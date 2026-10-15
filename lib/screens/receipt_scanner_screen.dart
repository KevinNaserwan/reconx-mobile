import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_sync_service.dart';
import '../services/language_service.dart';
import '../services/permission_service.dart';
import '../services/receipt_scanner_service.dart';
import '../theme/app_theme.dart';

class ReceiptScannerScreen extends StatefulWidget {
  final VoidCallback? onScanComplete;

  const ReceiptScannerScreen({super.key, this.onScanComplete});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  NumberFormat get currencyFormat {
    try {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    } catch (_) {
      return NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
    }
  }

  bool _isProcessing = false;
  bool _isTorchOn = false;
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
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(bool fromCamera) async {
    if (fromCamera) {
      final hasPerm = await PermissionService().requestCameraPermission(context);
      if (!hasPerm) return;
    }

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
    if (_scanResult != null) {
      return _buildResultScaffold();
    }

    return _buildGoPayStyleScannerView();
  }

  /// GoPay / DANA styled Camera Viewfinder UI
  Widget _buildGoPayStyleScannerView() {
    final size = MediaQuery.of(context).size;
    final boxSize = size.width * 0.76;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Camera Preview Mesh Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF020617),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Central Viewfinder Cutout Mask
          Center(
            child: SizedBox(
              width: boxSize,
              height: boxSize * 1.15,
              child: Stack(
                children: [
                  // Viewfinder Border with Corner Accents
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryEmerald.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // 4 Corner Brackets (GoPay Style)
                  _buildCornerReticle(Alignment.topLeft),
                  _buildCornerReticle(Alignment.topRight),
                  _buildCornerReticle(Alignment.bottomLeft),
                  _buildCornerReticle(Alignment.bottomRight),

                  // Animated Sweeping Laser Scanner Line
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, _) {
                      return Positioned(
                        top: _laserAnimation.value * (boxSize * 1.15 - 8),
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.primaryEmerald,
                                AppTheme.primaryCyan,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryEmerald.withOpacity(0.7),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Top Header Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () {
                        if (widget.onScanComplete != null) {
                          widget.onScanComplete!();
                        }
                      },
                    ),
                  ),
                  Text(
                    LanguageService().tr('scan_title'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _isTorchOn
                          ? AppTheme.primaryEmerald.withOpacity(0.2)
                          : Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isTorchOn ? AppTheme.primaryEmerald : Colors.white,
                      ),
                      onPressed: () {
                        setState(() => _isTorchOn = !_isTorchOn);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Helper Subtitle Under Viewfinder
          Positioned(
            top: (size.height / 2) + (boxSize * 0.58) + 16,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    LanguageService().tr('scan_hint'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls (GoPay Camera & Gallery Bar)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Upload Gallery Button
                    GestureDetector(
                      onTap: _isProcessing ? null : () => _handleCapture(false),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            LanguageService().tr('gallery'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    // Big Circular Shutter Button
                    GestureDetector(
                      onTap: _isProcessing ? null : () => _handleCapture(true),
                      child: Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryEmerald, width: 3),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: AppTheme.primaryEmerald,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.black,
                                    size: 32,
                                  ),
                          ),
                        ),
                      ),
                    ),

                    // Quick Mode Indicator
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryEmerald.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryEmerald, size: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Auto OCR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.primaryEmerald,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerReticle(Alignment alignment) {
    const double length = 24.0;
    const double thickness = 3.5;
    const color = AppTheme.primaryEmerald;

    Border border;
    if (alignment == Alignment.topLeft) {
      border = const Border(
        top: BorderSide(color: color, width: thickness),
        left: BorderSide(color: color, width: thickness),
      );
    } else if (alignment == Alignment.topRight) {
      border = const Border(
        top: BorderSide(color: color, width: thickness),
        right: BorderSide(color: color, width: thickness),
      );
    } else if (alignment == Alignment.bottomLeft) {
      border = const Border(
        bottom: BorderSide(color: color, width: thickness),
        left: BorderSide(color: color, width: thickness),
      );
    } else {
      border = const Border(
        bottom: BorderSide(color: color, width: thickness),
        right: BorderSide(color: color, width: thickness),
      );
    }

    return Align(
      alignment: alignment,
      child: Container(
        width: length,
        height: length,
        decoration: BoxDecoration(
          border: border,
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft ? const Radius.circular(8) : Radius.zero,
            topRight: alignment == Alignment.topRight ? const Radius.circular(8) : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft ? const Radius.circular(8) : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight ? const Radius.circular(8) : Radius.zero,
          ),
        ),
      ),
    );
  }

  /// Extracted Data Review & Sync Scaffold
  Widget _buildResultScaffold() {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getCard(context),
        elevation: 0,
        title: Text(
          'Hasil Ekstraksi Nota & QRIS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppTheme.getTextSecondary(context)),
            tooltip: 'Pindai Ulang',
            onPressed: () => setState(() => _scanResult = null),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Image Thumbnail
            if (_scanResult!.imagePath != null && File(_scanResult!.imagePath!).existsSync())
              Container(
                height: 180,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.getBorder(context)),
                  image: DecorationImage(
                    image: FileImage(File(_scanResult!.imagePath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Extracted Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.getCard(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.primaryEmerald, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Data Berhasil Terdeteksi',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Merchant Name
                  Text(
                    'Nama Toko / Merchant',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _merchantController,
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    decoration: _inputDecoration(context),
                  ),
                  const SizedBox(height: 16),

                  // Total Amount
                  Text(
                    'Total Pembayaran (Rp)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: AppTheme.primaryEmerald,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: _inputDecoration(context),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Text(
                    'Kategori Pengeluaran',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    decoration: _inputDecoration(context),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  Text(
                    'Metode Pembayaran',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedMethod,
                    dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                    style: TextStyle(color: AppTheme.getTextPrimary(context)),
                    decoration: _inputDecoration(context),
                    items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMethod = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Confirm Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _handleConfirmSync,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Simpan ke Ledger Rekonsiliasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return InputDecoration(
      filled: true,
      fillColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.getBorder(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.getBorder(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryEmerald, width: 1.5),
      ),
    );
  }
}
