import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  static const String liveProductionUrl =
      'https://foodbillx.onrender.com/api/v1';

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String? _overrideBaseUrl;
  static const String defaultLanIp = 'http://192.168.0.176:5000/api/v1';
  static const String emulatorIp = 'http://10.0.2.2:5000/api/v1';
  static const String localhostIp = 'http://127.0.0.1:5000/api/v1';

  static String _formatUrl(String url) {
    String clean = url.trim().replaceFirst(RegExp(r'/$'), '');
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      final isLocal = clean.startsWith('127.0.0.1') ||
          clean.startsWith('localhost') ||
          clean.startsWith('10.0.2.2') ||
          clean.startsWith('192.168.');
      clean = isLocal ? 'http://$clean' : 'https://$clean';
    }
    if (!clean.endsWith('/api/v1')) {
      clean = '$clean/api/v1';
    }
    return clean;
  }

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
        final clean = _formatUrl(url);
        await prefs.setString('fbx_custom_server_url', clean);
        setOverrideBaseUrl(clean);
      }
    } catch (_) {}
  }

  static void setOverrideBaseUrl(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      _overrideBaseUrl = _formatUrl(url);
    } else {
      _overrideBaseUrl = null;
    }
  }

  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    if (_configuredBaseUrl.isNotEmpty) {
      return _formatUrl(_configuredBaseUrl);
    }
    return liveProductionUrl;
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String getProfile = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  static const String verifyOwner = '/auth/verify-owner';

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
