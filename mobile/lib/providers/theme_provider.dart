import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

const String _themePrefKey = 'fbx_app_theme_mode';

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.dark) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themePrefKey);
      if (saved != null) {
        final mode = AppThemeMode.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => AppThemeMode.dark,
        );
        state = mode;
      }
    } catch (_) {}
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, mode.name);
    } catch (_) {}
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});
