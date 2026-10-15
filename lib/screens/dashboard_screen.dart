import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_sync_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_badge.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

    return ListenableBuilder(
      listenable: ApiSyncService(),
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
                      'Reconx',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                    Text(
                      user?.email.isNotEmpty == true ? user!.email : 'Online Sync Engine',
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
                  themeService.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: AppTheme.getTextSecondary(context),
                ),
                tooltip: 'Ganti Mode Tema (Terang / Gelap)',
                onPressed: () => themeService.toggleTheme(),
              ),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: AppTheme.getTextSecondary(context)),
                onPressed: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(4); // Navigate to Settings Tab
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: syncService.isServiceActive
                              ? AppTheme.primaryEmerald
                              : Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              syncService.isServiceActive
                                  ? 'Background Sync: ACTIVE'
                                  : 'Background Sync: PAUSED',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: syncService.isServiceActive
                                  ? AppTheme.primaryEmerald
                                  : Colors.amber,
                              ),
                            ),
                            Text(
                              'Memonitor mutasi bank, e-wallet, & nota fisik',
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

                // Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        'Total Terdata',
                        currencyFormat.format(syncService.syncedVolumeToday),
                        Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        'Transaksi',
                        '${syncService.syncedCountToday} Trx',
                        Icons.sync_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        'Latency',
                        '${syncService.latencyMs}ms',
                        Icons.speed_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Quick Action Cards
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onNavigateTab?.call(2), // Scan Nota Tab
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.getCard(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryEmerald.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppTheme.primaryEmerald),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Pindai QRIS & Nota',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.getTextPrimary(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onNavigateTab?.call(1), // Mutasi Tab
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.getCard(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.getBorder(context)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryCyan.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.receipt_long_rounded, size: 20, color: AppTheme.primaryCyan),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Lihat Mutasi',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.getTextPrimary(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Monitored Apps Grid with Brand Badges
                Text(
                  'APLIKASI & BANK TERPANTAU',
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

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.getCard(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isEnabled
                                ? AppTheme.primaryEmerald.withOpacity(0.4)
                                : AppTheme.getBorder(context),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BrandBadgeHelper.buildBadgeWidget(item['name']!, item['name']!, size: 26),
                            const SizedBox(width: 8),
                            Text(
                              item['name']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isEnabled
                                    ? AppTheme.getTextPrimary(context)
                                    : AppTheme.getTextSecondary(context),
                              ),
                            ),
                          ],
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
                      'MUTASI TERBARU',
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
                        'Lihat Semua (${syncService.history.length})',
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
                          'Belum Ada Mutasi Hari Ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Notifikasi dari bank atau scan struk fisik akan otomatis masuk dan terekonsiliasi.',
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
                              currencyFormat.format(item.amount),
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
}
