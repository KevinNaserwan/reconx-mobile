import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_sync_service.dart';
import '../theme/app_theme.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  bool _hasPrompted = false;

  /// Proactively request Camera and Notification runtime permissions
  Future<void> requestAppPermissions(BuildContext context) async {
    if (_hasPrompted) return;
    _hasPrompted = true;

    // Check if camera or notification is not granted yet
    final cameraStatus = await Permission.camera.status;
    final notificationStatus = await Permission.notification.status;
    final hasNotificationListener = ApiSyncService().hasPermission;

    if (!cameraStatus.isGranted || !notificationStatus.isGranted || !hasNotificationListener) {
      if (context.mounted) {
        _showOnboardingPermissionDialog(context);
      }
    }
  }

  /// Request single camera permission directly (e.g. before taking receipt photo)
  Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.dangerRose,
          content: const Text('Izin kamera dibutuhkan untuk memotret nota fisik / QRIS.'),
          action: SnackBarAction(
            label: 'Buka Settings',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
    return false;
  }

  void _showOnboardingPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security_rounded, color: AppTheme.primaryEmerald, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Izin Akses Reconx',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agar Reconx dapat bekerja optimal merekonsiliasi transaksi finansial keluarga secara otomatis, mohon aktifkan izin berikut:',
              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              icon: Icons.camera_alt_rounded,
              title: 'Kamera & Foto',
              desc: 'Untuk scan struk kasir fisik & bukti transfer',
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              icon: Icons.notifications_active_rounded,
              title: 'Notifikasi Aplikasi',
              desc: 'Menerima alert sinkronisasi pengeluaran keluarga',
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              icon: Icons.sync_rounded,
              title: 'Intersepsi Status Bar Bank',
              desc: 'Membaca otomatis mutasi BCA, Mandiri, SeaBank, dll',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti Saja', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Request native Android permissions
              await [
                Permission.camera,
                Permission.notification,
              ].request();

              // If Notification Listener is not granted, guide user to system settings
              if (!ApiSyncService().hasPermission) {
                await ApiSyncService().openPermissionSettings();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryEmerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Izinkan Semua', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.darkBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryEmerald),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
