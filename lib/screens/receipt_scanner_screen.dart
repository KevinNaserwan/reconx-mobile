import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_sync_service.dart';
import '../services/language_service.dart';
import '../services/permission_service.dart';
import '../services/receipt_scanner_service.dart';
import '../theme/app_theme.dart';
import '../widgets/slide_to_confirm.dart';
import '../widgets/success_celebration_dialog.dart';

class ReceiptScannerScreen extends StatefulWidget {
  final VoidCallback? onScanComplete;

  const ReceiptScannerScreen({super.key, this.onScanComplete});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isInitializingCamera = false;
  String? _cameraErrorMessage;

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
    'Tunai (Cash)',
    'QRIS BCA',
    'QRIS SeaBank',
    'QRIS blu BCA',
    'GoPay QRIS',
    'ShopeePay QRIS',
    'Debit BCA',
    'Debit Mandiri',
    'Debit BRI',
    'Transfer Bank',
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
    WidgetsBinding.instance.addObserver(this);
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initCamera();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializingCamera) return;
    setState(() {
      _isInitializingCamera = true;
      _cameraErrorMessage = null;
    });

    try {
      final hasPerm = await PermissionService().requestCameraPermission(context);
      if (!hasPerm) {
        if (mounted) {
          setState(() {
            _isInitializingCamera = false;
            _cameraErrorMessage = 'Izin kamera diperlukan untuk live viewfinder.';
          });
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializingCamera = false;
            _cameraErrorMessage = 'Kamera tidak terdeteksi pada perangkat ini.';
          });
        }
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      CameraController controller;
      try {
        controller = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await controller.initialize();
      } catch (presetError) {
        debugPrint('[Camera] High resolution preset failed, falling back to medium: $presetError');
        controller = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await controller.initialize();
      }

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraReady = true;
          _isInitializingCamera = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
          _cameraErrorMessage = 'Gagal memuat viewfinder kamera: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _laserController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(bool fromCamera) async {
    setState(() => _isProcessing = true);

    String? photoPath;

    if (fromCamera) {
      // In-app direct capture if camera controller is active
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        try {
          final xFile = await _cameraController!.takePicture();
          photoPath = xFile.path;
        } catch (e) {
          debugPrint('Error taking picture in-app: $e');
        }
      }

      // Fallback if in-app camera wasn't ready
      if (photoPath == null) {
        final xFile = await ReceiptScannerService().captureReceiptCamera();
        photoPath = xFile?.path;
      }
    } else {
      // Pick from gallery
      final xFile = await ReceiptScannerService().pickReceiptGallery();
      photoPath = xFile?.path;
    }

    if (photoPath == null) {
      setState(() => _isProcessing = false);
      return;
    }

    // Run intelligent Indonesian MLKit OCR parser
    final result = await ReceiptScannerService().parseReceiptImage(photoPath) ??
        ReceiptScanResult(
          imagePath: photoPath,
          merchant: 'Merchant / Toko',
          amount: 0.0,
          date: DateTime.now(),
          paymentMethod: 'QRIS BCA',
          category: 'Konsumsi & F&B',
          detectedItems: ['Pengeluaran Fisik'],
          confidenceScore: 0.5,
          engine: 'Default Fallback',
        );

    _merchantController.text = result.merchant;
    _amountController.text = result.amount > 0 ? result.amount.toInt().toString() : '';
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
    });

    if (mounted) {
      SuccessCelebrationDialog.show(
        context: context,
        amount: amount,
        merchant: merchant,
        category: _selectedCategory,
        paymentMethod: _selectedMethod,
        onViewTransactions: () {
          setState(() => _scanResult = null);
          widget.onScanComplete?.call();
        },
        onScanAgain: () {
          setState(() => _scanResult = null);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, _) {
        if (_scanResult != null) {
          return _buildResultScaffold();
        }
        return _buildGoPayStyleScannerView();
      },
    );
  }

  /// GoPay / DANA styled Camera Viewfinder UI
  Widget _buildGoPayStyleScannerView() {
    final size = MediaQuery.of(context).size;
    final boxSize = size.width * 0.76;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live In-App Camera Viewfinder or smart loading/fallback
          if (_isCameraReady && _cameraController != null && _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? size.width,
                  height: _cameraController!.value.previewSize?.width ?? size.height,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
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
              child: Center(
                child: _isInitializingCamera
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppTheme.primaryEmerald),
                          const SizedBox(height: 16),
                          Text(
                            'Menyiapkan Kamera In-App...',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : (_cameraErrorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.videocam_off_rounded, color: Colors.amber, size: 44),
                                const SizedBox(height: 12),
                                Text(
                                  _cameraErrorMessage!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _initCamera,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Coba Lagi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryEmerald,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null),
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
                      color: Colors.black.withOpacity(0.15),
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
                      onPressed: () async {
                        if (_cameraController != null && _cameraController!.value.isInitialized) {
                          try {
                            final newTorch = !_isTorchOn;
                            await _cameraController!.setFlashMode(newTorch ? FlashMode.torch : FlashMode.off);
                            setState(() => _isTorchOn = newTorch);
                          } catch (e) {
                            debugPrint('Torch error: $e');
                          }
                        } else {
                          setState(() => _isTorchOn = !_isTorchOn);
                        }
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

                  // Total Amount with Confidence Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pembayaran (Rp)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: _scanResult!.amount > 0
                              ? AppTheme.primaryEmerald.withOpacity(0.12)
                              : Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _scanResult!.amount > 0
                              ? '✓ ${_scanResult!.engine} (${(_scanResult!.confidenceScore * 100).toInt()}%)'
                              : 'Isi Manual',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _scanResult!.amount > 0 ? AppTheme.primaryEmerald : Colors.amber,
                          ),
                        ),
                      ),
                    ],
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
                  const SizedBox(height: 8),
                  // Quick adjustment chips for torn or imprecise receipts
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [1000, 5000, 10000, 50000].map((inc) {
                      return InkWell(
                        onTap: () {
                          final current = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                          final next = current + inc;
                          _amountController.text = next.toInt().toString();
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkBg : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.getBorder(context)),
                          ),
                          child: Text(
                            '+Rp ${(inc >= 1000 ? "${inc ~/ 1000}rb" : inc)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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

            // Slide to Confirm (GoPay / Banking Style Drag to Confirm)
            SlideToConfirm(
              text: 'Geser untuk Simpan Mutasi',
              isLoading: _isProcessing,
              onConfirmed: _handleConfirmSync,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Geser ke kanan untuk memvalidasi & memasukkan ke ledger',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.getTextSecondary(context),
                  fontWeight: FontWeight.w500,
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
