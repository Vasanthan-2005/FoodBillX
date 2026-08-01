import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const String _keyAuthToken = 'fbx_auth_token';
  static const String _keyUserId = 'fbx_user_id';
  static const String _keyUserRole = 'fbx_user_role';
  static const String _keyBusinessName = 'fbx_business_name';

  String _encode(String input) {
    return base64Url.encode(utf8.encode(input));
  }

  String _decode(String input) {
    try {
      return utf8.decode(base64Url.decode(input));
    } catch (_) {
      return input;
    }
  }

  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, _encode(token));
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAuthToken);
    if (raw == null) return null;
    return _decode(raw);
  }

  Future<void> saveUserData({
    required String id,
    required String role,
    required String businessName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, _encode(id));
    await prefs.setString(_keyUserRole, _encode(role));
    await prefs.setString(_keyBusinessName, _encode(businessName));
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyUserId);
    final role = prefs.getString(_keyUserRole);
    final businessName = prefs.getString(_keyBusinessName);
    return {
      'id': id != null ? _decode(id) : null,
      'role': role != null ? _decode(role) : null,
      'businessName': businessName != null ? _decode(businessName) : null,
    };
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyBusinessName);
  }
}
