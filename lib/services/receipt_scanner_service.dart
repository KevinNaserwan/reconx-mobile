import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_sync_service.dart';

class ReceiptScanResult {
  final String imagePath;
  String merchant;
  double amount;
  DateTime date;
  String paymentMethod;
  String category;
  List<String> detectedItems;
  double confidenceScore;
  String engine;

  ReceiptScanResult({
    required this.imagePath,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.category,
    required this.detectedItems,
    this.confidenceScore = 0.98,
    this.engine = 'PaddleOCR PP-OCRv4',
  });
}

class _AmountCandidate {
  final double amount;
  final int score;
  final String sourceLine;
  final String reason;

  _AmountCandidate({
    required this.amount,
    required this.score,
    required this.sourceLine,
    required this.reason,
  });
}

class ReceiptScannerService {
  static final ReceiptScannerService _instance = ReceiptScannerService._internal();
  factory ReceiptScannerService() => _instance;
  ReceiptScannerService._internal();

  final ImagePicker _picker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<XFile?> captureReceiptCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 1800,
      );
    } catch (e) {
      return null;
    }
  }

  Future<XFile?> pickReceiptGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1800,
      );
    } catch (e) {
      return null;
    }
  }

  /// High-Precision Indonesian Receipt & OCR Tuning Engine
  Future<ReceiptScanResult?> parseReceiptImage(String imagePath) async {
    // 1. Try PaddleOCR PP-OCRv4 Engine via Backend Microservice
    try {
      final backendUrl = ApiSyncService().backendUrl;
      final uri = Uri.parse('$backendUrl/ocr/scan-receipt');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      if (streamedResponse.statusCode == 200) {
        final respStr = await streamedResponse.stream.bytesToString();
        final Map<String, dynamic> data = jsonDecode(respStr);
        if (data['success'] == true && data['amount'] != null && (data['amount'] as num) > 0) {
          debugPrint('[OCR] PaddleOCR PP-OCRv4 Success: ${data["merchant"]} - Rp ${data["amount"]}');
          return ReceiptScanResult(
            imagePath: imagePath,
            merchant: data['merchant'] ?? 'Merchant Terdeteksi',
            amount: (data['amount'] as num).toDouble(),
            date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
            paymentMethod: data['paymentMethod'] ?? 'Transfer Bank',
            category: data['category'] ?? 'Konsumsi & Belanja',
            detectedItems: List<String>.from(data['detectedItems'] ?? [data['merchant'] ?? 'Transaksi']),
            confidenceScore: (data['confidenceScore'] as num?)?.toDouble() ?? 0.99,
            engine: 'PaddleOCR PP-OCRv4',
          );
        }
      }
    } catch (e) {
      debugPrint('[OCR] PaddleOCR service unreachable or timed out ($e). Falling back to on-device Google ML Kit.');
    }

    // 2. High-Precision On-Device Google ML Kit Fallback
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text.trim();

      if (rawText.isEmpty || rawText.length < 4) {
        debugPrint('[OCR] No legible text detected on image.');
        return null;
      }

      final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isEmpty) return null;

      final lowerAll = rawText.toLowerCase();

      // Extract amount with multi-strategy candidate scoring
      final detectedAmount = _extractBestAmount(recognizedText, lines);

      // Extract merchant name
      final merchant = _extractMerchant(lines, lowerAll);

      // Detect payment method
      final paymentMethod = _detectPaymentMethod(lowerAll);

      // Detect spending category
      final category = _detectCategory(merchant, lowerAll);

      // Collect item descriptions
      final items = _extractItems(lines, merchant);

      return ReceiptScanResult(
        imagePath: imagePath,
        merchant: merchant,
        amount: detectedAmount > 0 ? detectedAmount : 0.0,
        date: DateTime.now(),
        paymentMethod: paymentMethod,
        category: category,
        detectedItems: items.isNotEmpty ? items : [merchant],
        confidenceScore: detectedAmount > 0 ? 0.98 : 0.60,
        engine: 'Google ML Kit (Offline Fallback)',
      );
    } catch (e) {
      debugPrint('[OCR] Processing error: $e');
      return ReceiptScanResult(
        imagePath: imagePath,
        merchant: 'Toko / Merchant Fisik',
        amount: 0.0,
        date: DateTime.now(),
        paymentMethod: 'QRIS BCA',
        category: 'Konsumsi & F&B',
        detectedItems: ['Pengeluaran Fisik'],
        confidenceScore: 0.5,
        engine: 'Default Fallback',
      );
    }
  }

  /// Intelligently scores and picks the true transaction total across diverse Indonesian receipt formats
  double _extractBestAmount(RecognizedText recognizedText, List<String> lines) {
    final candidates = <_AmountCandidate>[];

    // Negative words: Lines that should NEVER be considered as the final amount
    final negativeKeywords = [
      'kembali ke beranda',
      'kembali ke menu',
      'kembali ke utama',
      'simpan sebagai favorit',
      'no. ref',
      'no ref',
      'ref blu',
      'referensi',
      'nomor referensi',
      'no. rekening',
      'nomor rekening',
      'rekening tujuan',
      'sumber dana',
      'antar blu',
      'bi-fast',
      'wib',
      'wita',
      'wit',
      'kembali',
      'kembalian',
      'change',
      'diskon',
      'discount',
      'potongan',
      'hemat',
      'voucher',
      'cashback',
      'kembalian tunai',
    ];

    // Strongest total, e-banking nominal & explicit cash price keywords (Priority 1)
    final p1Keywords = [
      'nominal',
      'nominal transfer',
      'jumlah transfer',
      'nilai transfer',
      'total transfer',
      'nominal transaksi',
      'total pembayaran',
      'harga tunai',
      'bayar tunai',
      'uang tunai',
      'pembayaran tunai',
      'total tunai',
      'total bayar',
      'total belanja',
      'grand total',
      'total tagihan',
      'total transaksi',
      'total akhir',
      'total net',
      'total netto',
      'total amount',
      'jumlah bayar',
      'total harga',
      'total rupiah',
      'jml rupiah',
      'total keseluruhan',
      'jumlah tagihan',
      'jumlah total',
      't0tal',
      'tota1',
      'to tal',
      'tot',
      'ttl',
    ];

    // Secondary domain total keywords (Priority 2: SPBU, Restoran, Parkir, Apotek)
    final p2Keywords = [
      'rupiah',
      'rup1ah',
      'rup!ah',
      'total (rp)',
      'tarif',
      'biaya parkir',
      'biaya tiket',
      'biaya masuk',
      'tarif tol',
      'total resep',
      'harga obat',
      'total',
      'subtotal',
      'sub total',
      'sub-total',
      'netto',
      'tagihan',
      'jml harga',
      'harga total',
      'harga jual',
      'total order',
    ];

    // Tertiary keywords
    final p3Keywords = [
      'jumlah',
      'tunai',
      'cash',
      'debit',
      'qris',
      'bayar',
      'harga',
      'biaya',
      'pembayaran',
    ];

    // Strategy 1: Scan line by line with contextual scoring
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Check if line contains negative words (change, discount, etc.)
      final hasNegative = negativeKeywords.any((nk) => lower.contains(nk));
      if (hasNegative) {
        continue; // Skip lines with change/discount
      }

      // 1.1 Check numbers directly on this line
      final amountsInLine = _extractNumbersFromText(line);
      for (final amt in amountsInLine) {
        if (!_isValidAmount(amt, line)) continue;

        int score = 25; // baseline

        if (p1Keywords.any((k) => lower.contains(k))) {
          score += lower.contains('nominal') ? 190 : 150;
        } else if (p2Keywords.any((k) => lower.contains(k))) {
          score += 105;
        } else if (p3Keywords.any((k) => lower.contains(k))) {
          score += 45;
        }

        if (lower.contains('rp') || lower.contains('idr')) {
          score += 35;
        }

        // Relative vertical position bonus (totals are in bottom 60% of physical receipt, but nominal can be anywhere)
        if (i >= lines.length * 0.35 || lower.contains('nominal')) {
          score += 25;
        }

        // Rupiah roundness bonus (common retail denomination)
        if (amt % 50 == 0) {
          score += 10;
        }

        candidates.add(_AmountCandidate(
          amount: amt,
          score: score,
          sourceLine: line,
          reason: 'Direct match on line $i',
        ));
      }

      // 1.2 Check split lines: Line i has keyword (e.g. "Nominal" or "Total") but no number, number is on line i+1
      final hasTotalKeyword = p1Keywords.any((k) => lower.contains(k)) ||
                              p2Keywords.any((k) => lower.contains(k));

      if (hasTotalKeyword && amountsInLine.isEmpty && i + 1 < lines.length) {
        final nextLine = lines[i + 1];
        final lowerNext = nextLine.toLowerCase();

        if (!negativeKeywords.any((nk) => lowerNext.contains(nk))) {
          final nextAmounts = _extractNumbersFromText(nextLine);
          for (final amt in nextAmounts) {
            if (!_isValidAmount(amt, nextLine)) continue;
            // E-Banking screenshot "Nominal" on line i followed by "Rp 38.490,00" gets top score 220!
            final score = lower.contains('nominal') ? 220 : 165;
            candidates.add(_AmountCandidate(
              amount: amt,
              score: score,
              sourceLine: '$line -> $nextLine',
              reason: 'Direct next line after $line',
            ));
          }
        }
      }
    }

    // Strategy 1.3: Intelligent Tunai - Kembali Net Reconciliation
    // Many warung/retail receipts don't have "TOTAL", only "TUNAI: 50.000" and "KEMBALI: 15.000"
    // Total Belanja = TUNAI - KEMBALI = 35.000!
    double? tenderAmount;
    String? tenderLine;
    double? changeAmount;
    String? changeLine;

    for (final line in lines) {
      final l = line.toLowerCase();
      // Exclude navigation buttons like "Kembali ke Beranda"
      final isNavButton = l.contains('beranda') || l.contains('menu') || l.contains('utama') || l.contains('halaman');
      if (!isNavButton && (l.contains('kembali') || l.contains('kembalian') || l.contains('change'))) {
        final nums = _extractNumbersFromText(line);
        if (nums.isNotEmpty) {
          changeAmount = nums.last;
          changeLine = line;
        }
      } else if (l.contains('tunai') || l.contains('cash') || l.contains('bayar tunai') || l.contains('uang tunai')) {
        if (!l.contains('kembali')) {
          final nums = _extractNumbersFromText(line);
          if (nums.isNotEmpty) {
            tenderAmount = nums.last;
            tenderLine = line;
          }
        }
      }
    }

    if (tenderAmount != null && tenderAmount > 0) {
      if (changeAmount != null && changeAmount > 0 && tenderAmount > changeAmount) {
        final netPurchase = tenderAmount - changeAmount;
        if (_isValidAmount(netPurchase, 'Net Calculation')) {
          candidates.add(_AmountCandidate(
            amount: netPurchase,
            score: 185, // Highest score! Mathematical truth of net purchase
            sourceLine: '$tenderLine minus $changeLine',
            reason: 'Tunai ($tenderAmount) - Kembali ($changeAmount)',
          ));
        }
      } else if (changeAmount == null || changeAmount == 0) {
        // Exact cash payment (no change) e.g. "TUNAI: 25.000"
        candidates.add(_AmountCandidate(
          amount: tenderAmount,
          score: 130,
          sourceLine: tenderLine ?? 'TUNAI',
          reason: 'Tunai tanpa kembalian (Exact Cash Payment)',
        ));
      }
    }

    // Strategy 2: Multi-block 2-column alignment (ML Kit Bounding Boxes)
    try {
      final allBlocks = recognizedText.blocks;
      for (final block in allBlocks) {
        for (final textLine in block.lines) {
          final lineLower = textLine.text.toLowerCase();
          final isP1 = p1Keywords.any((k) => lineLower.contains(k));
          final isP2 = p2Keywords.any((k) => lineLower.contains(k));

          if ((isP1 || isP2) && _extractNumbersFromText(textLine.text).isEmpty) {
            final yCenter = (textLine.boundingBox.top + textLine.boundingBox.bottom) / 2.0;

            // Search other blocks for a line at the same Y level (side-by-side)
            for (final otherBlock in allBlocks) {
              if (otherBlock == block) continue;
              for (final otherLine in otherBlock.lines) {
                final otherY = (otherLine.boundingBox.top + otherLine.boundingBox.bottom) / 2.0;
                if ((yCenter - otherY).abs() < 24) {
                  final amounts = _extractNumbersFromText(otherLine.text);
                  for (final amt in amounts) {
                    if (_isValidAmount(amt, otherLine.text)) {
                      candidates.add(_AmountCandidate(
                        amount: amt,
                        score: isP1 ? 165 : 135,
                        sourceLine: '${textLine.text} [parallel] ${otherLine.text}',
                        reason: 'Horizontal block alignment',
                      ));
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[OCR] Bounding box alignment analysis skipped: $e');
    }

    // Strategy 3: Multi-item line summation fallback (if receipt is torn or lacks total)
    if (candidates.where((c) => c.score >= 100).isEmpty) {
      double itemSum = 0;
      int itemCount = 0;
      for (final line in lines) {
        final l = line.toLowerCase();
        if (negativeKeywords.any((nk) => l.contains(nk))) continue;
        if (p1Keywords.any((k) => l.contains(k))) continue;
        if (p2Keywords.any((k) => l.contains(k))) continue;

        final nums = _extractNumbersFromText(line);
        if (nums.length == 1) {
          final amt = nums.first;
          if (amt >= 1000 && amt <= 1000000 && line.length >= 6) {
            itemSum += amt;
            itemCount++;
          }
        }
      }
      if (itemCount >= 2 && itemSum > 0 && itemSum <= 10000000) {
        candidates.add(_AmountCandidate(
          amount: itemSum,
          score: 95,
          sourceLine: 'Sum of $itemCount detected items',
          reason: 'Sum of item lines fallback',
        ));
      }
    }

    if (candidates.isEmpty) {
      debugPrint('[OCR] No high-confidence candidates found. Running fallback extraction.');
      // Fallback: Pick any valid number in the bottom half of the text
      for (int i = lines.length - 1; i >= 0; i--) {
        final line = lines[i];
        final lower = line.toLowerCase();
        if (negativeKeywords.any((nk) => lower.contains(nk))) continue;

        final nums = _extractNumbersFromText(line);
        for (final n in nums) {
          if (_isValidAmount(n, line)) {
            candidates.add(_AmountCandidate(
              amount: n,
              score: 35,
              sourceLine: line,
              reason: 'Bottom-up fallback',
            ));
          }
        }
      }
    }

    if (candidates.isEmpty) return 0.0;

    // Sort by highest score first; if equal, prefer larger amount
    candidates.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return b.amount.compareTo(a.amount);
    });

    final winner = candidates.first;
    debugPrint('[OCR] Winner Amount: Rp ${winner.amount} (Score: ${winner.score}, Reason: ${winner.reason}, Source: "${winner.sourceLine}")');
    return winner.amount;
  }

  /// Extracts numbers from text with Indonesian formatting and OCR character repair
  List<double> _extractNumbersFromText(String text) {
    final results = <double>[];

    // Pre-clean OCR noise in number context
    var cleaned = text;

    // Replace letter 'O' or 'o' between digits or dots with '0'
    cleaned = cleaned.replaceAllMapped(RegExp(r'(?<=\d|\.|\,)[oO](?=\d|\.|\,)'), (m) => '0');
    // Replace letter 'l' or 'I' with '1' if followed by .000 or digits
    cleaned = cleaned.replaceAllMapped(RegExp(r'(?<=\s|^)[lI|](?=\d)'), (m) => '1');

    // Pattern 1: Explicit Rp/IDR prefix (e.g., Rp 10.500, Rp. 10.500,00, IDR 25,000)
    final rpMatches = RegExp(
      r'(?:rp|idr)\s*[:.]?\s*([0-9]{1,3}(?:[.,\s][0-9]{3})*(?:[.,][0-9]{2})?|[0-9]{3,})',
      caseSensitive: false,
    ).allMatches(cleaned);

    for (final m in rpMatches) {
      final val = _cleanNumberString(m.group(1)!);
      if (val >= 500) results.add(val);
    }

    // Pattern 2: Standard Indonesian dot-separated thousands (e.g. 10.500, 1.250.000, 45,000)
    final dotMatches = RegExp(
      r'(?:^|[^\d])([0-9]{1,3}(?:[.,][0-9]{3})+(?:[.,][0-9]{2})?)(?:[^\d]|$)',
    ).allMatches(cleaned);

    for (final m in dotMatches) {
      final val = _cleanNumberString(m.group(1)!);
      if (val >= 500 && !results.contains(val)) results.add(val);
    }

    // Pattern 3: Space-separated thousands due to faded thermal printing (e.g. 10 500)
    final spaceMatches = RegExp(
      r'(?:^|[^\d])([0-9]{1,3}\s+[0-9]{3}(?:\s+[0-9]{3})*)(?:[^\d]|$)',
    ).allMatches(cleaned);

    for (final m in spaceMatches) {
      final val = _cleanNumberString(m.group(1)!);
      if (val >= 500 && !results.contains(val)) results.add(val);
    }

    // Pattern 4: Plain integer numbers >= 4 digits (e.g. 10500, 25000)
    final plainMatches = RegExp(
      r'(?:^|[^\d])([0-9]{4,8})(?:[^\d]|$)',
    ).allMatches(cleaned);

    for (final m in plainMatches) {
      final val = _cleanNumberString(m.group(1)!);
      if (val >= 500 && !results.contains(val)) results.add(val);
    }

    return results;
  }

  /// Parses and cleans raw string into double
  double _cleanNumberString(String raw) {
    var s = raw.trim();

    // Remove trailing cents/sen like ,00 or .00 or ,-
    if (s.endsWith(',00') || s.endsWith('.00')) {
      s = s.substring(0, s.length - 3);
    } else if (s.endsWith(',-')) {
      s = s.substring(0, s.length - 2);
    }

    // Strip non-digits
    s = s.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(s) ?? 0.0;
  }

  /// Rejects barcodes, phone numbers, invoice IDs, and dates
  bool _isValidAmount(double amt, String line) {
    // Basic bounds: Rp 500 up to Rp 100.000.000 (typical retail receipts & transfers)
    if (amt < 500 || amt > 100000000) return false;

    final lower = line.toLowerCase();
    // Rejects lines containing reference numbers, account numbers, or timestamps
    if (lower.contains('no. ref') ||
        lower.contains('no ref') ||
        lower.contains('ref blu') ||
        lower.contains('referensi') ||
        lower.contains('rekening') ||
        lower.contains('norek') ||
        lower.contains('wib') ||
        lower.contains('wita') ||
        lower.contains('wit') ||
        lower.contains('sumber dana') ||
        lower.contains('antar blu') ||
        lower.contains('bi-fast')) {
      return false;
    }

    final str = amt.toInt().toString();

    // Pure 10-16 digit numbers are barcodes, card numbers, or tax IDs
    if (str.length >= 10) return false;

    // Indonesian mobile phone number detection (08...)
    if (str.startsWith('8') && str.length >= 9) return false;

    // Date or year detection (e.g. 2024, 2025, 2026)
    if ((amt >= 2020 && amt <= 2030) && (line.contains('/') || line.contains('-') || line.contains(':') || line.contains('|'))) {
      return false;
    }

    return true;
  }

  String _extractMerchant(List<String> lines, String lowerAll) {
    // 0. E-Banking Transfer Screenshot Detection (blu BCA, BCA Mobile, Livin, BRImo, etc.)
    final isBanking = lowerAll.contains('transaksi berhasil') ||
        lowerAll.contains('transfer berhasil') ||
        lowerAll.contains('bukti transfer') ||
        lowerAll.contains('ref blu') ||
        lowerAll.contains('bi-fast') ||
        lowerAll.contains('antar blu');

    if (isBanking) {
      // Find the recipient name line
      for (int i = 0; i < lines.length; i++) {
        final l = lines[i].toLowerCase();
        if (l.contains('digital -') ||
            l.contains('bca -') ||
            l.contains('mandiri -') ||
            l.contains('bri -') ||
            l.contains('bni -') ||
            l.contains('tipe transaksi')) {
          if (i > 0) {
            final prev = lines[i - 1].trim();
            final prevL = prev.toLowerCase();
            if (!prevL.contains('nominal') &&
                !prevL.contains('rp') &&
                !prevL.contains('transaksi') &&
                !prevL.contains('wib') &&
                !prevL.contains('berhasil') &&
                prev.length >= 3) {
              return prev;
            }
          }
        }
      }

      // Check for known digital service providers or merchants in banking transfer
      for (final line in lines) {
        final l = line.toLowerCase();
        if (l.contains('caturnusa')) return 'CATURNUSA SEJAHTERA FINA';
        if (l.contains('traveloka')) return 'Traveloka PayLater';
        if (l.contains('tokopedia')) return 'Tokopedia';
        if (l.contains('shopee')) return 'Shopee';
        if (l.contains('pln')) return 'PLN Pascabayar/Token';
      }
    }

    // 1. Check known brands in full text
    if (lowerAll.contains('indomaret')) return 'Indomaret';
    if (lowerAll.contains('alfamidi')) return 'Alfamidi';
    if (lowerAll.contains('alfamart')) return 'Alfamart';
    if (lowerAll.contains('superindo') || lowerAll.contains('super indo')) return 'Super Indo';
    if (lowerAll.contains('hypermart')) return 'Hypermart';
    if (lowerAll.contains('transmart')) return 'Transmart';
    if (lowerAll.contains('lawson')) return 'Lawson';
    if (lowerAll.contains('circle k')) return 'Circle K';
    if (lowerAll.contains('dan+dan') || lowerAll.contains('dandan')) return 'Dan+Dan';
    if (lowerAll.contains('starbucks')) return 'Starbucks Coffee';
    if (lowerAll.contains('kfc') || lowerAll.contains('kentucky fried')) return 'KFC Indonesia';
    if (lowerAll.contains('mcdonald') || lowerAll.contains('mcd')) return "McDonald's";
    if (lowerAll.contains('spbu') || lowerAll.contains('pertamina')) return 'SPBU Pertamina';
    if (lowerAll.contains('shell')) return 'Shell SPBU';
    if (lowerAll.contains('kopi kenangan')) return 'Kopi Kenangan';
    if (lowerAll.contains('janji jiwa')) return 'Janji Jiwa';
    if (lowerAll.contains('mixue')) return 'Mixue';
    if (lowerAll.contains('fore coffee')) return 'Fore Coffee';
    if (lowerAll.contains('mie gacoan') || lowerAll.contains('gacoan')) return 'Mie Gacoan';
    if (lowerAll.contains('hokben')) return 'HokBen';
    if (lowerAll.contains('solaria')) return 'Solaria';
    if (lowerAll.contains('pizza hut')) return 'Pizza Hut';
    if (lowerAll.contains('burger king')) return 'Burger King';
    if (lowerAll.contains('guardian')) return 'Guardian';
    if (lowerAll.contains('watsons')) return 'Watsons';
    if (lowerAll.contains('kimia farma')) return 'Kimia Farma';
    if (lowerAll.contains('k-24') || lowerAll.contains('k24')) return 'Apotek K-24';

    // 2. Fallback to top non-address lines of the receipt
    for (int i = 0; i < lines.length && i < 5; i++) {
      final cand = lines[i];
      final l = cand.toLowerCase();
      if (cand.length >= 3 &&
          !RegExp(r'^[0-9\s/:\-]+$').hasMatch(cand) &&
          !l.contains('selamat') &&
          !l.contains('terima kasih') &&
          !l.contains('transaksi') &&
          !l.contains('berhasil') &&
          !l.contains('transfer') &&
          !l.contains('nominal') &&
          !l.contains('favorit') &&
          !l.contains('beranda') &&
          !l.contains('detail') &&
          !l.contains('menu') &&
          !l.contains('wib') &&
          !l.contains('wita') &&
          !l.contains('wit') &&
          !l.contains('jl.') &&
          !l.contains('jalan') &&
          !l.contains('telp') &&
          !l.contains('npwp') &&
          !l.contains('cabang') &&
          !l.contains('pos') &&
          !l.contains('kasir')) {
        return cand;
      }
    }

    return isBanking ? 'Penerima Transfer' : 'Merchant / Toko';
  }

  String _detectPaymentMethod(String lowerAll) {
    final isBanking = lowerAll.contains('transaksi berhasil') ||
        lowerAll.contains('transfer berhasil') ||
        lowerAll.contains('bukti transfer') ||
        lowerAll.contains('antar blu') ||
        lowerAll.contains('bi-fast') ||
        lowerAll.contains('ref blu');

    if (lowerAll.contains('blu') || lowerAll.contains('antar blu')) {
      if (lowerAll.contains('bi-fast')) return 'BI-FAST (blu BCA)';
      return 'blu by BCA Digital';
    }

    if (lowerAll.contains('bi-fast')) return 'BI-FAST Transfer';
    if (lowerAll.contains('bca')) return 'BCA Mobile';
    if (lowerAll.contains('mandiri') || lowerAll.contains('livin')) return "Livin' by Mandiri";
    if (lowerAll.contains('bri') || lowerAll.contains('brimo')) return 'BRImo (BRI)';
    if (lowerAll.contains('bni')) return 'BNI Mobile';
    if (lowerAll.contains('seabank')) return 'SeaBank Transfer';

    if (lowerAll.contains('qris')) {
      if (lowerAll.contains('seabank')) return 'QRIS SeaBank';
      if (lowerAll.contains('blu')) return 'QRIS blu BCA';
      if (lowerAll.contains('gopay') || lowerAll.contains('gojek')) return 'GoPay QRIS';
      if (lowerAll.contains('shopeepay') || lowerAll.contains('spay')) return 'ShopeePay QRIS';
      return 'QRIS BCA';
    }

    if (lowerAll.contains('gopay') || lowerAll.contains('gojek')) return 'GoPay';
    if (lowerAll.contains('shopeepay') || lowerAll.contains('shopee')) return 'ShopeePay';
    if (lowerAll.contains('ovo')) return 'OVO';
    if (lowerAll.contains('dana')) return 'DANA';
    if (lowerAll.contains('debit') || lowerAll.contains('edc')) return 'Debit BCA';

    if (!isBanking) {
      if (lowerAll.contains('uang tunai') ||
          lowerAll.contains('harga tunai') ||
          lowerAll.contains('bayar tunai') ||
          lowerAll.contains('kembalian') ||
          RegExp(r'\bkembali\s*:\s*[0-9]').hasMatch(lowerAll) ||
          (lowerAll.contains('tunai') && !lowerAll.contains('beranda'))) {
        return 'Tunai (Cash)';
      }
    }

    return isBanking ? 'Transfer Bank' : 'Tunai (Cash)';
  }

  String _detectCategory(String merchant, String lowerAll) {
    final m = merchant.toLowerCase();
    if (m.contains('caturnusa') || lowerAll.contains('caturnusa')) {
      return 'Tagihan & PayLater (Caturnusa)';
    }
    if (lowerAll.contains('uang keluar')) {
      return 'Transfer Uang Keluar';
    }
    if (lowerAll.contains('uang masuk')) {
      return 'Penerimaan Dana';
    }
    if (m.contains('indomaret') ||
        m.contains('alfamart') ||
        m.contains('alfamidi') ||
        m.contains('superindo') ||
        m.contains('hypermart') ||
        m.contains('transmart') ||
        m.contains('circle k') ||
        m.contains('lawson') ||
        lowerAll.contains('minimarket') ||
        lowerAll.contains('supermarket')) {
      return 'Belanja Harian & Minimarket';
    }
    if (m.contains('spbu') ||
        m.contains('pertamina') ||
        m.contains('shell') ||
        lowerAll.contains('bensin') ||
        lowerAll.contains('pertamax') ||
        lowerAll.contains('pertalite') ||
        lowerAll.contains('solar') ||
        lowerAll.contains('parkir') ||
        lowerAll.contains('tol') ||
        lowerAll.contains('tarif parkir')) {
      return 'Transportasi & Bahan Bakar';
    }
    if (m.contains('kfc') ||
        m.contains('mcdonald') ||
        m.contains('starbucks') ||
        m.contains('kopi') ||
        m.contains('cafe') ||
        m.contains('mie gacoan') ||
        m.contains('hokben') ||
        m.contains('solaria') ||
        m.contains('warung') ||
        m.contains('resto') ||
        m.contains('rumah makan') ||
        lowerAll.contains('makanan') ||
        lowerAll.contains('minuman')) {
      return 'Restoran & Kuliner';
    }
    if (m.contains('apotek') ||
        m.contains('kimia farma') ||
        m.contains('k-24') ||
        m.contains('guardian') ||
        m.contains('watsons') ||
        m.contains('century') ||
        lowerAll.contains('obat') ||
        lowerAll.contains('resep')) {
      return 'Kesehatan & Farmasi';
    }
    return 'Konsumsi & F&B';
  }

  List<String> _extractItems(List<String> lines, String merchant) {
    final items = <String>[];
    for (final line in lines) {
      final l = line.toLowerCase();
      if (line.length >= 3 &&
          !l.contains('total') &&
          !l.contains('bayar') &&
          !l.contains('kembali') &&
          !l.contains('tunai') &&
          !l.contains('terima kasih') &&
          !l.contains('selamat datang') &&
          !l.contains('kasir') &&
          !l.contains('npwp') &&
          !l.contains(merchant.toLowerCase())) {
        if (items.length < 5) {
          items.add(line);
        }
      }
    }
    return items;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
