import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_item.dart';
import 'auth_service.dart';

class ApiSyncService extends ChangeNotifier {
  static final ApiSyncService _instance = ApiSyncService._internal();
  factory ApiSyncService() => _instance;
  ApiSyncService._internal();

  static const MethodChannel _methodChannel = MethodChannel('com.reconx.agent/methods');
  static const EventChannel _eventChannel = EventChannel('com.reconx.agent/events');

  String _backendUrl = 'https://reconx.ramuni.id/api/v1'; // Live production endpoint
  String get backendUrl => _backendUrl;

  bool _isServiceActive = true;
  bool get isServiceActive => _isServiceActive;

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  // Fully reset to 0 for fresh SaaS accounts
  int _syncedCountToday = 0;
  int get syncedCountToday => _syncedCountToday;

  double _syncedVolumeToday = 0.0;
  double get syncedVolumeToday => _syncedVolumeToday;

  int _latencyMs = 28;
  int get latencyMs => _latencyMs;

  final List<SyncedTransaction> _history = [];
  List<SyncedTransaction> get history => List.unmodifiable(_history);

  final Set<String> _processedNotificationKeys = {};
  Set<String> get processedNotificationKeys => Set.unmodifiable(_processedNotificationKeys);

  // Bank & E-Wallet Interception Filter Settings
  Map<String, bool> _appFilters = {
    'bca': true,
    'mandiri': true,
    'bri': true,
    'bni': true,
    'seabank': true,
    'gopay': true,
    'ovo': true,
    'dana': true,
    'shopee': true,
    'superbank': true,
  };
  Map<String, bool> get appFilters => Map.unmodifiable(_appFilters);

  final _newTransactionController = StreamController<SyncedTransaction>.broadcast();
  Stream<SyncedTransaction> get onNewTransactionStream => _newTransactionController.stream;

  StreamSubscription? _eventSubscription;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _backendUrl = prefs.getString('reconx_backend_url') ?? 'https://reconx.ramuni.id/api/v1';
    _isServiceActive = prefs.getBool('reconx_service_active') ?? true;

