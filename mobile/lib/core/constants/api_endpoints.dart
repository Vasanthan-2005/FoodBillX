import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String? _overrideBaseUrl;
  static const String defaultLanIp = 'http://192.168.0.176:5000/api/v1';
  static const String emulatorIp = 'http://10.0.2.2:5000/api/v1';
  static const String localhostIp = 'http://127.0.0.1:5000/api/v1';

  static Future<void> initSavedServerUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('fbx_custom_server_url');
      if (saved != null && saved.isNotEmpty) {
        setOverrideBaseUrl(saved);
      }
    } catch (_) {}
  }

  static Future<void> saveCustomServerUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url.trim().isEmpty) {
        await prefs.remove('fbx_custom_server_url');
        setOverrideBaseUrl(null);
      } else {
        String clean = url.trim().replaceFirst(RegExp(r'/$'), '');
        if (!clean.contains('http://') && !clean.contains('https://')) {
          clean = 'http://$clean';
        }
        if (!clean.endsWith('/api/v1')) {
          clean = '$clean/api/v1';
        }
        await prefs.setString('fbx_custom_server_url', clean);
        setOverrideBaseUrl(clean);
      }
    } catch (_) {}
  }

  static void setOverrideBaseUrl(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      String clean = url.trim().replaceFirst(RegExp(r'/$'), '');
      if (!clean.contains('http://') && !clean.contains('https://')) {
        clean = 'http://$clean';
      }
      if (!clean.endsWith('/api/v1')) {
        clean = '$clean/api/v1';
      }
      _overrideBaseUrl = clean;
    } else {
      _overrideBaseUrl = null;
    }
  }

  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }
    if (kIsWeb) {
      return '${Uri.base.origin}/api/v1';
    }
    if (Platform.isAndroid) {
      return defaultLanIp;
    }
    return localhostIp;
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String getProfile = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  // Business Settings
  static const String settings = '/settings';

  // Categories & Menu Items
  static const String categories = '/categories';
  static const String menuItems = '/menu-items';

  // Customers & Loyalty
  static const String customers = '/customers';
  static const String loyaltyCards = '/loyalty-cards';

  // Orders & Billing
  static const String orders = '/orders';

  // Expenses
  static const String expenses = '/expenses';
  static const String expenseCategories = '/expense-categories';

  // Reports & Analytics
  static const String reportsSummary = '/reports/summary';
  static const String analytics = '/analytics';
}
