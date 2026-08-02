import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/metric_card_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  final Function(int tabIndex) onNavigateToTab;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenExpenses;

  const HomeDashboardScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onOpenSettings,
    required this.onOpenOrders,
    required this.onOpenExpenses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardProvider);
    final settings = ref.watch(settingsProvider).settings;
    final customerState = ref.watch(customerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(DateTime.now());

    final customerCount = customerState.customers.length;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  settings?.businessName ?? 'HMB Bills',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Previous Orders',
            onPressed: onOpenOrders,
          ),
          IconButton(
            icon: const Icon(Icons.currency_rupee_rounded),
            tooltip: 'Add Expense',
            onPressed: onOpenExpenses,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).refresh();
          await ref.read(customerProvider.notifier).loadCustomers();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Financial Summary Header
              Text(
                'Today\'s Financial Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // 4 Core Financial KPI Cards Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  MetricCardWidget(
                    title: 'Today\'s Revenue',
                    value: CurrencyFormatter.format(metrics.todayRevenue),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.secondary,
                    subtitle: '${metrics.todayOrderCount} orders billed',
                  ),
                  MetricCardWidget(
                    title: 'Today\'s Expenses',
                    value: CurrencyFormatter.format(metrics.todayExpenseTotal),
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.red.shade400,
                    subtitle: 'Operational costs',
                  ),
                  MetricCardWidget(
                    title: 'Today\'s Net Profit',
                    value: CurrencyFormatter.format(metrics.netProfitToday),
                    icon: Icons.trending_up_rounded,
                    color: metrics.netProfitToday >= 0 ? AppColors.secondary : Colors.red,
                    subtitle: 'Revenue - Expenses',
                  ),
                  MetricCardWidget(
                    title: 'Active Customers',
                    value: customerCount > 0 ? customerCount.toString() : '0',
                    icon: Icons.people_outline_rounded,
                    color: Colors.purple,
                    subtitle: 'Loyalty members',
                  ),
                ],
              ).animate().fade(duration: 350.ms),

              const SizedBox(height: 24),

              // Multi-timeframe Profit Overview
              Text(
                'Profit & Loss Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfitSummaryRow('Today\'s Net Profit', metrics.netProfitToday, isDark),
                      const Divider(height: 20),
                      _buildProfitSummaryRow('Weekly Net Profit', metrics.weeklyProfit, isDark),
                      const Divider(height: 20),
                      _buildProfitSummaryRow('Monthly Net Profit', metrics.monthlyProfit, isDark),
                      const Divider(height: 20),
                      _buildProfitSummaryRow('Overall Net Profit', metrics.overallProfit, isDark),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Weekly Revenue Trend Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Sales Trend',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () => onNavigateToTab(4), // Reports (Tab 4)
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: const Text('Full Reports'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '7-Day Revenue',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.format(metrics.weekRevenue),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${metrics.weekOrderCount} orders',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (metrics.isLoading)
                        const SkeletonLoader(height: 100, width: double.infinity)
                      else
                        _buildSimpleBarChart(metrics.recentDailyRevenue, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfitSummaryRow(String label, double amount, bool isDark) {
    final isProfit = amount >= 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: isProfit ? AppColors.secondary : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleBarChart(List<double> data, bool isDark) {
    final maxVal = data.fold<double>(1.0, (m, e) => e > m ? e : m);
    final today = DateTime.now();
    final days = List.generate(data.length, (i) {
      final d = today.subtract(Duration(days: data.length - 1 - i));
      return DateFormat('EEE').format(d);
    });

    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (index) {
          final val = data[index];
          final heightPct = (val / maxVal).clamp(0.08, 1.0);
          final dayLabel = days[index];
          final isToday = index == data.length - 1;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24,
                height: 70 * heightPct,
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary
                      : (val > 0
                          ? AppColors.secondary
                          : (isDark ? Colors.white10 : Colors.black12)),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
