import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/pin_auth_provider.dart';
import '../screens/auth/owner_verification_screen.dart';
import '../screens/auth/pin_screen.dart';
import '../screens/auth/reset_pin_screen.dart';
import '../screens/home_shell_screen.dart';
import '../screens/splash/splash_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<PinAuthState>(
      pinAuthProvider,
      (previous, next) {
        if (previous?.mode != next.mode) {
          notifyListeners();
        }
      },
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final pinState = ref.read(pinAuthProvider);
      final isUnlocked = pinState.mode == PinFlowMode.unlocked;
      final uri = state.uri.toString();
      final isForgotPin = uri.startsWith('/forgot-pin');

      // Allow splash screen to render without initial redirect interruption
      if (uri == '/splash') {
        return null;
      }

      if (pinState.mode == PinFlowMode.checking) {
        return null;
      }

      if (!isUnlocked && uri != '/pin' && !isForgotPin) {
        return '/pin';
      }

      if (isUnlocked && (uri == '/pin' || uri == '/splash' || isForgotPin)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/pin',
        builder: (context, state) => const PinScreen(),
      ),
      GoRoute(
        path: '/forgot-pin/verify',
        builder: (context, state) => const OwnerVerificationScreen(),
      ),
      GoRoute(
        path: '/forgot-pin/reset',
        builder: (context, state) => const ResetPinScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShellScreen(),
      ),
    ],
  );
});
