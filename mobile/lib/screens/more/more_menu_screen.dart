import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../dashboard/dashboard_screen.dart';
import '../expenses/expense_tracker_screen.dart';
import '../reports/orders_screen.dart';

class MoreMenuScreen extends StatelessWidget {
  final VoidCallback onGoToBilling;
  final VoidCallback onOpenSettings;

  const MoreMenuScreen({
    super.key,
    required this.onGoToBilling,
    required this.onOpenSettings,
  });

  void _navigateTo(BuildContext context, Widget target) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final modules = [
      {
        'title': 'Insights & Analytics',
        'subtitle': 'Sales performance & metrics',
        'icon': Icons.analytics_rounded,
        'color': Colors.purple,
        'onTap': () => _navigateTo(
              context,
              DashboardScreen(
                onGoToBilling: onGoToBilling,
                onOpenSettings: onOpenSettings,
              ),
            ),
      },
      {
        'title': 'Order Receipts',
        'subtitle': 'Billing history & search',
        'icon': Icons.history_rounded,
        'color': Colors.amber.shade800,
        'onTap': () => _navigateTo(
              context,
              OrdersScreen(onOpenSettings: onOpenSettings),
            ),
      },
      {
        'title': 'Expense Tracker',
        'subtitle': 'Log operational costs',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.red.shade600,
        'onTap': () => _navigateTo(
              context,
              ExpenseTrackerScreen(onOpenSettings: onOpenSettings),
            ),
      },
      {
        'title': 'Store & PIN Setup',
        'subtitle': 'Business profile & tax rates',
        'icon': Icons.settings_rounded,
        'color': Colors.blueGrey,
        'onTap': onOpenSettings,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('More Management Tools'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Secondary Modules',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Quick access to reports, expenses, order receipts, and settings.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemCount: modules.length,
              itemBuilder: (ctx, index) {
                final item = modules[index];
                final title = item['title'] as String;
                final subtitle = item['subtitle'] as String;
                final icon = item['icon'] as IconData;
                final color = item['color'] as Color;
                final onTap = item['onTap'] as VoidCallback;

                return Card(
                  margin: EdgeInsets.zero,
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: color.withAlpha(60),
                                  ),
                                ),
                                child: Icon(icon, color: color, size: 24),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
