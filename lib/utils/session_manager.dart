import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth_screen.dart';

class SessionManager {
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyUserType = 'user_type';
  static const String _keyExpiresAt = 'expires_at';
  static const String _keyProfilePic = 'profile_pic';

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  Future<void> saveSession({
    required String userId,
    required String username,
    required String userType,
    String? expiresAt,
    String? profilePic,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyUserType, userType);
    if (expiresAt != null) {
      await prefs.setString(_keyExpiresAt, expiresAt);
    } else {
      await prefs.remove(_keyExpiresAt);
    }
    if (profilePic != null) {
      await prefs.setString(_keyProfilePic, profilePic);
    } else {
      await prefs.remove(_keyProfilePic);
    }
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserType);
  }

  Future<String?> getExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyExpiresAt);
  }

  Future<String?> getProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfilePic);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyUserType);
    await prefs.remove(_keyExpiresAt);
    await prefs.remove(_keyProfilePic);
  }

  bool _isRedirecting = false;

  /// Automatically clears invalid session and redirects to AuthScreen
  Future<void> handleUnauthorized([String? message]) async {
    if (_isRedirecting) return;
    _isRedirecting = true;
    await clearSession();

    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AuthScreen(
            expirationMessage: message ?? 'Your session has ended or this account was removed. Please sign in.',
          ),
        ),
        (route) => false,
      );
    }
    Future.delayed(const Duration(seconds: 2), () {
      _isRedirecting = false;
    });
  }

  Future<bool> isExpired() async {
    final type = await getUserType();
    if (type != 'guest') return false;

    final expiryStr = await getExpiresAt();
    if (expiryStr == null) return false;

    try {
      final expiryDate = DateTime.parse(expiryStr);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return false;
    }
  }

  Future<int> getDaysRemaining() async {
    final type = await getUserType();
    if (type != 'guest') return 999;

    final expiryStr = await getExpiresAt();
    if (expiryStr == null) return 0;

    try {
      final expiryDate = DateTime.parse(expiryStr);
      final difference = expiryDate.difference(DateTime.now()).inDays;
      return difference < 0 ? 0 : difference;
    } catch (e) {
      return 0;
    }
  }
}
