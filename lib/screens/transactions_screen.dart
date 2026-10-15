import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';
import '../services/api_sync_service.dart';
import '../theme/app_theme.dart';

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

  void _showTransactionDetails(SyncedTransaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkCard,
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
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      tx.merchant,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(tx.amount),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
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
              _buildDetailRow('Waktu Transaksi', dateFormat.format(tx.timestamp)),
              _buildDetailRow('Catatan Raw', tx.content),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkBorder,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCard,
        elevation: 0,
        title: Text(
          'Mutasi & Rekonsiliasi',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: ApiSyncService(),
        builder: (context, _) {
          final allTransactions = ApiSyncService().history;

          // Filter by category / channel
          final filtered = allTransactions.where((tx) {
            final matchQuery = _searchQuery.isEmpty ||
                tx.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                tx.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                tx.amount.toString().contains(_searchQuery);

            if (!matchQuery) return false;

            if (_selectedFilter == 'QRIS') {
              return tx.channel.contains('QRIS') || tx.content.toLowerCase().contains('qris');
            } else if (_selectedFilter == 'Transfer Bank') {
              return tx.channel.contains('TRANSFER') || tx.appName.toLowerCase().contains('bank');
            } else if (_selectedFilter == 'E-Wallet') {
              return tx.channel.contains('WALLET') ||
                  tx.appName.toLowerCase().contains('shopee') ||
                  tx.appName.toLowerCase().contains('ovo') ||
                  tx.appName.toLowerCase().contains('gopay');
            } else if (_selectedFilter == 'Scan Nota') {
              return tx.channel.contains('RECEIPT');
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Search & Filter Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.darkCard,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.darkBg,
                        hintText: 'Cari merchant, toko, atau nominal...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.white54),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.white54),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                    const SizedBox(height: 12),
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
                              selectedColor: AppTheme.primaryEmerald,
                              backgroundColor: AppTheme.darkBg,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.white60,
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

              // Transactions List or Empty State
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final tx = filtered[idx];
                          final isReceipt = tx.channel.contains('RECEIPT');

                          return InkWell(
                            onTap: () => _showTransactionDetails(tx),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.darkCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isReceipt
                                      ? AppTheme.primaryEmerald.withOpacity(0.3)
                                      : AppTheme.darkBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isReceipt
                                          ? AppTheme.primaryEmerald.withOpacity(0.15)
                                          : AppTheme.primaryCyan.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isReceipt ? Icons.receipt_long_rounded : Icons.sync_alt_rounded,
                                      color: isReceipt ? AppTheme.primaryEmerald : AppTheme.primaryCyan,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.merchant,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${tx.appName} • ${dateFormat.format(tx.timestamp)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    currencyFormat.format(tx.amount),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                color: AppTheme.darkCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 36,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum Ada Mutasi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaksi yang terdeteksi dari status bar notifikasi bank atau foto nota pembayaran fisik akan otomatis tersinkronisasi di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onNavigateToScan,
              icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
              label: Text(
                'Scan Nota Fisik Sekarang',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
