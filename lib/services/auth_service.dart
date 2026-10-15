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
    this.phoneNumber = '',
    this.photoUrl,
    required this.role,
    required this.token,
    this.familyId = '',
    this.familyName = 'Finansial Keluarga',
    this.familyInviteCode = '',
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
        name: json['name'] ?? 'Pengguna',
        email: json['email'] ?? '',
        phoneNumber: json['phoneNumber'] ?? '',
        photoUrl: json['photoUrl'],
        role: json['role'] ?? 'Kepala Keluarga',
        token: json['token'] ?? '',
        familyId: json['familyId'] ?? '',
        familyName: json['familyName'] ?? 'Finansial Keluarga',
        familyInviteCode: json['familyInviteCode'] ?? '',
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

      final name = account?.displayName ?? (account?.email?.split('@')[0] ?? 'Pengguna');
      final email = account?.email ?? '';
      final photoUrl = account?.photoUrl;

      final ts = DateTime.now().millisecondsSinceEpoch;
      final profile = UserProfile(
        name: name,
        email: email,
        phoneNumber: '',
        photoUrl: photoUrl,
        role: 'Kepala Keluarga',
        token: 'reconx_mobile_bearer_$ts',
        familyId: 'fam-$ts',
        familyName: 'Finansial Keluarga',
        familyInviteCode: 'FAM-${ts.toString().substring(7)}',
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
      final ts = DateTime.now().millisecondsSinceEpoch;
      final finalFamilyName = familyName?.isNotEmpty == true ? familyName! : 'Finansial Keluarga';
      final finalInviteCode = inviteCode?.isNotEmpty == true
          ? inviteCode!.toUpperCase()
          : 'FAM-${ts.toString().substring(7)}';
      final finalRole = role?.isNotEmpty == true ? role! : 'Kepala Keluarga';

      final profile = UserProfile(
        name: name,
        email: email,
        phoneNumber: phoneNumber ?? '',
        photoUrl: photoUrl,
        role: finalRole,
        token: 'reconx_mobile_bearer_$ts',
        familyId: 'fam-$ts',
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
