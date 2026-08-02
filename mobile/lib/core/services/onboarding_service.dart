import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding_v2';

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyHasCompletedOnboarding) ?? false);
  }

  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasCompletedOnboarding, true);
  }

  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasCompletedOnboarding, false);
  }
}
