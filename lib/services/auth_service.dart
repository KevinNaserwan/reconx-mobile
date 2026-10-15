import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final String email;
  final String phoneNumber;
  final String? photoUrl;
  final String role;
  final String token;
  final String familyId;
  final String familyName;
  final String familyInviteCode;

  UserProfile({
    required this.name,
    required this.email,
    this.phoneNumber = '081234567890',
    this.photoUrl,
    required this.role,
    required this.token,
    this.familyId = 'fam-kevin-001',
    this.familyName = 'Kevin & Anan (Couple)',
    this.familyInviteCode = 'COUPLE-KVN-ANN',
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? role,
    String? token,
    String? familyId,
    String? familyName,
    String? familyInviteCode,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      token: token ?? this.token,
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      familyInviteCode: familyInviteCode ?? this.familyInviteCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'photoUrl': photoUrl,
        'role': role,
        'token': token,
        'familyId': familyId,
        'familyName': familyName,
        'familyInviteCode': familyInviteCode,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? 'Kevin Naserwan',
        email: json['email'] ?? 'kevin.naserwan@gmail.com',
        phoneNumber: json['phoneNumber'] ?? '081234567890',
        photoUrl: json['photoUrl'],
        role: json['role'] ?? 'Kevin (Partner)',
        token: json['token'] ?? '',
        familyId: json['familyId'] ?? 'fam-kevin-001',
        familyName: json['familyName'] ?? 'Kevin & Anan (Couple)',
        familyInviteCode: json['familyInviteCode'] ?? 'COUPLE-KVN-ANN',
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

      final name = account?.displayName ?? 'Kevin Naserwan';
      final email = account?.email ?? 'kevin.naserwan@gmail.com';
      final photoUrl = account?.photoUrl ?? 'https://api.dicebear.com/7.x/avataaars/svg?seed=Kevin';

      final profile = UserProfile(
        name: name,
        email: email,
        phoneNumber: '081234567890',
        photoUrl: photoUrl,
        role: 'Kevin (Partner)',
        token: 'reconx_mobile_bearer_${DateTime.now().millisecondsSinceEpoch}',
        familyId: 'fam-kevin-001',
        familyName: 'Kevin & Anan (Couple)',
        familyInviteCode: 'COUPLE-KVN-ANN',
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

  Future<bool> registerOrLogin({
    required String name,
    required String email,
    String? phoneNumber,
    String? familyName,
    String? inviteCode,
    String? role,
    String? photoUrl,
  }) async {
    try {
      final finalFamilyName = familyName?.isNotEmpty == true ? familyName! : 'Kevin & Anan (Couple)';
      final finalInviteCode = inviteCode?.isNotEmpty == true
          ? inviteCode!.toUpperCase()
          : 'COUPLE-KVN-ANN';
      final finalRole = role?.isNotEmpty == true ? role! : 'Kevin (Partner)';

      final profile = UserProfile(
        name: name,
        email: email,
        phoneNumber: phoneNumber?.isNotEmpty == true ? phoneNumber! : '081234567890',
        photoUrl: photoUrl ?? 'https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(name)}',
        role: finalRole,
        token: 'reconx_mobile_bearer_${DateTime.now().millisecondsSinceEpoch}',
        familyId: 'fam-${DateTime.now().millisecondsSinceEpoch}',
        familyName: finalFamilyName,
        familyInviteCode: finalInviteCode,
      );

      _currentUser = profile;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reconx_mobile_user', jsonEncode(profile.toJson()));

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Custom Auth Error: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phoneNumber,
    required String role,
    required String familyName,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return false;

    try {
      final updated = _currentUser!.copyWith(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
        familyName: familyName,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
      );

      _currentUser = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reconx_mobile_user', jsonEncode(updated.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update Profile Error: $e');
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
