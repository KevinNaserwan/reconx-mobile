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
  String _selectedMember = 'Semua Anggota';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> _filters = [
    'Semua',
    'Uang Keluar',
    'Uang Masuk',
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

  void _showManualEntryModal() {
    final isDark = AppTheme.isDark(context);
    String txType = 'EXPENSE';
    final amountController = TextEditingController();
    final merchantController = TextEditingController();
    final notesController = TextEditingController();
    String selectedApp = 'Tunai (Cash)';
    String selectedCategory = 'Makanan & Minuman';
    String selectedMember = 'Kevin (Saya)';

    final apps = [
      'Tunai (Cash)',
      'blu by BCA Digital',
      'BCA Mobile',
      "Livin' by Mandiri",
      'BRImo',
      'BNI Mobile',
      'SeaBank',
      'GoPay',
      'OVO',
      'DANA',
      'ShopeePay',
      'Lainnya',
    ];

    final categories = [
      'Makanan & Minuman',
      'Belanja Harian',
      'Gaji & Pendapatan',
      'Transportasi & Bensin',
      'Tagihan & Utilitas',
      'Kesehatan & Farmasi',
      'Pendidikan',
      'Investasi & Tabungan',
      'Hiburan & Rekreasi',
      'Lainnya',
    ];

    final members = ApiSyncService().familyMembers;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: AppTheme.getCard(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppTheme.getBorder(context)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Catat Mutasi Finansial Manual',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, color: AppTheme.getTextSecondary(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Type Segmented Toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() {
                            txType = 'EXPENSE';
                            if (selectedCategory == 'Gaji & Pendapatan') {
                              selectedCategory = 'Makanan & Minuman';
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: txType == 'EXPENSE'
                                  ? const Color(0xFFF43F5E).withOpacity(0.15)
                                  : (isDark ? AppTheme.darkBg : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: txType == 'EXPENSE'
                                    ? const Color(0xFFF43F5E)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '↑ Uang Keluar (Expense)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: txType == 'EXPENSE'
                                      ? const Color(0xFFF43F5E)
                                      : AppTheme.getTextSecondary(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() {
                            txType = 'INCOME';
                            selectedCategory = 'Gaji & Pendapatan';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: txType == 'INCOME'
                                  ? AppTheme.primaryEmerald.withOpacity(0.15)
                                  : (isDark ? AppTheme.darkBg : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: txType == 'INCOME'
                                    ? AppTheme.primaryEmerald
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '↓ Uang Masuk (Income)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: txType == 'INCOME'
                                      ? AppTheme.primaryEmerald
                                      : AppTheme.getTextSecondary(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Nominal
                  Text('Nominal Transaksi (Rp)', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.getTextSecondary(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.getTextPrimary(context)),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '50.000',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.getBorder(context))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Merchant / Keterangan Singkat
                  Text('Penerima / Merchant / Keperluan', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.getTextSecondary(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: merchantController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.getTextPrimary(context)),
                    decoration: InputDecoration(
                      hintText: txType == 'INCOME' ? 'Contoh: Gaji Bulanan, Transfer Masuk, Bonus' : 'Contoh: Warung Makan, Indomaret, Bensin SPBU',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.getBorder(context))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Anggota Keluarga & Dompet
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Anggota Keluarga', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.getTextSecondary(context))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedMember,
                              items: members.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (v) => setModalState(() => selectedMember = v ?? 'Kevin (Saya)'),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.getBorder(context))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Metode / Dompet', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.getTextSecondary(context))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedApp,
                              items: apps.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (v) => setModalState(() => selectedApp = v ?? 'Tunai (Cash)'),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.getBorder(context))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Kategori
                  Text('Kategori Pengeluaran / Pemasukan', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.getTextSecondary(context))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setModalState(() => selectedCategory = v ?? 'Makanan & Minuman'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.getBorder(context))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Catatan Opsional
                  Text('Catatan Tambahan (Opsional)', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.getTextSecondary(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.getTextPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'Misal: Beli galon & belanja bulanan',
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.getBorder(context))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final rawAmt = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                        final amt = double.tryParse(rawAmt) ?? 0.0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal harus lebih dari Rp 0.')));
                          return;
                        }
                        final merchant = merchantController.text.trim().isNotEmpty
                            ? merchantController.text.trim()
                            : (txType == 'INCOME' ? 'Pemasukan Kas' : 'Pengeluaran Kas');

                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);

                        final cleanMember = selectedMember.replaceAll(' (Saya)', '');
                        await ApiSyncService().addManualTransaction(
                          amount: amt,
                          merchant: merchant,
                          type: txType,
                          appName: selectedApp,
                          category: selectedCategory,
                          member: cleanMember,
                          notes: notesController.text.trim(),
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primaryEmerald,
                              content: Text(
                                'Mutasi manual berhasil dicatat: ${txType == "INCOME" ? "+ " : "- "}Rp ${amt.toInt()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: txType == 'INCOME' ? AppTheme.primaryEmerald : const Color(0xFFF43F5E),
                        foregroundColor: txType == 'INCOME' ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Simpan Mutasi (${txType == "INCOME" ? "Masuk" : "Keluar"})',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
                      (tx.isIncome ? '+ ' : '- ') + currencyFormat.format(tx.amount),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: tx.isIncome ? AppTheme.primaryEmerald : const Color(0xFFF43F5E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (tx.isIncome ? AppTheme.primaryEmerald : const Color(0xFFF43F5E)).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tx.isIncome ? '↓ Uang Masuk' : '↑ Uang Keluar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: tx.isIncome ? AppTheme.primaryEmerald : const Color(0xFFF43F5E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRose, size: 18),
                      label: Text(
                        'Hapus Transaksi',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.dangerRose,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.dangerRose.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            backgroundColor: AppTheme.getCard(context),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text(
                              'Hapus Transaksi Ini?',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.getTextPrimary(context),
                              ),
                            ),
                            content: Text(
                              'Transaksi ${tx.merchant} sebesar ${currencyFormat.format(tx.amount)} akan dihapus dari histori.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.getTextSecondary(context),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: Text('Batal', style: TextStyle(color: AppTheme.getTextSecondary(context))),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.dangerRose,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          Navigator.pop(ctx);
                          await ApiSyncService().deleteTransaction(tx.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppTheme.primaryEmerald,
                                content: Text('Transaksi berhasil dihapus.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryEmerald),
            tooltip: 'Catat Mutasi Manual',
            onPressed: () => _showManualEntryModal(),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryEmerald),
            tooltip: LanguageService().tr('scan_title'),
            onPressed: widget.onNavigateToScan,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.black,
        elevation: 3,
        icon: const Icon(Icons.edit_note_rounded, size: 20),
        label: Text(
          'Catat Mutasi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        onPressed: () => _showManualEntryModal(),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([ApiSyncService(), LanguageService()]),
        builder: (context, _) {
          final sync = ApiSyncService();
          final history = sync.history;
          final familyMembers = sync.familyMembers;

          final filtered = history.where((tx) {
            // Member Filter
            if (_selectedMember != 'Semua Anggota') {
              final cleanFilter = _selectedMember.replaceAll(' (Saya)', '').toLowerCase();
              if (tx.member.toLowerCase() != cleanFilter) {
                return false;
              }
            }

            // Category / Channel Filter
            if (_selectedFilter == 'Uang Masuk') {
              if (!tx.isIncome) return false;
            } else if (_selectedFilter == 'Uang Keluar') {
              if (tx.isIncome) return false;
            } else if (_selectedFilter == 'QRIS') {
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
                  tx.content.toLowerCase().contains(query) ||
                  tx.member.toLowerCase().contains(query);
            }

            return true;
          }).toList();

          final totalIncome = filtered.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
          final totalExpense = filtered.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
          final netBalance = totalIncome - totalExpense;

          return Column(
            children: [
              // Total Saldo Kas (Net Balance) Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.getBorder(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 14,
                                color: netBalance >= 0 ? AppTheme.primaryEmerald : const Color(0xFFF43F5E),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedMember == 'Semua Anggota'
                                    ? 'Total Saldo Kas Bersih'
                                    : 'Saldo Kas ($_selectedMember)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.getTextSecondary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (netBalance >= 0 ? '+ ' : '- ') + currencyFormat.format(netBalance.abs()),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: netBalance >= 0 ? AppTheme.primaryEmerald : const Color(0xFFF43F5E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '↓ Masuk: +${currencyFormat.format(totalIncome)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '↑ Keluar: -${currencyFormat.format(totalExpense)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF43F5E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search & Filter Box
              Container(
                color: AppTheme.getCard(context),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      style: TextStyle(color: AppTheme.getTextPrimary(context), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari nama merchant, anggota, atau transaksi...',
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
                    const SizedBox(height: 10),

                    // Family Member Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              avatar: const Icon(Icons.people_alt_rounded, size: 14),
                              label: const Text('Semua Keluarga'),
                              selected: _selectedMember == 'Semua Anggota',
                              selectedColor: AppTheme.primaryEmerald.withOpacity(0.2),
                              backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF1F5F9),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: _selectedMember == 'Semua Anggota' ? FontWeight.w800 : FontWeight.w600,
                                color: _selectedMember == 'Semua Anggota' ? AppTheme.primaryEmerald : AppTheme.getTextSecondary(context),
                              ),
                              side: BorderSide(color: _selectedMember == 'Semua Anggota' ? AppTheme.primaryEmerald : AppTheme.getBorder(context)),
                              onSelected: (_) => setState(() => _selectedMember = 'Semua Anggota'),
                            ),
                          ),
                          ...familyMembers.map((m) {
                            final isSel = _selectedMember == m;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                avatar: const Icon(Icons.person_outline_rounded, size: 14),
                                label: Text(m),
                                selected: isSel,
                                selectedColor: AppTheme.primaryEmerald.withOpacity(0.2),
                                backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF1F5F9),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  color: isSel ? AppTheme.primaryEmerald : AppTheme.getTextSecondary(context),
                                ),
                                side: BorderSide(color: isSel ? AppTheme.primaryEmerald : AppTheme.getBorder(context)),
                                onSelected: (_) => setState(() => _selectedMember = m),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Type / Channel Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((f) {
                          final isSelected = _selectedFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                tx.merchant,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.getTextPrimary(context),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: tx.isIncome
                                                    ? AppTheme.primaryEmerald.withOpacity(0.12)
                                                    : const Color(0xFFF43F5E).withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                tx.isIncome ? '↓ Masuk' : '↑ Keluar',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: tx.isIncome ? AppTheme.primaryEmerald : const Color(0xFFF43F5E),
                                                ),
                                              ),
                                            ),
                                          ],
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
                                    (tx.isIncome ? '+ ' : '- ') + currencyFormat.format(tx.amount),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: tx.isIncome ? AppTheme.primaryEmerald : const Color(0xFFF43F5E),
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
