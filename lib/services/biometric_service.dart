import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService extends ChangeNotifier {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  bool _isHardwareSupported = false;
  bool get isHardwareSupported => _isHardwareSupported;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isBiometricEnabled = prefs.getBool('reconx_biometric_enabled') ?? false;

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      _isHardwareSupported = canCheck || isSupported;
    } catch (e) {
      debugPrint('Biometric hardware check failed: $e');
      _isHardwareSupported = false;
    }
    notifyListeners();
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      // Prompt user to verify fingerprint/biometric before enabling
      final success = await authenticate(
        reason: 'Verifikasi sidik jari untuk mengaktifkan keamanan biometrik ReconX',
      );
      if (!success) return false;
    }

    _isBiometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reconx_biometric_enabled', enabled);
    notifyListeners();
    return true;
  }

  Future<bool> authenticate({
    String reason = 'Gunakan sidik jari atau biometrik untuk membuka ReconX',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return false;
    }
  }
}
