import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_sync_service.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_notification_banner.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    BiometricService().init();
  }

  void _showEditProfileDialog() {
    final user = AuthService().currentUser;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    final familyCtrl = TextEditingController(text: user?.familyName ?? '');
    final photoCtrl = TextEditingController(text: user?.photoUrl ?? '');
    String selectedRole = user?.role ?? 'Kevin (Partner)';

    final isDark = AppTheme.isDark(context);
    final lang = LanguageService();

    final roles = [
      'Kevin (Partner)',
      'Anan (Partner)',
      'Partner / Pasangan',
      'Personal / Individu',
      'Head of Household',
    ];

    if (!roles.contains(selectedRole)) {
      roles.insert(0, selectedRole);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppTheme.getBorder(context)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.tr('edit_profile'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perbarui profil Anda untuk sinkronisasi rekonsiliasi pasangan (couple).',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Foto Profil (URL)
                  _buildInputLabel('Foto Profil (URL Google / Avatar)', context),
                  const SizedBox(height: 6),
                  TextField(
                    controller: photoCtrl,
                    style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14),
                    decoration: _inputDecoration('https://... (Foto Google atau Avatar)', context),
                  ),
                  const SizedBox(height: 14),

                  // Nama Lengkap
                  _buildInputLabel('Nama Lengkap', context),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14),
                    decoration: _inputDecoration('Contoh: Kevin Naserwan', context),
                  ),
                  const SizedBox(height: 14),

                  // Email
                  _buildInputLabel('Alamat Email', context),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14),
                    decoration: _inputDecoration('kevin@example.com', context),
                  ),
                  const SizedBox(height: 14),

                  // Nomor WhatsApp / HP
                  _buildInputLabel('Nomor WhatsApp / HP', context),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14),
                    decoration: _inputDecoration('081234567890', context),
                  ),
                  const SizedBox(height: 14),

                  // Peran Finansial
                  _buildInputLabel('Peran Finansial', context),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.getBorder(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        isExpanded: true,
                        dropdownColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 13),
                        items: roles.map((r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(r),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedRole = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Nama Cluster Pasangan / Keluarga
                  _buildInputLabel('Nama Cluster Pasangan', context),
                  const SizedBox(height: 6),
                  TextField(
                    controller: familyCtrl,
                    style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 14),
                    decoration: _inputDecoration('Kevin & Anan (Couple)', context),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Simpan
                  ElevatedButton(
                    onPressed: () async {
                      final n = nameCtrl.text.trim();
                      final e = emailCtrl.text.trim();
                      final p = phoneCtrl.text.trim();
                      final f = familyCtrl.text.trim();
                      final ph = photoCtrl.text.trim();

                      if (n.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama lengkap wajib diisi.')),
                        );
                        return;
                      }

                      await AuthService().updateProfile(
                        name: n,
                        email: e.isNotEmpty ? e : (user?.email ?? ''),
                        phoneNumber: p,
                        role: selectedRole,
                        familyName: f.isNotEmpty ? f : 'Kevin & Anan (Couple)',
                        photoUrl: ph,
                      );

                      if (mounted) {
                        Navigator.pop(ctx);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppTheme.primaryEmerald,
                            content: Text('Profil dan foto pribadi berhasil disimpan!'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      lang.tr('save_changes'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text, BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.getTextPrimary(context),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.getTextSecondary(context).withOpacity(0.6), fontSize: 13),
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

  void _showResetConfirmDialog() {
    final isDark = AppTheme.isDark(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Seluruh Data Lokal?',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.getTextPrimary(context),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Tindakan ini akan mengosongkan seluruh riwayat mutasi tersimpan dan hitungan volume harian pada perangkat ini. Apakah Anda yakin?',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.getTextSecondary(context), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: AppTheme.getTextSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiSyncService().resetAllData();
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua data mutasi lokal berhasil di-reset.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRose),
            child: const Text('Ya, Reset Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final syncService = ApiSyncService();
    final themeService = ThemeService();
    final lang = LanguageService();
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getCard(context),
        elevation: 0,
        title: Text(
          lang.tr('settings_title'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.getCard(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.getBorder(context)),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (user?.photoUrl != null && user!.photoUrl.isNotEmpty)
                        ClipOval(
                          child: Image.network(
                            user.photoUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => CircleAvatar(
                              radius: 28,
                              backgroundColor: AppTheme.primaryEmerald.withOpacity(0.2),
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'K',
                                style: const TextStyle(
                                  color: AppTheme.primaryEmerald,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryEmerald.withOpacity(0.2),
                          child: Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'K',
                            style: const TextStyle(
                              color: AppTheme.primaryEmerald,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Kevin Naserwan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.getTextPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'kevin@example.com',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                            if (user?.phoneNumber != null && user!.phoneNumber.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                user.phoneNumber,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.getTextSecondary(context),
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user?.role ?? 'Kevin (Partner)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(
                        lang.tr('edit_profile'),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryEmerald,
                        side: const BorderSide(color: AppTheme.primaryEmerald),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Language Selector Section (ID, EN, ZH)
            Text(
              lang.tr('lang_title'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.getTextSecondary(context),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getCard(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Row(
                children: [
                  _buildOptionItem(
                    title: '🇮🇩 Indonesia',
                    isSelected: lang.currentLanguage == 'id',
                    onTap: () => lang.setLanguage('id'),
                  ),
                  const SizedBox(width: 8),
                  _buildOptionItem(
                    title: '🇬🇧 English',
                    isSelected: lang.currentLanguage == 'en',
                    onTap: () => lang.setLanguage('en'),
                  ),
                  const SizedBox(width: 8),
                  _buildOptionItem(
                    title: '🇨🇳 中文',
                    isSelected: lang.currentLanguage == 'zh',
                    onTap: () => lang.setLanguage('zh'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Theme Mode Selector (White / Dark Mode)
            Text(
              lang.tr('theme_title'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.getTextSecondary(context),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getCard(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Row(
                children: [
                  _buildThemeOption(
                    title: lang.tr('theme_dark'),
                    icon: Icons.dark_mode_rounded,
                    isSelected: themeService.themeMode == ThemeMode.dark,
                    onTap: () => themeService.setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    title: lang.tr('theme_light'),
                    icon: Icons.light_mode_rounded,
                    isSelected: themeService.themeMode == ThemeMode.light,
                    onTap: () => themeService.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    title: lang.tr('theme_system'),
                    icon: Icons.smartphone_rounded,
                    isSelected: themeService.themeMode == ThemeMode.system,
                    onTap: () => themeService.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bank & E-Wallet Notification Whitelist Settings
            Text(
              lang.tr('notify_sources'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.getTextSecondary(context),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getCard(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.tr('notify_sources_desc'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterTile('BCA (BCA Mobile, myBCA, blu)', 'bca', syncService),
                  _buildFilterTile("Mandiri (Livin' by Mandiri)", 'mandiri', syncService),
                  _buildFilterTile('BRI (BRImo)', 'bri', syncService),
                  _buildFilterTile('BNI (BNI Mobile Banking)', 'bni', syncService),
                  _buildFilterTile('SeaBank Indonesia', 'seabank', syncService),
                  _buildFilterTile('GoPay / Gojek', 'gopay', syncService),
                  _buildFilterTile('OVO', 'ovo', syncService),
                  _buildFilterTile('DANA Indonesia', 'dana', syncService),
                  _buildFilterTile('ShopeePay & SPayLater', 'shopee', syncService),
                  _buildFilterTile('Superbank', 'superbank', syncService),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Enterprise Security & Biometric Section
            Text(
              lang.tr('security_title'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.getTextSecondary(context),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            ListenableBuilder(
              listenable: BiometricService(),
              builder: (context, _) {
                final bio = BiometricService();

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.getCard(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.getBorder(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fingerprint_rounded, size: 24, color: AppTheme.primaryEmerald),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.tr('fingerprint'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.getTextPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lang.tr('fingerprint_desc'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: bio.isBiometricEnabled,
                        activeColor: AppTheme.primaryEmerald,
                        onChanged: (val) async {
                          final ok = await bio.setBiometricEnabled(val);
                          if (!ok && val && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sensor sidik jari tidak tersedia atau verifikasi dibatalkan.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Notification Interceptor Permission Status
            Text(
              lang.tr('interceptor_title'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.getTextSecondary(context),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getCard(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        syncService.hasPermission ? Icons.check_circle_rounded : Icons.warning_rounded,
                        color: syncService.hasPermission ? AppTheme.primaryEmerald : AppTheme.dangerRose,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              syncService.hasPermission ? lang.tr('interceptor_active') : lang.tr('interceptor_inactive'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.getTextPrimary(context),
                              ),
                            ),
                            Text(
                              'Intersepsi otomatis dari bank dan e-wallet yang aktif.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!syncService.hasPermission) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => syncService.openPermissionSettings(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryEmerald,
                          side: const BorderSide(color: AppTheme.primaryEmerald),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Aktifkan Izin di Android'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        FloatingNotificationBanner.show(
                          context,
                          title: 'QRIS Pembayaran Terdeteksi',
                          subtitle: 'BCA Mobile • Kopi Kenangan Mall',
                          amount: 38000,
                          brand: 'QRIS BCA',
                        );
                      },
                      icon: const Icon(Icons.motion_photos_on_rounded, size: 18),
                      label: const Text('Uji Animasi Floating Notification'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryEmerald,
                        side: BorderSide(color: AppTheme.primaryEmerald.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Factory Reset Local Data Button
            OutlinedButton.icon(
              onPressed: _showResetConfirmDialog,
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.dangerRose),
              label: Text(
                lang.tr('reset_data'),
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.dangerRose,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.dangerRose),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 14),

            // Sign Out Button (Firm Red Style per user request)
            ElevatedButton.icon(
              onPressed: _handleSignOut,
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              label: Text(
                lang.tr('logout'),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRose,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryEmerald.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryEmerald : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.primaryEmerald : AppTheme.getTextSecondary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryEmerald.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryEmerald : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primaryEmerald : AppTheme.getTextSecondary(context),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryEmerald : AppTheme.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTile(String title, String key, ApiSyncService syncService) {
    final enabled = syncService.appFilters[key] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
          ),
          Switch(
            value: enabled,
            activeColor: AppTheme.primaryEmerald,
            onChanged: (val) {
              syncService.toggleAppFilter(key, val);
            },
          ),
        ],
      ),
    );
  }
}
