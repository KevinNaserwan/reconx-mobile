class SyncedTransaction {
  final String id;
  final String appName;
  final String packageName;
  final String title;
  final String content;
  final double amount;
  final String merchant;
  final String channel;
  final DateTime timestamp;
  final String status;

  SyncedTransaction({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.title,
    required this.content,
    required this.amount,
    required this.merchant,
    required this.channel,
    required this.timestamp,
    required this.status,
  });

  factory SyncedTransaction.fromJson(Map<String, dynamic> json) {
    return SyncedTransaction(
      id: json['transactionRef'] ?? json['id'] ?? 'TRX-UNKNOWN',
      appName: json['providerName'] ?? json['app'] ?? 'Bank / Wallet',
      packageName: json['packageName'] ?? '',
      title: json['title'] ?? 'Pembayaran Berhasil',
      content: json['content'] ?? '',
      amount: (json['parsedAmount'] ?? json['amount'] ?? 0).toDouble(),
      merchant: json['merchant'] ?? 'Merchant Partner',
      channel: json['channel'] ?? 'MOBILE_AUTO_SYNC',
      timestamp: json['syncedAt'] != null
          ? DateTime.tryParse(json['syncedAt']) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] ?? 'SYNCED_TO_LEDGER',
    );
  }
}
