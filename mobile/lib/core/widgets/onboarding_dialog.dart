import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

enum TourTargetSpace {
  billing,
  menu,
  customers,
  dashboard,
  expenses,
  orders,
  reports,
  settings,
}

class OnboardingStep {
  final String title;
  final String description;
  final String tip;
  final String spaceLabel;
  final IconData icon;
  final Color color;
  final int tabIndex;
  final TourTargetSpace targetSpace;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.tip,
    required this.spaceLabel,
    required this.icon,
    required this.color,
    required this.tabIndex,
    required this.targetSpace,
  });
}

const List<OnboardingStep> guidedTourSteps = [
  OnboardingStep(
    title: 'Welcome to HMB Bills',
    description:
        'This live tour takes you to each tab and workspace so you can see where everything lives and how every workflow works.',
    tip: 'Tap Next to walk through Billing, Menu, Customers, Expenses, Orders, Reports & Settings',
    spaceLabel: 'Guided Tour',
    icon: Icons.storefront_rounded,
    color: AppColors.primary,
    tabIndex: 0,
    targetSpace: TourTargetSpace.billing,
  ),
  OnboardingStep(
    title: 'POS Billing & Checkout',
    description:
        'You are now on the Billing tab. Search dishes or filter by category, tap items to add to cart, attach a customer or loyalty card, choose payment mode, and share PDF bills via WhatsApp.',
    tip: 'Tap any dish tile to add it • Cart bar appears at the bottom',
    spaceLabel: 'Billing Tab',
    icon: Icons.point_of_sale_rounded,
    color: Colors.orange,
    tabIndex: 0,
    targetSpace: TourTargetSpace.billing,
  ),
  OnboardingStep(
    title: 'Menu Management',
    description:
        'Here on the Menu tab you manage categories and dishes. Flip items In Stock or Out with one switch, toggle Grid/List views, or tap any item card to edit price and details.',
    tip: 'Tap + Category chip to organize menu sections • Tap any dish tile to edit',
    spaceLabel: 'Menu Tab',
    icon: Icons.restaurant_menu_rounded,
    color: Colors.green,
    tabIndex: 1,
    targetSpace: TourTargetSpace.menu,
  ),
  OnboardingStep(
    title: 'Customers & Loyalty',
    description:
        'On the Customers tab you can search guests by name or phone, view total visits & lifetime spend, assign loyalty cards, and tap any customer tile to update details.',
    tip: 'Loyalty milestone alerts automatically trigger during checkout',
    spaceLabel: 'Customers Tab',
    icon: Icons.people_alt_rounded,
    color: Colors.purple,
    tabIndex: 2,
    targetSpace: TourTargetSpace.customers,
  ),
  OnboardingStep(
    title: 'Live Dashboard',
    description:
        'The Dashboard tab shows Today\'s Revenue, Orders, Expenses, Net Profit, a 7-day sales chart, and Insights. Tapping Today\'s Expenses opens Expenses; top-bar icons jump straight to Previous Orders or Add Expense.',
    tip: 'Tap Today\'s Expenses card anytime to log an expense',
    spaceLabel: 'Dashboard Tab',
    icon: Icons.dashboard_rounded,
    color: Colors.blue,
    tabIndex: 3,
    targetSpace: TourTargetSpace.dashboard,
  ),
  OnboardingStep(
    title: 'Expense Tracker',
    description:
        'Welcome to Expense Management (opened from Dashboard). Record daily stock, salary, rent, or gas expenses, set a monthly budget bar, and tap any expense tile to edit or delete.',
    tip: 'Expenses power accurate Net Profit metrics on Dashboard & Reports',
    spaceLabel: 'Expenses Space',
    icon: Icons.currency_rupee_rounded,
    color: Colors.redAccent,
    tabIndex: 3,
    targetSpace: TourTargetSpace.expenses,
  ),
  OnboardingStep(
    title: 'Previous Orders & Bills',
    description:
        'Inside Previous Orders you can browse receipts by Today, Week, Month, or custom From/To date range, filter by payment mode, and tap any order tile to edit, delete, or reprint PDF.',
    tip: 'Editing or deleting an order automatically updates customer totals & reports',
    spaceLabel: 'Orders Space',
    icon: Icons.receipt_long_rounded,
    color: Colors.amber,
    tabIndex: 3,
    targetSpace: TourTargetSpace.orders,
  ),
  OnboardingStep(
    title: 'Reports & PDF/Excel Export',
    description:
        'On the Reports tab, use the period slicer and Daily/Weekly/Monthly/Yearly/Custom filters to analyze revenue, profit, top dishes, payments, and expenses — then tap Export in the top right.',
    tip: 'Export Business Reports (PDF with charts), Customers, Orders, or Full Excel Backup',
    spaceLabel: 'Reports Tab',
    icon: Icons.bar_chart_rounded,
    color: Colors.teal,
    tabIndex: 4,
    targetSpace: TourTargetSpace.reports,
  ),
  OnboardingStep(
    title: 'Settings, Themes & Cloud Sync',
    description:
        'Settings (accessible from the gear icon on any screen) lets you switch themes including Ultra Dark, upload local orders/customers/settings to Cloud Sync, update Loyalty & Store info, change PIN, and import/export backups.',
    tip: 'Settings is the single control center for Cloud Sync, Themes, Backup & PIN',
    spaceLabel: 'Settings Space',
    icon: Icons.settings_rounded,
    color: AppColors.primary,
    tabIndex: 4,
    targetSpace: TourTargetSpace.settings,
  ),
];

/// Floating guided-tour card docked over the live active tab or space.
class GuidedTourOverlayCard extends StatelessWidget {
  final OnboardingStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const GuidedTourOverlayCard({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = AppTheme.isAmoledTheme(context);
    final isLast = stepIndex >= totalSteps - 1;
    final cardColor = isAmoled
        ? AppColors.amoledCard
        : (theme.cardTheme.color ??
            (isDark ? AppColors.darkCard : AppColors.lightCard));

    return Material(
      elevation: isAmoled ? 0 : 12,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: step.color.withAlpha(isAmoled ? 180 : 140),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: step.color.withAlpha(28),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: step.color.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(step.icon, size: 14, color: step.color),
                      const SizedBox(width: 6),
                      Text(
                        '${stepIndex + 1}/$totalSteps • ${step.spaceLabel}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: step.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: onSkip,
                  child: const Text('Skip', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              step.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              step.description,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.38,
                color: theme.textTheme.bodyMedium?.color ??
                    (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: step.color.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: step.color.withAlpha(55)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_rounded, size: 15, color: step.color),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      step.tip,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white.withAlpha(220) : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Step dots
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(totalSteps, (idx) {
                      final active = idx == stepIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? step.color : Colors.grey.withAlpha(90),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                if (onBack != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Back'),
                  ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: step.color,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onNext,
                  icon: Icon(
                    isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    isLast ? 'Finish' : 'Next',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
