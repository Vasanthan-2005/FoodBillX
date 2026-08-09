import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../providers/bootstrap_provider.dart';

class NetworkErrorScreen extends ConsumerWidget {
  const NetworkErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapState = ref.watch(bootstrapProvider);
    final errorMsg = bootstrapState.errorMessage ??
        "We couldn't connect to the server. Please check your internet connection and try again.";

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withAlpha(80),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.shade500.withAlpha(120),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade900.withAlpha(100),
                        blurRadius: 32,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Colors.redAccent,
                    size: 56,
                  ),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack)
                    .fade(duration: 400.ms),

                const SizedBox(height: 32),

                const Text(
                  'Network Error',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fade(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                Text(
                  errorMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey.shade400,
                  ),
                ).animate().fade(delay: 350.ms, duration: 500.ms),

                const SizedBox(height: 40),

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: bootstrapState.isLoading
                        ? null
                        : () async {
                            context.go('/splash');
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: bootstrapState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh_rounded, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Retry Connection',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ).animate().fade(delay: 500.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
