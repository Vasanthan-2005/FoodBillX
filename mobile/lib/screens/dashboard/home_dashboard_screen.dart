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

import '../../core/widgets/profit_display_widget.dart';
import '../../core/widgets/revenue_line_chart_widget.dart';

import '../../core/widgets/live_badge_widget.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
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
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(dashboardProvider);
    final settings = ref.watch(settingsProvider).settings;
    final customerState = ref.watch(customerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(DateTime.now());

    final customerCount = customerState.customers.length;

    const xLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    final last7Total = metrics.recentDailyRevenue.fold<double>(0.0, (s, e) => s + e);
    final display7Total = last7Total > 0 ? last7Total : metrics.weekRevenue;

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
                Expanded(
                  child: Text(
                    settings?.businessName ?? 'HMB Bills',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 6.0),
              child: LiveBadgeWidget(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Previous Orders',
            onPressed: widget.onOpenOrders,
          ),
          IconButton(
            icon: const Icon(Icons.currency_rupee_rounded),
            tooltip: 'Add Expense',
            onPressed: widget.onOpenExpenses,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
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
                    value: metrics.todayExpenseTotal <= 0
                        ? 'Log expenses'
                        : CurrencyFormatter.format(metrics.netProfitToday),
                    icon: Icons.trending_up_rounded,
                    color: metrics.todayExpenseTotal <= 0
                        ? Colors.orange.shade800
                        : (metrics.netProfitToday >= 0 ? AppColors.secondary : Colors.red),
                    subtitle: metrics.todayExpenseTotal <= 0
                        ? 'Log expenses to see profit'
                        : 'Revenue - Expenses',
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
                      _buildProfitSummaryRow('Today\'s Net Profit', metrics.todayExpenseTotal, metrics.netProfitToday),
                      const Divider(height: 20),
                      _buildProfitSummaryRow('Weekly Net Profit', metrics.weekExpenseTotal, metrics.weeklyProfit),
                      const Divider(height: 20),
                      _buildProfitSummaryRow('Monthly Net Profit', metrics.monthExpenseTotal, metrics.monthlyProfit),
                      const Divider(height: 20),
                      _buildProfitSummaryRow('Overall Net Profit', metrics.overallExpenseTotal, metrics.overallProfit),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 7-Day Revenue Trend Header & Line Chart
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
                    onPressed: () => widget.onNavigateToTab(3), // Reports (Tab 3)
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: const Text('Full Reports'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (metrics.isLoading)
                const SkeletonLoader(height: 220, width: double.infinity)
              else
                RevenueLineChartWidget(
                  title: '7 Day Revenue Trend',
                  totalRevenue: display7Total,
                  percentageChange: 12.5,
                  percentageSubtitle: 'vs previous 7 days',
                  xLabels: xLabels,
                  dataPoints: metrics.recentDailyRevenue.isNotEmpty
                      ? metrics.recentDailyRevenue
                      : List.filled(7, 0.0),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfitSummaryRow(String label, double expenseAmount, double profitAmount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        ProfitDisplayWidget(
          expenseAmount: expenseAmount,
          profitAmount: profitAmount,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
