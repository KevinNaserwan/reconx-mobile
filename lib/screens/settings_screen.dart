import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_sync_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiSyncService().backendUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleTestPing() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    await ApiSyncService().setBackendUrl(_urlController.text.trim());
    final ok = await ApiSyncService().testConnection();

    setState(() {
      _isTesting = false;
      _testResult = ok
          ? 'Connected! Latency: ${ApiSyncService().latencyMs}ms'
          : 'Failed to connect. Make sure server is reachable.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final syncService = ApiSyncService();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        title: Text(
          'Settings & Sync Agent',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkCardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryEmerald),
                    ),
                    child: const Center(
                      child: Text(
                        'KN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Kevin Naserwan',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          user?.email ?? 'kevin.naserwan@reconx.io',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.darkTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryEmerald.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Google SSO Active',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.primaryEmerald,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Access Permission
            Text(
              'ANDROID NOTIFICATION PERMISSION',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkTextSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        syncService.hasPermission ? Icons.check_circle : Icons.warning_rounded,
                        color: syncService.hasPermission ? AppTheme.primaryEmerald : Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        syncService.hasPermission
                            ? 'Notification Listener: GRANTED'
                            : 'Notification Listener: ACTION REQUIRED',
                        style: GoogleFonts.plusJakartaSans(
                          color: syncService.hasPermission ? AppTheme.primaryEmerald : Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Izin ini diperlukan agar aplikasi dapat membaca notifikasi transaksi dari blu BCA, SeaBank, Superbank, ShopeePay, Tokopedia, OVO & Bibit.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.darkTextSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => syncService.openPermissionSettings(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryEmerald,
                        side: const BorderSide(color: AppTheme.primaryEmerald),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Buka Pengaturan Izin Android',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Server Endpoint Configuration
            Text(
              'RECONX SERVER ENDPOINT',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkTextSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _urlController,
                    style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.darkBg,
                      labelText: 'API Base URL',
                      labelStyle: GoogleFonts.plusJakartaSans(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.darkCardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isTesting ? null : _handleTestPing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkBg,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.darkCardBorder),
                        ),
                      ),
                      child: _isTesting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Test Connection Ping',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _testResult!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _testResult!.startsWith('Connected')
                            ? AppTheme.primaryEmerald
                            : AppTheme.dangerRose,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                onPressed: () async {
                  await AuthService().signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppTheme.dangerRose),
                label: Text(
                  'Sign Out from Google',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.dangerRose,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
