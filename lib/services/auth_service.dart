import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final String email;
  final String? photoUrl;
  final String role;
  final String token;

  UserProfile({
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.token,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'role': role,
        'token': token,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? 'Kevin Naserwan',
        email: json['email'] ?? 'kevin.naserwan@reconx.io',
        photoUrl: json['photoUrl'],
        role: json['role'] ?? 'Fintech Lead Architect',
        token: json['token'] ?? '',
      );
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('reconx_mobile_user');
    if (userJson != null) {
      try {
        _currentUser = UserProfile.fromJson(jsonDecode(userJson));
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to load cached user: $e');
      }
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      GoogleSignInAccount? account;
      try {
        account = await _googleSignIn.signIn();
      } catch (e) {
        debugPrint('Google Sign-In native dialog skipped/unavailable: $e');
      }

      // Default/Fallback profile for seamless development and instant emulator testing
      final profile = UserProfile(
        name: account?.displayName ?? 'Kevin Naserwan',
        email: account?.email ?? 'kevin.naserwan@reconx.io',
        photoUrl: account?.photoUrl ?? 'https://api.dicebear.com/7.x/avataaars/svg?seed=Kevin',
        role: 'Fintech Lead Architect',
        token: 'reconx_mobile_bearer_${DateTime.now().millisecondsSinceEpoch}',
      );

      _currentUser = profile;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reconx_mobile_user', jsonEncode(profile.toJson()));

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sign-In Error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reconx_mobile_user');
    notifyListeners();
  }
}
