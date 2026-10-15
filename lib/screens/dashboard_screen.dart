import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_sync_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/brand_badge.dart';
import '../widgets/floating_notification_banner.dart';
import '../widgets/radar_pulse_indicator.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  bool _isBalanceMasked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ApiSyncService().checkPermission();
    ApiSyncService().syncActiveNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ApiSyncService().checkPermission();
      ApiSyncService().syncActiveNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  NumberFormat get currencyFormat {
    try {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    } catch (_) {
      return NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
    }
  }

  final List<Map<String, String>> monitoredApps = [
    {'name': 'BCA (Mobile / blu)', 'key': 'bca', 'tag': 'BCA'},
    {'name': "Mandiri (Livin')", 'key': 'mandiri', 'tag': 'Livin'},
    {'name': 'BRI (BRImo)', 'key': 'bri', 'tag': 'BRI'},
    {'name': 'BNI Mobile', 'key': 'bni', 'tag': 'BNI'},
    {'name': 'SeaBank', 'key': 'seabank', 'tag': 'SeaBank'},
    {'name': 'GoPay / Gojek', 'key': 'gopay', 'tag': 'GoPay'},
    {'name': 'OVO', 'key': 'ovo', 'tag': 'OVO'},
    {'name': 'DANA Indonesia', 'key': 'dana', 'tag': 'DANA'},
    {'name': 'ShopeePay & SPayLater', 'key': 'shopee', 'tag': 'Shopee'},
    {'name': 'Superbank', 'key': 'superbank', 'tag': 'Superbank'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isDark = AppTheme.isDark(context);
    final themeService = ThemeService();
    final lang = LanguageService();

    return ListenableBuilder(
      listenable: Listenable.merge([ApiSyncService(), LanguageService()]),
      builder: (context, _) {
        final syncService = ApiSyncService();

        return Scaffold(
          backgroundColor: AppTheme.getBg(context),
          appBar: AppBar(
            backgroundColor: AppTheme.getCard(context),
            elevation: 0,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/icon.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.tr('app_title'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                    Text(
                      user?.email.isNotEmpty == true ? user!.email : 'Enterprise Sync Engine',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isBalanceMasked ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppTheme.getTextSecondary(context),
                ),
                tooltip: _isBalanceMasked ? 'Tampilkan Saldo' : 'Sembunyikan Saldo (Privacy)',
                onPressed: () => setState(() => _isBalanceMasked = !_isBalanceMasked),
              ),
              IconButton(
                icon: Icon(
                  themeService.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: AppTheme.getTextSecondary(context),
                ),
                tooltip: 'Ganti Mode Tema (Terang / Gelap)',
                onPressed: () => themeService.toggleTheme(),
              ),
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(4); // Navigate to Settings Tab
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Center(
                    child: AppAvatar(
                      photoUrl: user?.photoUrl,
                      name: user?.name ?? 'Kevin',
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppTheme.primaryEmerald,
            backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
            onRefresh: () async {
              await syncService.checkPermission();
              await syncService.rebindListenerService();
              final count = await syncService.syncActiveNotifications();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: count > 0 ? AppTheme.primaryEmerald : const Color(0xFF1E293B),
                    content: Text(
                      count > 0
                          ? 'Sukses mencatat $count transaksi baru dari notifikasi HP!'
                          : 'Notifikasi status bar diperiksa. Tidak ada transaksi baru.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: count > 0 ? Colors.black : Colors.white,
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 0. Notification Permission Warning (Actionable)
                if (!syncService.hasPermission) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Akses Notifikasi Android Belum Aktif',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agar notifikasi pembayaran QRIS (blu BCA, BCA, Mandiri, dll) dapat otomatis tercatat ke pembukuan, izin Akses Notifikasi wajib diaktifkan.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            height: 1.4,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => syncService.openPermissionSettings(),
                                icon: const Icon(Icons.security_update_good_rounded, size: 16),
                                label: const Text(
                                  'Aktifkan Izin Notifikasi',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryEmerald,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _showRestrictedSettingsGuide(context),
                              icon: const Icon(Icons.help_outline_rounded, color: Colors.amber),
                              tooltip: 'Panduan Android 13/14 (Setelan Dibatasi)',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Service Active Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: syncService.isServiceActive
                        ? AppTheme.primaryEmerald.withOpacity(isDark ? 0.12 : 0.08)
                        : Colors.amber.withOpacity(isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: syncService.isServiceActive
                          ? AppTheme.primaryEmerald.withOpacity(0.3)
                          : Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      RadarPulseIndicator(
                        size: 11,
                        color: syncService.isServiceActive
                            ? AppTheme.primaryEmerald
                            : Colors.amber,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              syncService.isServiceActive
                                  ? lang.tr('status_active')
                                  : lang.tr('status_paused'),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: syncService.isServiceActive
                                    ? AppTheme.primaryEmerald
                                    : Colors.amber,
                              ),
                            ),
                            Text(
                              lang.tr('status_desc'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: syncService.isServiceActive,
                        activeColor: AppTheme.primaryEmerald,
                        onChanged: (val) => syncService.setServiceActive(val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Metrics Row (With Privacy Eye Toggle)
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildMetricCard(
                        context,
                        lang.tr('total_tracked'),
                        _isBalanceMasked ? '••••••••' : currencyFormat.format(syncService.syncedVolumeToday),
                        Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _buildMetricCard(
                        context,
                        lang.tr('transactions'),
                        '${syncService.syncedCountToday} Trx',
                        Icons.sync_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _buildMetricCard(
                        context,
                        lang.tr('latency'),
                        '${syncService.latencyMs}ms',
                        Icons.speed_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Enterprise Security & Double-Counting Guard Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.getCard(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.getBorder(context)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppTheme.primaryEmerald, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Enkripsi 256-bit TLS • Anti-Double Counting Aktif',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Monitored Apps Grid with Brand Badges
                Text(
                  lang.tr('monitored_apps'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.getTextSecondary(context),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: monitoredApps.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, idx) {
                      final item = monitoredApps[idx];
                      final isEnabled = syncService.appFilters[item['key']] ?? true;

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          syncService.toggleAppFilter(item['key']!, !isEnabled);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? AppTheme.getCard(context)
                                : (AppTheme.isDark(context) ? Colors.black26 : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isEnabled
                                  ? AppTheme.primaryEmerald.withOpacity(0.4)
                                  : AppTheme.getBorder(context).withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: isEnabled ? 1.0 : 0.4,
                                child: BrandBadgeHelper.buildBadgeWidget(item['name']!, item['name']!, size: 26),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item['name']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isEnabled
                                      ? AppTheme.getTextPrimary(context)
                                      : AppTheme.getTextSecondary(context).withOpacity(0.5),
                                ),
                              ),
                              if (isEnabled) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.primaryEmerald),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Transactions Feed Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.tr('recent_mutasi'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextSecondary(context),
                        letterSpacing: 0.8,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.onNavigateTab?.call(1), // Mutasi Tab
                      child: Text(
                        '${lang.tr('view_all')} (${syncService.history.length})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.primaryEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transactions Feed List or Clean Empty State
                if (syncService.history.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.getCard(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.getBorder(context)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded, size: 38, color: AppTheme.getTextSecondary(context).withOpacity(0.5)),
                        const SizedBox(height: 10),
                        Text(
                          lang.tr('no_mutasi_today'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.tr('no_mutasi_desc'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: syncService.history.take(5).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = syncService.history[idx];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.getCard(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.getBorder(context)),
                        ),
                        child: Row(
                          children: [
                            BrandBadgeHelper.buildBadgeWidget(item.appName, item.merchant, channel: item.channel, size: 42),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.merchant,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.getTextPrimary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.appName} • ${DateFormat('HH:mm').format(item.timestamp)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppTheme.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isBalanceMasked ? '••••••' : currencyFormat.format(item.amount),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryEmerald,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.getCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryEmerald),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.getTextPrimary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showRestrictedSettingsGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.getCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.primaryEmerald, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Panduan Akses Notifikasi Android',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Pada Android 13, 14, dan 15, fitur keamanan OS sering menampilkan pesan "Setelan Dibatasi" (Restricted Settings) saat mengaktifkan Akses Notifikasi.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4, color: AppTheme.getTextSecondary(context)),
            ),
            const SizedBox(height: 14),
            _buildGuideStep('1', 'Tutup aplikasi, lalu TAHAN ikon Reconx di home screen HP Anda.'),
            _buildGuideStep('2', 'Pilih menu "Info Aplikasi" (Ikon tanda seru ⓘ).'),
            _buildGuideStep('3', 'Tekan tombol Titik 3 di pojok kanan atas layar.'),
            _buildGuideStep('4', 'Pilih "Izinkan setelan terbatas" (Allow restricted settings).'),
            _buildGuideStep('5', 'Buka kembali Reconx > tekan "Aktifkan Izin Notifikasi" dan nyalakan centang Reconx.'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ApiSyncService().openPermissionSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Buka Pengaturan Sekarang', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