    // Load persisted app filters
    final filtersJson = prefs.getString('reconx_app_filters');
    if (filtersJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(filtersJson);
        for (final k in decoded.keys) {
          if (_appFilters.containsKey(k)) {
            _appFilters[k] = decoded[k] == true;
          }
        }
      } catch (e) {
        debugPrint('Failed to load saved app filters: $e');
      }
    }

    // Load deduplication keys
    final keysJson = prefs.getString('reconx_processed_keys');
    if (keysJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(keysJson);
        _processedNotificationKeys.addAll(decoded.map((e) => e.toString()));
      } catch (e) {
        debugPrint('Failed to load processed keys: $e');
      }
    }

    // Load persisted real transaction history
    _history.clear();
    final savedHistoryJson = prefs.getString('reconx_saved_history');
    if (savedHistoryJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedHistoryJson);
        for (final item in decoded) {
          _history.add(SyncedTransaction.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (e) {
        debugPrint('Failed to load saved history: $e');
      }
    }

    _syncedCountToday = _history.length;
    _syncedVolumeToday = _history.fold(0.0, (sum, item) => sum + item.amount);

    await checkPermission();
    _startNativeListener();
    await syncActiveNotifications();
    notifyListeners();
  }

  Future<void> _saveProcessedKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _processedNotificationKeys.toList();
      final toSave = list.length > 500 ? list.sublist(list.length - 500) : list;
      await prefs.setString('reconx_processed_keys', jsonEncode(toSave));
    } catch (_) {}
  }

  Future<void> toggleAppFilter(String key, bool enabled) async {
    _appFilters[key] = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reconx_app_filters', jsonEncode(_appFilters));
    } catch (e) {
      debugPrint('Failed to persist app filters: $e');
    }
  }

  bool isNotificationAllowed(String appPackage, String title, String content) {
    if (!_isServiceActive) return false;

    final combined = '${appPackage.toLowerCase()} ${title.toLowerCase()} ${content.toLowerCase()}';

    if (combined.contains('bca') || combined.contains('blu')) {
      return _appFilters['bca'] ?? true;
    }
    if (combined.contains('mandiri') || combined.contains('livin')) {
      return _appFilters['mandiri'] ?? true;
    }
    if (combined.contains('bri') || combined.contains('brimo')) {
      return _appFilters['bri'] ?? true;
    }
    if (combined.contains('bni')) {
      return _appFilters['bni'] ?? true;
    }
    if (combined.contains('seabank') || combined.contains('searpm')) {
      return _appFilters['seabank'] ?? true;
    }
    if (combined.contains('gopay') || combined.contains('gojek')) {
      return _appFilters['gopay'] ?? true;
    }
    if (combined.contains('ovo')) {
      return _appFilters['ovo'] ?? true;
    }
    if (combined.contains('dana')) {
      return _appFilters['dana'] ?? true;
    }
    if (combined.contains('shopee') || combined.contains('spay')) {
      return _appFilters['shopee'] ?? true;
    }
    if (combined.contains('superbank')) {
      return _appFilters['superbank'] ?? true;
    }

    return true; // Default allow for other detected financial notifications
  }

  Future<void> _saveHistoryToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = _history.map((tx) => tx.toJson()).toList();
      await prefs.setString('reconx_saved_history', jsonEncode(listMap));
    } catch (e) {
      debugPrint('Failed to persist history: $e');
    }
  }

  /// Reset all data completely (Clean Fresh State)
  Future<void> resetAllData() async {
    _history.clear();
    _syncedCountToday = 0;
    _syncedVolumeToday = 0.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reconx_saved_history');
    notifyListeners();
  }

  void _startNativeListener() {
    try {
      _eventSubscription?.cancel();
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (!_isServiceActive) return;
          if (event is Map) {
            final map = Map<String, dynamic>.from(event);
            final pkg = map['packageName'] ?? '';
            final ttl = map['title'] ?? '';
            final cnt = map['content'] ?? '';
            final key = map['notificationKey'] ?? '';

            // Check if this app/bank notification is allowed by user's filter
            if (!isNotificationAllowed(pkg, ttl, cnt)) {
              debugPrint('Notification filtered out by user preference: $pkg');
              return;
            }

            syncNotification(
              appPackage: pkg,
              title: ttl,
              content: cnt,
              postTime: map['postTime'],
              notificationKey: key.isNotEmpty ? key : null,
            );
          }
        },
        onError: (error) {
          debugPrint('Notification EventChannel Error: $error');
        },
      );
    } catch (e) {
      debugPrint('EventChannel initialization skipped: $e');
    }
  }

  Future<void> checkPermission() async {
    try {
      final bool granted = await _methodChannel.invokeMethod('isPermissionGranted');
      _hasPermission = granted;
      notifyListeners();
    } catch (_) {
      _hasPermission = true; // Fallback in non-Android environments
    }
  }

  Future<void> openPermissionSettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  /// Scans all active notifications currently sitting in the Android notification shade/tray
  Future<int> syncActiveNotifications() async {
    try {
      final res = await _methodChannel.invokeMethod('syncActiveNotifications');
      debugPrint('[ApiSyncService] syncActiveNotifications returned: $res');
      return (res is int) ? res : 0;
    } catch (e) {
      debugPrint('[ApiSyncService] Error scanning active notifications: $e');
      return 0;
    }
  }

  /// Re-binds NotificationListenerService if OS unbinded it
  Future<bool> rebindListenerService() async {
    try {
      final res = await _methodChannel.invokeMethod('rebindListenerService');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setServiceActive(bool active) async {
    _isServiceActive = active;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reconx_service_active', active);
    notifyListeners();
  }

  Future<void> setBackendUrl(String url) async {
    _backendUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reconx_backend_url', url);
    notifyListeners();
  }

  /// Sync scanned receipt / physical payment
  Future<SyncedTransaction> syncReceiptTransaction({
    required String merchant,
    required double amount,
    required String category,
    required String paymentMethod,
    List<String>? detectedItems,
    String? imagePath,
  }) async {
    final user = AuthService().currentUser;
    final id = 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final item = SyncedTransaction(
      id: id,
      appName: 'Scan Nota Fisik ($paymentMethod)',
      packageName: 'com.reconx.receipt.scanner',
      title: 'Nota: $merchant',
      content: 'Pembayaran $category sebesar Rp ${amount.toInt()} di $merchant via $paymentMethod.',
      amount: amount,
      merchant: merchant,
      channel: 'RECEIPT_OCR_SCAN',
      timestamp: DateTime.now(),
      status: 'SYNCED_TO_LEDGER',
    );

    _history.insert(0, item);
    _syncedCountToday += 1;
    _syncedVolumeToday += amount;
    await _saveHistoryToPrefs();
    _newTransactionController.add(item);
    notifyListeners();

    // Async sync to backend
    try {
      final uri = Uri.parse('$_backendUrl/mobile/sync-notification');
      http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user?.token ?? ""}',
        },
        body: jsonEncode({
          'appPackage': 'com.reconx.receipt.scanner',
          'appName': 'Scan Nota Fisik ($paymentMethod)',
          'title': 'Nota: $merchant',
          'content': item.content,
          'postTime': DateTime.now().millisecondsSinceEpoch,
          'userEmail': user?.email ?? 'user@reconx.io',
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return item;
  }

  Future<SyncedTransaction?> syncNotification({
    required String appPackage,
    required String title,
    required String content,
    String? appName,
    int? postTime,
    String? notificationKey,
  }) async {
    final user = AuthService().currentUser;

    // DEDUPLICATION GUARD 1: Key Check (exact notification instance)
    final uniqueKey = notificationKey ?? '${appPackage}_${postTime ?? 0}_${title}_$content'.hashCode.toString();
    if (_processedNotificationKeys.contains(uniqueKey)) {
      debugPrint('[Deduplication] Notification key $uniqueKey already processed. Skipping duplicate.');
      return null;
    }

    // DEDUPLICATION GUARD 2: Rapid Duplicate Prevention (Same app + same amount within 60s)
    final candidateAmount = _extractAmountClientSide(content);
    final now = DateTime.now();
    final isRecentDuplicate = _history.any((tx) {
      if (tx.packageName.toLowerCase() == appPackage.toLowerCase() &&
          candidateAmount > 0 &&
          (tx.amount - candidateAmount).abs() < 0.01) {
        final diff = now.difference(tx.timestamp).inSeconds.abs();
        if (diff < 60) return true;
      }
      return false;
    });

    if (isRecentDuplicate) {
      debugPrint('[Deduplication] Transaction from $appPackage ($candidateAmount) recently recorded. Skipping duplicate.');
      _processedNotificationKeys.add(uniqueKey);
      _saveProcessedKeys();
      return null;
    }

    _processedNotificationKeys.add(uniqueKey);
    _saveProcessedKeys();

    try {
      final stopwatch = Stopwatch()..start();
      final uri = Uri.parse('$_backendUrl/mobile/sync-notification');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user?.token ?? ""}',
        },
        body: jsonEncode({
          'appPackage': appPackage,
          'appName': appName ?? _resolveAppName(appPackage),
          'title': title,
          'content': content,
          'postTime': postTime ?? DateTime.now().millisecondsSinceEpoch,
          'userEmail': user?.email ?? 'user@reconx.io',
        }),
      ).timeout(const Duration(seconds: 5));
      stopwatch.stop();

      if (res.statusCode == 200) {
        _latencyMs = stopwatch.elapsedMilliseconds;
        final data = jsonDecode(res.body);

        final item = SyncedTransaction.fromJson(data);
        _history.insert(0, item);
        _syncedCountToday += 1;
        _syncedVolumeToday += item.amount;
        await _saveHistoryToPrefs();
        _newTransactionController.add(item);
        notifyListeners();
        return item;
      }
    } catch (e) {
      debugPrint('Sync HTTP Error: $e');
    }

    // Client-side fallback if server is unreachable
    final fallbackAmount = _extractAmountClientSide(content);
    final fallbackItem = SyncedTransaction(
      id: 'MOB-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      appName: appName ?? _resolveAppName(appPackage),
      packageName: appPackage,
      title: title,
      content: content,
      amount: fallbackAmount,
      merchant: _extractMerchantClientSide(content),
      channel: 'OFFLINE_QUEUED',
      timestamp: DateTime.now(),
      status: 'QUEUED_LOCAL',
    );

    _history.insert(0, fallbackItem);
    _syncedCountToday += 1;
    _syncedVolumeToday += fallbackAmount;
    await _saveHistoryToPrefs();
    _newTransactionController.add(fallbackItem);
    notifyListeners();
    return fallbackItem;
  }

  String _resolveAppName(String pkg) {
    final p = pkg.toLowerCase();
    if (p.contains('bcadigital') || p.contains('blu')) return 'blu by BCA Digital';
    if (p.contains('bca')) return 'BCA Mobile';
    if (p.contains('mandiri') || p.contains('livin')) return "Livin' by Mandiri";
    if (p.contains('bri') || p.contains('brimo')) return 'BRImo';
    if (p.contains('bni')) return 'BNI Mobile';
    if (p.contains('searpm') || p.contains('seabank')) return 'SeaBank Indonesia';
    if (p.contains('superbank')) return 'Superbank Indonesia';
    if (p.contains('shopee')) return 'ShopeePay';
    if (p.contains('tokopedia')) return 'Tokopedia';
    if (p.contains('ovo')) return 'OVO';
    if (p.contains('gopay') || p.contains('gojek')) return 'GoPay';
    if (p.contains('dana')) return 'DANA Indonesia';
    if (p.contains('bibit')) return 'Bibit (Investasi)';
    if (p.contains('pluang')) return 'Pluang (Investasi)';
    return 'Bank / Dompet Digital';
  }

  double _extractAmountClientSide(String text) {
    // 1. Try explicit Rp / IDR pattern (e.g. "Rp 25.000", "Rp25.000", "IDR 150.000,00")
    final reg = RegExp(r'(?:Rp|IDR)\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2})?|[0-9]+)', caseSensitive: false);
    final match = reg.firstMatch(text);
    if (match != null) {
      final raw = match.group(1)!;
      final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
      final val = double.tryParse(cleaned);
      if (val != null && val > 0) return val;
    }

    // 2. Generic thousands pattern (e.g. "25.000", "150.000")
    final numReg = RegExp(r'([0-9]{1,3}(?:[.,][0-9]{3})+)', caseSensitive: false);
    final numMatch = numReg.firstMatch(text);
    if (numMatch != null) {
      final cleaned = numMatch.group(1)!.replaceAll(RegExp(r'[^0-9]'), '');
      final val = double.tryParse(cleaned);
      if (val != null && val > 0) return val;
    }

    return 0.0;
  }

  String _extractMerchantClientSide(String text) {
    final reg = RegExp(r'(?:ke|di|merchant|pada|toko)\s+([A-Za-z0-9\s\.\-]{3,30})', caseSensitive: false);
    final match = reg.firstMatch(text);
    if (match != null) {
      final candidate = match.group(1)!.trim();
      final cleaned = candidate.split(RegExp(r'(?:berhasil|sukses|pada|sebesar|rp|idr)', caseSensitive: false)).first.trim();
      if (cleaned.isNotEmpty && cleaned.length >= 2) return cleaned;
    }
    return 'Merchant QRIS';
  }
}
