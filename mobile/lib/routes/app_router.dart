import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/pin_auth_provider.dart';
import '../screens/auth/pin_screen.dart';
import '../screens/home_shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final pinState = ref.watch(pinAuthProvider);

  return GoRouter(
    initialLocation: '/pin',
    redirect: (context, state) {
      final isUnlocked = pinState.mode == PinFlowMode.unlocked;
      final isPinRoute = state.uri.toString() == '/pin';

      if (pinState.mode == PinFlowMode.checking) {
        return null;
      }

      if (!isUnlocked && !isPinRoute) {
        return '/pin';
      }

      if (isUnlocked && isPinRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/pin', builder: (context, state) => const PinScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShellScreen(),
      ),
    ],
  );
});
