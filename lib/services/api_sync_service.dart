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

  StreamSubscription? _eventSubscription;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _backendUrl = prefs.getString('reconx_backend_url') ?? 'https://reconx.ramuni.id/api/v1';
    _isServiceActive = prefs.getBool('reconx_service_active') ?? true;

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
    notifyListeners();
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
            syncNotification(
              appPackage: map['packageName'] ?? '',
              title: map['title'] ?? '',
              content: map['content'] ?? '',
              postTime: map['postTime'],
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

  Future<bool> testConnection() async {
    try {
      final stopwatch = Stopwatch()..start();
      final uri = Uri.parse('$_backendUrl/mobile/status');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      stopwatch.stop();

      if (res.statusCode == 200) {
        _latencyMs = stopwatch.elapsedMilliseconds;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
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
  }) async {
    final user = AuthService().currentUser;

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
    notifyListeners();
    return fallbackItem;
  }

  String _resolveAppName(String pkg) {
    final p = pkg.toLowerCase();
    if (p.contains('bcadigital') || p.contains('blu')) return 'blu by BCA Digital';
    if (p.contains('searpm') || p.contains('seabank')) return 'SeaBank Indonesia';
    if (p.contains('superbank')) return 'Superbank Indonesia';
    if (p.contains('shopee')) return 'ShopeePay';
    if (p.contains('tokopedia')) return 'Tokopedia';
    if (p.contains('ovo')) return 'OVO';
    if (p.contains('bibit')) return 'Bibit (Investasi)';
    if (p.contains('pluang')) return 'Pluang (Investasi)';
    return 'Bank / Dompet Digital';
  }

  double _extractAmountClientSide(String text) {
    final reg = RegExp(r'(?:Rp|IDR)\s*([0-9\.\,]+)', caseSensitive: false);
    final match = reg.firstMatch(text);
    if (match != null) {
      final clean = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(clean) ?? 50000.0;
    }
    return 50000.0;
  }

  String _extractMerchantClientSide(String text) {
    final reg = RegExp(r'(?:ke|di|merchant)\s+([A-Za-z0-9\s]{3,20})', caseSensitive: false);
    final match = reg.firstMatch(text);
    if (match != null) return match.group(1)!.trim();
    return 'Merchant Partner';
  }
}
