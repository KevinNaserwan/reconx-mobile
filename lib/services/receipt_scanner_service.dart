import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptScanResult {
  final String imagePath;
  String merchant;
  double amount;
  DateTime date;
  String paymentMethod;
  String category;
  List<String> detectedItems;
  double confidenceScore;

  ReceiptScanResult({
    required this.imagePath,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.category,
    required this.detectedItems,
    this.confidenceScore = 0.98,
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
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (e) {
      return null;
    }
  }

  Future<XFile?> pickReceiptGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (e) {
      return null;
    }
  }

  /// Real Google ML Kit OCR Engine with strict non-receipt rejection
  Future<ReceiptScanResult?> parseReceiptImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text.trim();

      // STRICT VALIDATION 1: Empty or negligible text
      if (rawText.isEmpty || rawText.length < 5) {
        debugPrint('[OCR] No legible text detected on image.');
        return null;
      }

      final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isEmpty) return null;

      // STRICT VALIDATION 2: Receipt/Financial context checks
      final lowerAll = rawText.toLowerCase();
      final hasReceiptKeywords = RegExp(
        r'(?i)(total|subtotal|jumlah|harga|rp|idr|tunai|cash|kembali|struk|nota|kasir|pembayaran|qris|bca|mandiri|bri|bni|seabank|ovo|gopay|dana|shopee|toko|mart|cafe|resto|kopi|transaksi|rekening)'
      ).hasMatch(lowerAll);

      // Search for price/nominal in lines
      double detectedAmount = 0.0;
      for (final line in lines.reversed) {
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('total') || lowerLine.contains('jumlah') || lowerLine.contains('bayar') || lowerLine.contains('rp') || lowerLine.contains('tagihan')) {
          final matches = RegExp(r'([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]{4,})').allMatches(line);
          for (final m in matches) {
            final cleaned = m.group(1)!.replaceAll(RegExp(r'[^0-9]'), '');
            final val = double.tryParse(cleaned);
            if (val != null && val >= 500 && val > detectedAmount) {
              detectedAmount = val;
            }
          }
          if (detectedAmount > 0) break;
        }
      }

      // Fallback search across all lines for currency amounts if no keyword was explicit
      if (detectedAmount <= 0) {
        for (final line in lines) {
          final matches = RegExp(r'([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]{4,})').allMatches(line);
          for (final m in matches) {
            final cleaned = m.group(1)!.replaceAll(RegExp(r'[^0-9]'), '');
            final val = double.tryParse(cleaned);
            if (val != null && val >= 1000 && val > detectedAmount) {
              detectedAmount = val;
            }
          }
        }
      }

      // STRICT VALIDATION 3: If no valid amount and no financial keywords, this is NOT a receipt!
      if (detectedAmount <= 0 && !hasReceiptKeywords) {
        debugPrint('[OCR] Image is not a receipt or bill (no amount or keywords).');
        return null;
      }

      // Extract store / merchant name from the topmost lines
      String merchant = 'Merchant / Toko';
      for (int i = 0; i < lines.length && i < 4; i++) {
        final candidate = lines[i];
        if (candidate.length >= 3 &&
            !RegExp(r'^[0-9\s/:\-]+$').hasMatch(candidate) &&
            !candidate.toLowerCase().contains('selamat') &&
            !candidate.toLowerCase().contains('terima kasih')) {
          merchant = candidate;
          break;
        }
      }

      // Detect payment method
      String paymentMethod = 'QRIS BCA';
      if (lowerAll.contains('qris')) {
        paymentMethod = 'QRIS BCA';
      } else if (lowerAll.contains('gopay') || lowerAll.contains('gojek')) {
        paymentMethod = 'GoPay QRIS';
      } else if (lowerAll.contains('shopeepay') || lowerAll.contains('shopee')) {
        paymentMethod = 'ShopeePay QRIS';
      } else if (lowerAll.contains('ovo')) {
        paymentMethod = 'OVO';
      } else if (lowerAll.contains('dana')) {
        paymentMethod = 'DANA';
      } else if (lowerAll.contains('mandiri')) {
        paymentMethod = 'Debit Mandiri';
      } else if (lowerAll.contains('bri')) {
        paymentMethod = 'Debit BRI';
      } else if (lowerAll.contains('seabank')) {
        paymentMethod = 'QRIS SeaBank';
      } else if (lowerAll.contains('tunai') || lowerAll.contains('cash')) {
        paymentMethod = 'Tunai (Cash)';
      }

      // Detect category
      String category = 'Konsumsi & F&B';
      if (lowerAll.contains('indomaret') || lowerAll.contains('alfamart') || lowerAll.contains('superindo') || lowerAll.contains('minimarket')) {
        category = 'Belanja Harian & Minimarket';
      } else if (lowerAll.contains('spbu') || lowerAll.contains('pertamina') || lowerAll.contains('shell')) {
        category = 'Transportasi & Bahan Bakar';
      } else if (lowerAll.contains('resto') || lowerAll.contains('cafe') || lowerAll.contains('kopi') || lowerAll.contains('makan')) {
        category = 'Restoran & Kuliner';
      } else if (lowerAll.contains('apotek') || lowerAll.contains('farmasi') || lowerAll.contains('kimia') || lowerAll.contains('obat')) {
        category = 'Kesehatan & Farmasi';
      }

      // Collect items
      final items = <String>[];
      for (final line in lines) {
        if (line.length >= 3 &&
            !line.toLowerCase().contains('total') &&
            !line.toLowerCase().contains('bayar') &&
            !line.toLowerCase().contains('kembali') &&
            !line.toLowerCase().contains('terima kasih')) {
          if (items.length < 5) {
            items.add(line);
          }
        }
      }

      return ReceiptScanResult(
        imagePath: imagePath,
        merchant: merchant,
        amount: detectedAmount > 0 ? detectedAmount : 0.0,
        date: DateTime.now(),
        paymentMethod: paymentMethod,
        category: category,
        detectedItems: items.isNotEmpty ? items : [merchant],
        confidenceScore: 0.95,
      );
    } catch (e) {
      debugPrint('[OCR] Processing error: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
