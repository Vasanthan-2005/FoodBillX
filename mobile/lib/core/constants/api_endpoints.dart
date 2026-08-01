import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiEndpoints {
  /// The LAN IP of the machine running the backend.
  /// Update this if your PC's IP address changes (run `ipconfig` to check).
  static const String _lanIp = '192.168.29.250';

  // Base URL — dynamically selects the right address per platform.
  // • Web             → localhost (same origin)
  // • Android (real)  → LAN IP of the PC running the backend
  // • Android (emu)   → 10.0.2.2 (loopback alias for emulator)
  // • Windows/iOS     → 127.0.0.1
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    if (Platform.isAndroid) {
      // Use LAN IP to reach PC backend from a physical Android device on same WiFi.
      // (10.0.2.2 only works for Android Studio emulators, not real phones.)
      return 'http://$_lanIp:5000/api/v1';
    }
    return 'http://127.0.0.1:5000/api/v1';
  }

  static const String localhostUrl = 'http://127.0.0.1:5000/api/v1';

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
