import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';

class FoodBillXApp extends ConsumerWidget {
  const FoodBillXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final themeData = AppTheme.getTheme(themeMode);

    return MaterialApp.router(
      title: 'HMB Bills',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      darkTheme: themeData,
      themeMode: ThemeMode.dark, // Always use the explicitly-selected theme
      routerConfig: router,
    );
  }
}
