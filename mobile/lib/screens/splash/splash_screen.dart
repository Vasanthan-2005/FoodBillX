import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/pin_auth_provider.dart';
import '../../providers/settings_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    final startTime = DateTime.now();

    // Perform startup prefetch of required app data in parallel
    try {
      await Future.wait([
        ref.read(menuProvider.notifier).loadCategoriesAndItems(),
        ref.read(customerProvider.notifier).loadCustomers(),
        ref.read(settingsProvider.notifier).loadSettings(),
        ref.read(dashboardProvider.notifier).refresh(forceSpinner: true),
        ref.read(expenseProvider.notifier).loadAll(),
        ref.read(ordersProvider.notifier).loadOrders(),
      ]);
    } catch (_) {
      // Ignore initial network issues, local cache fallbacks exist
    }

    // Ensure minimum splash duration of 4 seconds (4000 ms)
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 4000) {
      await Future.delayed(Duration(milliseconds: 4000 - elapsed));
    }

    if (!mounted) return;

    final pinState = ref.read(pinAuthProvider);
    if (pinState.mode == PinFlowMode.unlocked) {
      context.go('/home');
    } else {
      context.go('/pin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Logo & Title
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(120),
                          blurRadius: 32,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 700.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fade(duration: 400.ms),

                  const SizedBox(height: 24),

                  const Text(
                    'HMB Bills',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  )
                      .animate()
                      .fade(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 8),

                  Text(
                    'Honeymoon Biryani POS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withAlpha(220),
                      letterSpacing: 0.6,
                    ),
                  ).animate().fade(delay: 350.ms, duration: 500.ms),
                ],
              ),
            ),

            // Bottom Footer
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Powered by FoodBillX',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
              ).animate().fade(delay: 500.ms, duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}
