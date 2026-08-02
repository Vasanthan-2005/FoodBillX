import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/onboarding_service.dart';

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingDialog extends StatefulWidget {
  final VoidCallback? onFinished;
  const OnboardingDialog({super.key, this.onFinished});

  static Future<void> showIfNeeded(BuildContext context) async {
    final isFirst = await OnboardingService.isFirstLaunch();
    if (isFirst && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const OnboardingDialog(),
      );
    }
  }

  static void forceShow(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const OnboardingDialog(),
    );
  }

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  int _currentStep = 0;

  final List<OnboardingStep> _steps = const [
    OnboardingStep(
      title: 'Welcome to HMB Bills 🚀',
      description: 'Your commercial POS & billing application for Honeymoon Biryani. Let\'s take a quick 1-minute guided tour of the key features.',
      icon: Icons.storefront_rounded,
      color: AppColors.primary,
    ),
    OnboardingStep(
      title: '1. Dashboard (📊)',
      description: 'View today\'s live sales revenue, expenses, net profit, and quick action cards for fast operations.',
      icon: Icons.dashboard_rounded,
      color: Colors.blue,
    ),
    OnboardingStep(
      title: '2. Fast Billing & Checkout (🧾)',
      description: 'Create bills in seconds. Search items, tap to add to cart, enter customer\'s Loyalty Card Number, and complete payments.',
      icon: Icons.point_of_sale_rounded,
      color: Colors.orange,
    ),
    OnboardingStep(
      title: '3. Menu Management (🍽️)',
      description: 'Manage your restaurant menu items, categories, prices, and food availability with a simple tap.',
      icon: Icons.restaurant_menu_rounded,
      color: Colors.green,
    ),
    OnboardingStep(
      title: '4. Customers & Loyalty (👥)',
      description: 'View customer directory, loyalty card numbers, and visit counts. Automatic loyalty reward alerts trigger on milestone visits!',
      icon: Icons.people_alt_rounded,
      color: Colors.purple,
    ),
    OnboardingStep(
      title: '5. Business Reports & Exports (📈)',
      description: 'Comprehensive P&L analytics, peak selling hours, top selling dishes, and 1-click PDF & Excel report exports.',
      icon: Icons.bar_chart_rounded,
      color: Colors.teal,
    ),
    OnboardingStep(
      title: '6. Settings Access (⚙️)',
      description: 'Tap the Settings icon in the top-right corner of ANY screen to configure printers, loyalty rewards, PINs, and server connection.',
      icon: Icons.settings_rounded,
      color: Colors.redAccent,
    ),
    OnboardingStep(
      title: '7. Direct WhatsApp Bill Sharing 📲',
      description: 'After checkout, tap "Pay & Send Bill" to open WhatsApp directly with pre-filled invoice details & loyalty status for your customer!',
      icon: Icons.mark_chat_read_rounded,
      color: Colors.green,
    ),
  ];

  Future<void> _completeTour() async {
    await OnboardingService.markOnboardingComplete();
    if (mounted) {
      Navigator.pop(context);
      widget.onFinished?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = _steps[_currentStep];
    final isLast = _currentStep == _steps.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Indicator & Skip Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${_currentStep + 1} of ${_steps.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: step.color,
                  ),
                ),
                TextButton(
                  onPressed: _completeTour,
                  child: const Text('Skip Tour', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Animated Icon Avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: step.color.withAlpha(30),
              child: Icon(step.icon, size: 40, color: step.color),
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              step.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Page Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (idx) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: idx == _currentStep ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: idx == _currentStep ? step.color : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _currentStep--);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  )
                else
                  const SizedBox(width: 80),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: step.color,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (isLast) {
                      _completeTour();
                    } else {
                      setState(() => _currentStep++);
                    }
                  },
                  icon: Icon(isLast ? Icons.check_circle_rounded : Icons.arrow_forward, color: Colors.white),
                  label: Text(
                    isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
