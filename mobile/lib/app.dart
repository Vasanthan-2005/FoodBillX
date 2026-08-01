import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/pin_auth_provider.dart';
import 'routes/app_router.dart';

class FoodBillXApp extends ConsumerWidget {
  const FoodBillXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinState = ref.watch(pinAuthProvider);
    final router = ref.watch(routerProvider);

    // Activate background sync listener (fires when device comes online).
    ref.watch(autoSyncProvider);

    if (pinState.mode == PinFlowMode.checking) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'FoodBillX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
