import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_sync_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
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
    {'name': 'Pluang (Emas & Saham)', 'pkg': 'com.pluang.android', 'color': '0xFFFBBF24'},
    {'name': 'Bibit (Investasi)', 'pkg': 'com.bibit.id', 'color': '0xFF14B8A6'},
    {'name': 'Bareksa', 'pkg': 'com.bareksa.android', 'color': '0xFF10B981'},
    {'name': 'Ajaib Sekuritas', 'pkg': 'com.ajaib.android', 'color': '0xFF3B82F6'},
    {'name': 'Stockbit Saham', 'pkg': 'id.stockbit.android', 'color': '0xFF6366F1'},
    {'name': 'blu by BCA', 'pkg': 'id.co.bcadigital.blu', 'color': '0xFF06B6D4'},
    {'name': 'SeaBank', 'pkg': 'com.searpm.bank', 'color': '0xFFF97316'},
    {'name': 'Superbank', 'pkg': 'id.superbank.app', 'color': '0xFFA855F7'},
    {'name': 'ShopeePay', 'pkg': 'com.shopee.id', 'color': '0xFFF59E0B'},
    {'name': 'Tokopedia', 'pkg': 'com.tokopedia.tkpd', 'color': '0xFF10B981'},
    {'name': 'OVO', 'pkg': 'ovo.id', 'color': '0xFF8B5CF6'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return ListenableBuilder(
      listenable: ApiSyncService(),
      builder: (context, _) {
        final syncService = ApiSyncService();

        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          appBar: AppBar(
            backgroundColor: AppTheme.darkCard,
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
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user?.email.isNotEmpty == true ? user!.email : 'Online Sync Engine',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white70),
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
                        ? AppTheme.primaryEmerald.withOpacity(0.12)
                        : Colors.amber.withOpacity(0.12),
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
                                color: Colors.white54,
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
                        'Total Terdata',
                        currencyFormat.format(syncService.syncedVolumeToday),
                        Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        'Transaksi',
                        '${syncService.syncedCountToday} Trx',
                        Icons.sync_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
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
                            color: AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryEmerald.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 20, color: AppTheme.primaryEmerald),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Scan Nota Fisik',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                            color: AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.darkBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryCyan.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.receipt_long_rounded, size: 20, color: AppTheme.primaryCyan),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Lihat Mutasi',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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

                const SizedBox(height: 20),

                // Monitored Channels
                Text(
                  'APLIKASI TERHUBUNG (11 KANAL)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white54,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: monitoredApps.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, idx) {
                      final item = monitoredApps[idx];
                      final color = Color(int.parse(item['color']!));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item['name']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Live Feed Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MUTASI TERBARU',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white54,
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
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded, size: 38, color: Colors.white30),
                        const SizedBox(height: 10),
                        Text(
                          'Belum Ada Mutasi Hari Ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Notifikasi dari bank atau scan struk fisik akan otomatis masuk dan terekonsiliasi.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white54,
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
                      final isReceipt = item.channel.contains('RECEIPT');

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isReceipt
                                ? AppTheme.primaryEmerald.withOpacity(0.3)
                                : AppTheme.darkBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isReceipt ? AppTheme.primaryTeal : AppTheme.primaryEmerald).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.appName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isReceipt ? AppTheme.primaryTeal : AppTheme.primaryEmerald,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(item.timestamp),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.merchant,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(item.amount),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryEmerald,
                                  ),
                                ),
                              ],
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

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryEmerald),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
