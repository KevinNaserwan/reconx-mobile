import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _prefKey = 'reconx_language_code';

  String _currentLanguage = 'id'; // 'id', 'en', 'zh'
  String get currentLanguage => _currentLanguage;

  static const Map<String, Map<String, String>> _translations = {
    'id': {
      'nav_home': 'Beranda',
      'nav_mutasi': 'Mutasi',
      'nav_scan': 'Pindai',
      'nav_family': 'Keluarga',
      'nav_account': 'Akun',
      'app_title': 'Reconx',
      'status_active': 'Background Sync: AKTIF',
      'status_paused': 'Background Sync: JEDA',
      'status_desc': 'Memonitor mutasi bank, e-wallet, & nota fisik',
      'total_tracked': 'Total Terdata',
      'transactions': 'Transaksi',
      'latency': 'Latency',
      'monitored_apps': 'APLIKASI & BANK TERPANTAU',
      'recent_mutasi': 'MUTASI TERBARU',
      'view_all': 'Lihat Semua',
      'no_mutasi_today': 'Belum Ada Mutasi Hari Ini',
      'no_mutasi_desc': 'Notifikasi dari bank atau scan struk fisik akan otomatis masuk dan terekonsiliasi.',
      'scan_title': 'Pindai QRIS & Nota Fisik',
      'scan_hint': 'Arahkan kamera ke struk kasir atau QRIS',
      'gallery': 'Galeri',
      'auto_ocr': 'Auto OCR',
      'family_title': 'Household Financial Cluster',
      'family_desc': 'Multi-Tenant Household Financial Engine',
      'invite_pin': 'PIN Undangan Anggota Keluarga',
      'copy_pin': 'Salin PIN',
      'pin_copied': 'PIN berhasil disalin ke clipboard!',
      'anti_double': 'Proteksi Anti-Double Counting',
      'anti_double_desc': 'Transfer internal suami-istri otomatis terdeteksi & tidak dihitung dobel.',
      'members_title': 'Anggota & Dompet Mandiri',
      'invite_member': 'Undang Pasangan / Anggota Keluarga',
      'settings_title': 'Pengaturan & Profil',
      'edit_profile': 'Edit & Lengkapi Data Profil',
      'theme_title': 'TEMA TAMPILAN',
      'theme_dark': 'Gelap (Dark)',
      'theme_light': 'Terang (White)',
      'theme_system': 'Sistem',
      'lang_title': 'BAHASA APLIKASI / LANGUAGE',
      'notify_sources': 'SUMBER NOTIFIKASI AKTIF',
      'notify_sources_desc': 'Pilih bank & e-wallet yang diizinkan untuk disinkronkan:',
      'security_title': 'KEAMANAN & PRIVASI TINGKAT ENTERPRISE',
      'fingerprint': 'Kunci Sidik Jari / Biometrik',
      'fingerprint_desc': 'Minta verifikasi biometrik setiap kali aplikasi dibuka.',
      'privacy_mask': 'Sembunyikan Saldo (Privacy Mode)',
      'privacy_mask_desc': 'Sensor nominal saldo pada layar publik.',
      'interceptor_title': 'STATUS NOTIFICATION INTERCEPTOR',
      'interceptor_active': 'Akses Notifikasi Aktif',
      'interceptor_inactive': 'Izin Notifikasi Belum Aktif',
      'reset_data': 'Reset Seluruh Data Mutasi Lokal',
      'logout': 'Keluar dari Akun (Logout)',
      'save_changes': 'Simpan Perubahan',
      'export_csv': 'Export Rekap CSV',
    },
    'en': {
      'nav_home': 'Home',
      'nav_mutasi': 'Ledger',
      'nav_scan': 'Scan',
      'nav_family': 'Family',
      'nav_account': 'Account',
      'app_title': 'Reconx',
      'status_active': 'Background Sync: ACTIVE',
      'status_paused': 'Background Sync: PAUSED',
      'status_desc': 'Monitoring bank, e-wallet, & receipt notifications',
      'total_tracked': 'Total Tracked',
      'transactions': 'Transactions',
      'latency': 'Latency',
      'monitored_apps': 'MONITORED BANKS & WALLETS',
      'recent_mutasi': 'RECENT TRANSACTIONS',
      'view_all': 'View All',
      'no_mutasi_today': 'No Transactions Recorded Today',
      'no_mutasi_desc': 'Bank push alerts or scanned physical receipts will automatically reconcile here.',
      'scan_title': 'Scan QRIS & Receipts',
      'scan_hint': 'Point camera at receipt paper or QRIS code',
      'gallery': 'Gallery',
      'auto_ocr': 'Auto OCR',
      'family_title': 'Household Financial Cluster',
      'family_desc': 'Multi-Tenant Household Financial Engine',
      'invite_pin': 'Family Invitation PIN Code',
      'copy_pin': 'Copy PIN',
      'pin_copied': 'PIN copied to clipboard successfully!',
      'anti_double': 'Anti-Double Counting Protection',
      'anti_double_desc': 'Internal transfers between spouse accounts are excluded from double counting.',
      'members_title': 'Members & Independent Wallets',
      'invite_member': 'Invite Spouse / Family Member',
      'settings_title': 'Settings & Profile',
      'edit_profile': 'Edit Personal & Family Profile',
      'theme_title': 'DISPLAY THEME',
      'theme_dark': 'Dark Mode',
      'theme_light': 'White Mode',
      'theme_system': 'System',
      'lang_title': 'APP LANGUAGE / 语言',
      'notify_sources': 'ACTIVE NOTIFICATION SOURCES',
      'notify_sources_desc': 'Select which banks and e-wallets Reconx is allowed to sync:',
      'security_title': 'ENTERPRISE-GRADE SECURITY & PRIVACY',
      'fingerprint': 'Biometric / Fingerprint Lock',
      'fingerprint_desc': 'Require biometric authentication on app resume.',
      'privacy_mask': 'Mask Balances (Privacy Mode)',
      'privacy_mask_desc': 'Hide confidential amounts in public environments.',
      'interceptor_title': 'NOTIFICATION INTERCEPTOR STATUS',
      'interceptor_active': 'Notification Access Active',
      'interceptor_inactive': 'Notification Access Inactive',
      'reset_data': 'Reset All Local Transaction Data',
      'logout': 'Sign Out (Logout)',
      'save_changes': 'Save Changes',
      'export_csv': 'Export CSV Summary',
    },
    'zh': {
      'nav_home': '首页',
      'nav_mutasi': '明细流水',
      'nav_scan': '扫一扫',
      'nav_family': '家庭协同',
      'nav_account': '我的账户',
      'app_title': 'Reconx',
      'status_active': '后台实时同步: 运行中',
      'status_paused': '后台同步: 已暂停',
      'status_desc': '实时监听银行、电子钱包及实体收据凭据',
      'total_tracked': '已同步总额',
      'transactions': '交易笔数',
      'latency': '网络延迟',
      'monitored_apps': '已监控银行与支付平台',
      'recent_mutasi': '最新交易动态',
      'view_all': '查看全部',
      'no_mutasi_today': '今日尚无交易记录',
      'no_mutasi_desc': '银行通知推送或小票拍摄后，系统将自动汇总至家庭总账。',
      'scan_title': '扫描 QRIS 码与小票收据',
      'scan_hint': '请将相机对准消费凭条或收款码',
      'gallery': '相册',
      'auto_ocr': '智能识别',
      'family_title': '家庭财务协同引擎',
      'family_desc': '多租户家庭私域财务清算平台',
      'invite_pin': '配偶与家庭邀请密钥 PIN',
      'copy_pin': '复制 PIN 码',
      'pin_copied': '邀请码已复制到剪贴板！',
      'anti_double': '防重复记账风控保护',
      'anti_double_desc': '夫妻互转自动抵消，杜绝家庭支出重复统计。',
      'members_title': '家庭成员与独立钱包',
      'invite_member': '邀请配偶/家庭成员接入',
      'settings_title': '设置与个人资料',
      'edit_profile': '完善个人及家庭资料',
      'theme_title': '界面外观主题',
      'theme_dark': '深色模式 (Dark)',
      'theme_light': '浅色高亮 (White)',
      'theme_system': '跟随系统',
      'lang_title': '语言设置 / LANGUAGE',
      'notify_sources': '授权同步渠道',
      'notify_sources_desc': '管理允许 Reconx 自动捕获的银行与钱包列表：',
      'security_title': '企业级安全与隐私保护',
      'fingerprint': '指纹与生物识别锁',
      'fingerprint_desc': '每次切入应用时必须通过安全验证。',
      'privacy_mask': '金额隐私掩码模式',
      'privacy_mask_desc': '在公共场合隐藏敏感账户余额。',
      'interceptor_title': '通知拦截器运行状态',
      'interceptor_active': '系统通知权限已就绪',
      'interceptor_inactive': '尚未获取通知监听权限',
      'reset_data': '重置本地所有明细数据',
      'logout': '退出当前登录',
      'save_changes': '保存变更',
      'export_csv': '导出 CSV 明细表',
    },
  };

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(_prefKey) ?? 'id';
      notifyListeners();
    } catch (e) {
      debugPrint('LanguageService init fallback: $e');
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (langCode != 'id' && langCode != 'en' && langCode != 'zh') return;
    _currentLanguage = langCode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
    } catch (e) {
      debugPrint('LanguageService save error: $e');
    }
  }

  String tr(String key) {
    final dict = _translations[_currentLanguage] ?? _translations['id']!;
    return dict[key] ?? _translations['id']?[key] ?? key;
  }
}
