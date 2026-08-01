import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/pin_auth_provider.dart';

class PinScreen extends ConsumerWidget {
  const PinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pinAuthProvider);
    final notifier = ref.read(pinAuthProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String title = 'Enter Owner PIN';
    String subtitle = 'Enter your 4-digit security PIN to unlock';

    if (state.mode == PinFlowMode.createPin) {
      title = 'Create Your 4-Digit PIN';
      subtitle = 'Set a 4-digit security PIN for your POS app';
    } else if (state.mode == PinFlowMode.confirmPin) {
      title = 'Confirm Your PIN';
      subtitle = 'Re-enter your 4-digit PIN to confirm';
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo & Header
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryVariant],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(90),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ).animate().scale(
                    duration: 350.ms,
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'HMB Bills',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // PIN 4 Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < state.currentInput.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        height: 18,
                        width: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isFilled
                                ? AppColors.primary
                                : Colors.grey.shade500,
                            width: 2,
                          ),
                          boxShadow: isFilled
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(120),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Error Message Banner
                  if (state.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade400),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ).animate().shake(duration: 400.ms),
                  const SizedBox(height: 32),

                  // 3x4 Keypad Grid
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['1', '2', '3']
                            .map(
                              (digit) => _buildKeypadButton(
                                context,
                                digit,
                                () => notifier.appendDigit(digit),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['4', '5', '6']
                            .map(
                              (digit) => _buildKeypadButton(
                                context,
                                digit,
                                () => notifier.appendDigit(digit),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['7', '8', '9']
                            .map(
                              (digit) => _buildKeypadButton(
                                context,
                                digit,
                                () => notifier.appendDigit(digit),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildIconButton(
                            context,
                            Icons.clear_all,
                            notifier.clearInput,
                          ),
                          _buildKeypadButton(
                            context,
                            '0',
                            () => notifier.appendDigit('0'),
                          ),
                          _buildIconButton(
                            context,
                            Icons.backspace_outlined,
                            notifier.deleteDigit,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(
    BuildContext context,
    String text,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          height: 72,
          width: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          height: 72,
          width: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppColors.darkCard.withAlpha(50)
                : AppColors.lightCard,
          ),
          child: Icon(
            icon,
            size: 24,
            color: isDark ? Colors.grey : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
