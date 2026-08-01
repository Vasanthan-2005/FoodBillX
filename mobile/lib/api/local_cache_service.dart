import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const String _prefix = 'fbx_cache_';

  static Future<void> saveCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(data);
      await prefs.setString('$_prefix$key', jsonStr);
    } catch (_) {}
  }

  static Future<dynamic> getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_prefix$key');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return jsonDecode(jsonStr);
      }
    } catch (_) {}
    return null;
  }
}
