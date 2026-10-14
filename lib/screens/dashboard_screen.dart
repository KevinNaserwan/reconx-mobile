import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';
import '../services/api_sync_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
  void initState() {
    super.initState();
    ApiSyncService().init();
  }

  void _showTestNotificationSheet() {
    final textController = TextEditingController(
      text: 'Pembayaran QRIS sebesar Rp 65.000 ke Solaria telah berhasil.',
    );
    String selectedPkg = 'id.co.bcadigital.blu';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Simulasi Notifikasi Masuk',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pilih channel pembayaran:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: monitoredApps.map((app) {
                      final isSelected = selectedPkg == app['pkg'];
                      return ChoiceChip(
                        label: Text(app['name']!),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryEmerald.withOpacity(0.2),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.primaryEmerald : Colors.white70,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryEmerald : AppTheme.darkCardBorder,
                        ),
                        backgroundColor: AppTheme.darkBg,
                        onSelected: (val) {
                          setSheetState(() {
                            selectedPkg = app['pkg']!;
                            if (app['name']!.contains('Pluang')) {
                              textController.text = 'Pembelian Saham AS NVDA senilai Rp 500.000 telah berhasil dieksekusi di market.';
                            } else if (app['name']!.contains('Bibit')) {
                              textController.text = 'Pembelian Reksa Dana Pasar Uang senilai Rp 1.000.000 telah diverifikasi KSEI.';
                            } else if (app['name']!.contains('Bareksa')) {
                              textController.text = 'Order Reksa Dana Pendapatan Tetap sebesar Rp 750.000 telah sukses.';
                            } else if (app['name']!.contains('Ajaib')) {
                              textController.text = 'Order Beli Saham BBCA Rp 2.500.000 telah MATCH di bursa.';
                            } else if (app['name']!.contains('Stockbit')) {
                              textController.text = 'Order buy 10 lot BMRI Rp 6.800.000 telah executed.';
                            } else if (app['name']!.contains('blu')) {
                              textController.text = 'Pembayaran QRIS sebesar Rp 45.000 ke Kopi Kenangan telah berhasil.';
                            } else if (app['name']!.contains('Shopee')) {
                              textController.text = 'Pembayaran sebesar Rp 135.000 ke Toko Komputer Sukses telah selesai.';
                            } else if (app['name']!.contains('SeaBank')) {
                              textController.text = 'Transfer masuk Rp 500.000 dari BCA Digital berhasil.';
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.darkBg,
                      hintText: 'Teks notifikasi masuk...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.darkCardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.darkCardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final selectedAppObj = monitoredApps.firstWhere((a) => a['pkg'] == selectedPkg);
                        await ApiSyncService().syncNotification(
                          appPackage: selectedPkg,
                          appName: selectedAppObj['name'],
                          title: 'Transaksi Sukses',
                          content: textController.text,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primaryEmerald,
                              content: Text(
                                'Transaksi berhasil disinkronkan ke ReconX Web!',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        'Kirim Notifikasi ke Ledger',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
            backgroundColor: AppTheme.darkBg,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryEmerald, AppTheme.primaryTeal],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'X',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ReconX Mobile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user?.email ?? 'kevin.naserwan@reconx.io',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.darkTextSecondary,
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
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
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
                              'Memonitor mutasi bank & e-wallet real-time',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.darkTextSecondary,
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

                // Monitored Channels
                Text(
                  'APLIKASI TERHUBUNG (7 KANAL)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkTextSecondary,
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
                          border: Border.all(color: AppTheme.darkCardBorder),
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
                      'LIVE NOTIFICATION FEED',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkTextSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '${syncService.history.length} records',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.primaryEmerald,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transactions Feed List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: syncService.history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final item = syncService.history[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.darkCardBorder),
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
                                  color: AppTheme.primaryEmerald.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.appName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryEmerald,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm').format(item.timestamp),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.darkTextSecondary,
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
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryEmerald,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.darkTextSecondary,
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showTestNotificationSheet,
            backgroundColor: AppTheme.primaryEmerald,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.flash_on_rounded),
            label: Text(
              'Test Notifikasi',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
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
        border: Border.all(color: AppTheme.darkCardBorder),
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
              color: AppTheme.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
