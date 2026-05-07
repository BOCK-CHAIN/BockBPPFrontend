// lib/core/session.dart
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const _keySessionId = 'session_id';
  static const _keyUserId = 'user_id';
  static const _keyFirstName = 'first_name';
  static const _keyEmail = 'email';

  static Future<void> save({
    required String sessionId,
    required String userId,
    required String firstName,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionId, sessionId);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyFirstName, firstName);
    await prefs.setString(_keyEmail, email);
  }

  static Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySessionId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<String?> getFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFirstName);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<bool> isLoggedIn() async {
    final id = await getSessionId();
    return id != null && id.isNotEmpty;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
