import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_sync_service.dart';
import '../services/receipt_scanner_service.dart';
import '../theme/app_theme.dart';

class ReceiptScannerScreen extends StatefulWidget {
  final VoidCallback? onScanComplete;

  const ReceiptScannerScreen({super.key, this.onScanComplete});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isProcessing = false;
  ReceiptScanResult? _scanResult;

  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedMethod = 'QRIS BCA';
  String _selectedCategory = 'Konsumsi & F&B';

  final List<String> _paymentMethods = [
    'QRIS BCA',
    'QRIS SeaBank',
    'QRIS blu BCA',
    'GoPay QRIS',
    'ShopeePay QRIS',
    'Debit Mandiri',
    'Debit BRI',
    'Tunai (Cash)',
  ];

  final List<String> _categories = [
    'Konsumsi & F&B',
    'Belanja Harian & Minimarket',
    'Belanja Kebutuhan Rumah',
    'Transportasi & Bahan Bakar',
    'Restoran & Kuliner',
    'Kesehatan & Farmasi',
    'Tagihan & Utilitas',
    'Lainnya',
  ];

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(bool fromCamera) async {
    setState(() => _isProcessing = true);

    final xFile = fromCamera
        ? await ReceiptScannerService().captureReceiptCamera()
        : await ReceiptScannerService().pickReceiptGallery();

    if (xFile == null) {
      setState(() => _isProcessing = false);
      return;
    }

    // Run intelligent parser
    final result = ReceiptScannerService().parseReceiptImage(xFile.path);

    _merchantController.text = result.merchant;
    _amountController.text = result.amount.toInt().toString();
    _selectedMethod = result.paymentMethod;
    if (!_paymentMethods.contains(_selectedMethod)) {
      _paymentMethods.insert(0, _selectedMethod);
    }
    _selectedCategory = result.category;
    if (!_categories.contains(_selectedCategory)) {
      _categories.insert(0, _selectedCategory);
    }

    setState(() {
      _scanResult = result;
      _isProcessing = false;
    });
  }

  Future<void> _handleConfirmSync() async {
    if (_scanResult == null) return;

    final merchant = _merchantController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? _scanResult!.amount;

    if (merchant.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pastikan nama toko dan total nominal valid.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    await ApiSyncService().syncReceiptTransaction(
      merchant: merchant,
      amount: amount,
      category: _selectedCategory,
      paymentMethod: _selectedMethod,
      detectedItems: _scanResult!.detectedItems,
      imagePath: _scanResult!.imagePath,
    );

    setState(() {
      _isProcessing = false;
      _scanResult = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryEmerald,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nota $merchant berhasil masuk ke mutasi rekonsiliasi!',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );

      widget.onScanComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCard,
        elevation: 0,
        title: Text(
          'Scan Nota & Pembayaran Fisik',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_scanResult != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              tooltip: 'Scan Ulang',
              onPressed: () => setState(() => _scanResult = null),
            ),
        ],
      ),
      body: SafeArea(
        child: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryEmerald),
                    SizedBox(height: 16),
                    Text(
                      'Menganalisis Struk & Mengekstrak Data...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: _scanResult == null ? _buildEmptyPicker() : _buildScanResultForm(),
              ),
      ),
    );
  }

  Widget _buildEmptyPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.darkBorder),
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryEmerald.withOpacity(0.08),
                AppTheme.primaryCyan.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 38,
                  color: AppTheme.primaryEmerald,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Auto-Ingest Struk Belanja & Pembayaran',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Foto struk fisik dari kasir minimarket, SPBU, restoran, atau cafe. Sistem otomatis mengekstrak merchant, total belanja, dan menyinkronkannya ke ledger keluarga.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Action Buttons: Camera vs Gallery
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _handleCapture(true),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 28, color: AppTheme.primaryEmerald),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Foto Kamera',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: () => _handleCapture(false),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_library_rounded, size: 28, color: AppTheme.primaryCyan),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pilih Galeri',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Tips Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 8),
                  Text(
                    'Tips Pengambilan Foto Struk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTipRow('Pastikan pencahayaan cukup dan struk tidak terlipat.'),
              _buildTipRow('Nama toko dan total akhir (Rp) berada di dalam frame.'),
              _buildTipRow('Struk QRIS dan EDC bank terbaca lebih cepat dan akurat.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResultForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Preview Header with Confidence Badge
        Stack(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.4)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: File(_scanResult!.imagePath).existsSync()
                    ? Image.file(
                        File(_scanResult!.imagePath),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppTheme.darkCard,
                        child: const Icon(Icons.receipt_rounded, size: 48, color: Colors.white30),
                      ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'AI OCR Extracted (${(_scanResult!.confidenceScore * 100).toInt()}%)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Form Fields for Extracted Data
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Hasil Ekstraksi Struk',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Merchant Field
              Text('Nama Toko / Merchant', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 6),
              TextField(
                controller: _merchantController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.darkBg,
                  prefixIcon: const Icon(Icons.storefront_rounded, color: AppTheme.primaryEmerald),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 14),

              // Amount Field
              Text('Total Pembayaran (Rp)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.darkBg,
                  prefixIcon: const Icon(Icons.payments_rounded, color: AppTheme.primaryEmerald),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 14),

              // Payment Method Dropdown
              Text('Metode Pembayaran', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMethod,
                    dropdownColor: AppTheme.darkCard,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: _paymentMethods.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMethod = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Category Dropdown
              Text('Kategori Pengeluaran', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    dropdownColor: AppTheme.darkCard,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: _categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),

              if (_scanResult!.detectedItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Rincian Item Terdeteksi:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _scanResult!.detectedItems.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Text(
                        item,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Confirm Button
        ElevatedButton(
          onPressed: _handleConfirmSync,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryEmerald,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            'Verifikasi & Masukkan ke Mutasi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _scanResult = null),
          child: Text(
            'Batal & Ambil Foto Lain',
            style: GoogleFonts.plusJakartaSans(color: Colors.white60),
          ),
        ),
      ],
    );
  }
}
