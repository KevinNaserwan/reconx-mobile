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

  String _backendUrl = 'http://10.0.2.2:5000/api/v1'; // 10.0.2.2 points to localhost from Android emulator
  String get backendUrl => _backendUrl;

  bool _isServiceActive = true;
  bool get isServiceActive => _isServiceActive;

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  int _syncedCountToday = 3;
  int get syncedCountToday => _syncedCountToday;

  double _syncedVolumeToday = 1730000.0;
  double get syncedVolumeToday => _syncedVolumeToday;

  int _latencyMs = 38;
  int get latencyMs => _latencyMs;

  final List<SyncedTransaction> _history = [];
  List<SyncedTransaction> get history => List.unmodifiable(_history);

  StreamSubscription? _eventSubscription;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _backendUrl = prefs.getString('reconx_backend_url') ?? 'http://10.0.2.2:5000/api/v1';
    _isServiceActive = prefs.getBool('reconx_service_active') ?? true;

    // Initial mock history for demo presentation
    _history.addAll([
      SyncedTransaction(
        id: 'MOB-20261014-8841',
        appName: 'blu by BCA Digital',
        packageName: 'id.co.bcadigital.blu',
        title: 'Pembayaran QRIS Berhasil',
        content: 'Pembayaran QRIS sebesar Rp 45.000 ke Kopi Kenangan telah berhasil.',
        amount: 45000,
        merchant: 'Kopi Kenangan',
        channel: 'BLU_QRIS_OR_TRANSFER',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: 'SYNCED_TO_LEDGER',
      ),
      SyncedTransaction(
        id: 'MOB-20261014-9912',
        appName: 'ShopeePay',
        packageName: 'com.shopee.id',
        title: 'ShopeePay Berhasil',
        content: 'Pembayaran sebesar Rp 185.000 ke Toko Komputer Sukses telah selesai.',
        amount: 185000,
        merchant: 'Toko Komputer Sukses',
        channel: 'SHOPEEPAY_WALLET',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        status: 'SYNCED_TO_LEDGER',
      ),
      SyncedTransaction(
        id: 'MOB-20261014-7723',
        appName: 'Bibit (Investasi)',
        packageName: 'com.bibit.id',
        title: 'Investasi Berhasil',
        content: 'Pembelian Reksa Dana Pasar Uang senilai Rp 1.500.000 telah berhasil diverifikasi oleh KSEI.',
        amount: 1500000,
        merchant: 'Bibit',
        channel: 'INVESTMENT_SETTLEMENT',
        timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
        status: 'SYNCED_TO_LEDGER',
      ),
    ]);

    await checkPermission();
    _startNativeListener();
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
          'userEmail': user?.email ?? 'kevin.naserwan@reconx.io',
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
