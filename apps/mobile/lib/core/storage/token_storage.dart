import 'package:shared_preferences/shared_preferences.dart';

/// Persistance du JWT — utilise SharedPreferences (localStorage sur web).
class TokenStorage {
  TokenStorage._();

  static const _tokenKey = 'trackeo_access_token';
  static const _emailKey = 'trackeo_user_email';
  static const _nameKey = 'trackeo_user_name';
  static const _userIdKey = 'trackeo_user_id';

  static Future<void> saveSession({
    required String token,
    required String email,
    required int userId,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    await prefs.setInt(_userIdKey, userId);
    if (name != null) await prefs.setString(_nameKey, name);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<({String? token, String? email, String? name, int? userId})>
      getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      token: prefs.getString(_tokenKey),
      email: prefs.getString(_emailKey),
      name: prefs.getString(_nameKey),
      userId: prefs.getInt(_userIdKey),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_userIdKey);
  }
}
