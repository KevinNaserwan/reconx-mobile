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
  final String type; // 'EXPENSE' or 'INCOME'

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
    this.type = 'EXPENSE',
  });

  DateTime get timestampWib => timestamp.toUtc().add(const Duration(hours: 7));
  bool get isIncome => type.toUpperCase() == 'INCOME' || type.toUpperCase() == 'CREDIT';

  Map<String, dynamic> toJson() => {
        'id': id,
        'appName': appName,
        'packageName': packageName,
        'title': title,
        'content': content,
        'amount': amount,
        'merchant': merchant,
        'channel': channel,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
        'type': type,
      };

  factory SyncedTransaction.fromJson(Map<String, dynamic> json) {
    final rawNotif = json['rawNotification'] is Map ? json['rawNotification'] as Map : null;
    
    // Resolve transaction type (INCOME vs EXPENSE)
    String resolvedType = (json['type'] ?? json['transactionType'] ?? '').toString().toUpperCase();
    if (resolvedType != 'INCOME' && resolvedType != 'EXPENSE') {
      final combined = '${json['title'] ?? ''} ${json['content'] ?? ''} ${rawNotif?['title'] ?? ''} ${rawNotif?['content'] ?? ''}'.toLowerCase();
      final isInc = combined.contains('masuk') ||
          combined.contains('menerima') ||
          combined.contains('terima uang') ||
          combined.contains('top up') ||
          combined.contains('kredit') ||
          combined.contains('cashback') ||
          combined.contains('refund') ||
          combined.contains('setoran');
      resolvedType = isInc ? 'INCOME' : 'EXPENSE';
    }

    return SyncedTransaction(
      id: json['id'] ?? json['transactionRef'] ?? json['transactionId'] ?? 'TRX-UNKNOWN',
      appName: json['appName'] ?? json['providerName'] ?? json['app'] ?? (rawNotif?['app']) ?? 'Bank / Wallet',
      packageName: json['packageName'] ?? '',
      title: json['title'] ?? (rawNotif?['title']) ?? 'Pembayaran Berhasil',
      content: json['content'] ?? (rawNotif?['content']) ?? '',
      amount: (json['amount'] ?? json['parsedAmount'] ?? 0).toDouble(),
      merchant: json['merchant'] ?? 'Merchant Partner',
      channel: json['channel'] ?? 'MOBILE_AUTO_SYNC',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : (json['syncedAt'] != null
              ? DateTime.tryParse(json['syncedAt']) ?? DateTime.now()
              : DateTime.now()),
      status: json['status'] ?? 'SYNCED_TO_LEDGER',
      type: resolvedType,
    );
  }
}
