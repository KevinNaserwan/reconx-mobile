import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/transaction_item.dart';
import '../services/api_sync_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_badge.dart';

class TransactionsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToScan;

  const TransactionsScreen({super.key, this.onNavigateToScan});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  NumberFormat get currencyFormat {
    try {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    } catch (_) {
      return NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
    }
  }

  DateFormat get dateFormat {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    } catch (_) {
      return DateFormat('dd MMM yyyy, HH:mm');
    }
  }

  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> _filters = [
    'Semua',
    'QRIS',
    'Transfer Bank',
    'E-Wallet',
    'Scan Nota',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleExportCSV(List<SyncedTransaction> list) {
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada transaksi untuk di-export.')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('ID,Waktu,Merchant,Aplikasi,Kanal,Nominal,Status');
    for (final tx in list) {
      buffer.writeln('"${tx.id}","${dateFormat.format(tx.timestampWib)} WIB","${tx.merchant}","${tx.appName}","${tx.channel}",${tx.amount},"${tx.status}"');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Rekap Mutasi CSV Disalin',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        content: Text(
          'Sebanyak ${list.length} baris data mutasi finansial keluarga berhasil diformat ke CSV dan disalin ke clipboard HP Anda. Anda dapat langsung paste ke Excel, Google Sheets, atau WhatsApp.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: AppTheme.dangerRose, size: 24),
            const SizedBox(width: 10),
            Text(
              'Reset Data Mutasi',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
          ],
        ),
        content: Text(
          'Seluruh riwayat transaksi mutasi lokal akan dikosongkan (0 transaksi). Anda dapat memulai pencatatan dari awal lagi.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: TextStyle(color: AppTheme.getTextSecondary(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              await ApiSyncService().resetAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.primaryEmerald,
                    content: Text(
                      'Riwayat mutasi berhasil dikosongkan (0 transaksi).',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reset Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(SyncedTransaction tx) {
    final isDark = AppTheme.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Transaksi Rekonsiliasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextPrimary(context),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, color: AppTheme.getTextSecondary(context)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.getBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BrandBadgeHelper.buildBadgeWidget(tx.appName, tx.merchant, channel: tx.channel, size: 52),
                    const SizedBox(height: 10),
                    Text(
                      tx.merchant,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(tx.amount),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tx.status == 'SYNCED_TO_LEDGER' ? 'Terekonsiliasi ke Ledger' : 'Tersimpan Offline',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow('ID Transaksi', tx.id),
              _buildDetailRow('Sumber / Aplikasi', tx.appName),
              _buildDetailRow('Kanal Pembayaran', tx.channel),
              _buildDetailRow('Waktu Transaksi (WIB)', '${dateFormat.format(tx.timestampWib)} WIB'),
              _buildDetailRow('Catatan Raw', tx.content),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.darkCard : const Color(0xFFE2E8F0),
                    foregroundColor: AppTheme.getTextPrimary(context),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.getTextSecondary(context),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimary(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getCard(context),
        elevation: 0,
        title: Text(
          LanguageService().tr('nav_mutasi'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: AppTheme.getTextSecondary(context)),
            tooltip: LanguageService().tr('export_csv'),
            onPressed: () => _handleExportCSV(ApiSyncService().history),
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: AppTheme.getTextSecondary(context)),
            tooltip: 'Reset Data Mutasi',
            onPressed: () => _showResetConfirmationDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryEmerald),
            tooltip: LanguageService().tr('scan_title'),
            onPressed: widget.onNavigateToScan,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([ApiSyncService(), LanguageService()]),
        builder: (context, _) {
          final history = ApiSyncService().history;

          final filtered = history.where((tx) {
            if (_selectedFilter == 'QRIS') {
              if (!tx.channel.toLowerCase().contains('qris') &&
                  !tx.appName.toLowerCase().contains('qris') &&
                  !tx.merchant.toLowerCase().contains('qris')) {
                return false;
              }
            } else if (_selectedFilter == 'Transfer Bank') {
              if (!tx.appName.toLowerCase().contains('bca') &&
                  !tx.appName.toLowerCase().contains('mandiri') &&
                  !tx.appName.toLowerCase().contains('bri') &&
                  !tx.appName.toLowerCase().contains('bni') &&
                  !tx.appName.toLowerCase().contains('seabank') &&
                  !tx.appName.toLowerCase().contains('bank')) {
                return false;
              }
            } else if (_selectedFilter == 'E-Wallet') {
              if (!tx.appName.toLowerCase().contains('gopay') &&
                  !tx.appName.toLowerCase().contains('ovo') &&
                  !tx.appName.toLowerCase().contains('dana') &&
                  !tx.appName.toLowerCase().contains('shopee')) {
                return false;
              }
            } else if (_selectedFilter == 'Scan Nota') {
              if (!tx.channel.toLowerCase().contains('receipt')) {
                return false;
              }
            }

            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              return tx.merchant.toLowerCase().contains(query) ||
                  tx.appName.toLowerCase().contains(query) ||
                  tx.content.toLowerCase().contains(query);
            }

            return true;
          }).toList();

          return Column(
            children: [
              // Search & Filter Box
              Container(
                color: AppTheme.getCard(context),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari nama merchant atau transaksi...',
                        hintStyle: TextStyle(color: AppTheme.getTextSecondary(context).withOpacity(0.6), fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppTheme.getTextSecondary(context)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((f) {
                          final isSelected = _selectedFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryEmerald.withOpacity(0.2),
                              backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF1F5F9),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.primaryEmerald
                                    : AppTheme.getTextSecondary(context),
                              ),
                              side: BorderSide(
                                color: isSelected ? AppTheme.primaryEmerald : AppTheme.getBorder(context),
                              ),
                              onSelected: (_) => setState(() => _selectedFilter = f),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction List
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primaryEmerald,
                  backgroundColor: AppTheme.getCard(context),
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    await ApiSyncService().syncActiveNotifications();
                  },
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: _buildEmptyState(),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                          final tx = filtered[idx];

                          return InkWell(
                            onTap: () => _showTransactionDetails(tx),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.getCard(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.getBorder(context)),
                              ),
                              child: Row(
                                children: [
                                  BrandBadgeHelper.buildBadgeWidget(
                                    tx.appName,
                                    tx.merchant,
                                    channel: tx.channel,
                                    size: 44,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.merchant,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.getTextPrimary(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${tx.appName} • ${dateFormat.format(tx.timestampWib)} WIB',
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
                                    currencyFormat.format(tx.amount),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryEmerald,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.getCard(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.getBorder(context)),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 36,
                color: AppTheme.getTextSecondary(context).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum Ada Mutasi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaksi yang terdeteksi dari status bar notifikasi bank atau scan struk fisik akan otomatis tersinkronisasi di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
