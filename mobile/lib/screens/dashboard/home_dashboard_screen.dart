import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/live_badge_widget.dart';
import '../../core/widgets/metric_card_widget.dart';
import '../../core/widgets/revenue_line_chart_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  final Function(int tabIndex) onNavigateToTab;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenExpenses;
  final int reportsTabIndex;

  const HomeDashboardScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onOpenSettings,
    required this.onOpenOrders,
    required this.onOpenExpenses,
    this.reportsTabIndex = 4,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    // Generate accurate day labels for the past 7 days ending today
    final now = DateTime.now();
    final xLabels = List<String>.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateFormat('E').format(d);
    });

    final last7Total = metrics.recentDailyRevenue.fold<double>(0.0, (s, e) => s + e);
    final display7Total = last7Total > 0 ? last7Total : metrics.weekRevenue;

    // 7-day pct change vs previous 7 days
    final double pct7 = metrics.previousWeekRevenue > 0
        ? ((display7Total - metrics.previousWeekRevenue) / metrics.previousWeekRevenue * 100)
        : 0.0;

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
                    settings?.businessName ?? 'FoodBillX',
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
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 4.0),
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
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(forceSpinner: true),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Daily Core KPI Cards (2x2 Grid)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Pulse',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Live Today',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.secondary,
                    subtitle: metrics.todayOrderCount > 0
                        ? '${metrics.todayOrderCount} orders billed'
                        : 'No orders yet',
                  ),
                  MetricCardWidget(
                    title: 'Today\'s Orders',
                    value: '${metrics.todayOrderCount}',
                    icon: Icons.receipt_long_rounded,
                    color: Colors.blue.shade600,
                    subtitle: metrics.todayOrderCount > 0
                        ? 'Avg. ${CurrencyFormatter.format(metrics.todayRevenue / metrics.todayOrderCount)}'
                        : '0 billed today',
                  ),
                  MetricCardWidget(
                    title: 'Today\'s Expenses',
                    value: CurrencyFormatter.format(metrics.todayExpenseTotal),
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.red.shade400,
                    subtitle: metrics.todayExpenseTotal > 0
                        ? 'Operational costs'
                        : '₹0 recorded',
                  ),
                  MetricCardWidget(
                    title: 'Today\'s Net Profit',
                    value: metrics.todayExpenseTotal > 0
                        ? CurrencyFormatter.format(metrics.netProfitToday)
                        : 'Add expense',
                    icon: metrics.todayExpenseTotal > 0
                        ? Icons.trending_up_rounded
                        : Icons.info_outline_rounded,
                    color: metrics.todayExpenseTotal > 0
                        ? (metrics.netProfitToday >= 0 ? AppColors.secondary : Colors.red)
                        : Colors.amber.shade700,
                    subtitle: metrics.todayExpenseTotal > 0
                        ? 'Revenue - Expenses'
                        : 'to know profit',
                  ),
                ],
              ).animate().fade(duration: 300.ms),

              const SizedBox(height: 20),

              // 2. 7-Day Revenue Trend Chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '7-Day Sales Trend',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () => widget.onNavigateToTab(widget.reportsTabIndex),
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: const Text('View Full Reports'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (metrics.isLoading)
                const SkeletonLoader(height: 220, width: double.infinity)
              else
                RevenueLineChartWidget(
                  title: 'Past 7 Days Revenue',
                  totalRevenue: display7Total,
                  percentageChange: pct7,
                  percentageSubtitle: 'vs prior 7 days',
                  xLabels: xLabels,
                  dataPoints: metrics.recentDailyRevenue.isNotEmpty
                      ? metrics.recentDailyRevenue
                      : List.filled(7, 0.0),
                ),

              const SizedBox(height: 20),

              // 3. Quick Insights (Derived strictly from real data)
              Text(
                'Quick Insights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),

              _buildQuickInsightsCard(context, metrics, isDark),

              const SizedBox(height: 20),

              // 4. View Full Reports Call-To-Action Banner
              InkWell(
                onTap: () => widget.onNavigateToTab(widget.reportsTabIndex),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(60),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detailed Business Reports',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'P&L periods, dish rankings, customer loyalty & PDF export',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
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

  Widget _buildQuickInsightsCard(BuildContext context, DashboardState metrics, bool isDark) {
    // 1. Daily pace insight
    String paceText;
    IconData paceIcon;
    Color paceColor;
    if (metrics.todayRevenue <= 0) {
      paceText = 'No orders billed yet today. Once you start billing, live performance will appear.';
      paceIcon = Icons.info_outline_rounded;
      paceColor = Colors.grey;
    } else if (metrics.yesterdayRevenue > 0) {
      final diff = metrics.todayRevenue - metrics.yesterdayRevenue;
      final pct = (diff / metrics.yesterdayRevenue) * 100;
      if (pct >= 0) {
        paceText = 'Today is running +${pct.toStringAsFixed(1)}% higher than yesterday\'s total (${CurrencyFormatter.format(metrics.yesterdayRevenue)}).';
        paceIcon = Icons.trending_up_rounded;
        paceColor = AppColors.secondary;
      } else {
        paceText = 'Today is ${pct.abs().toStringAsFixed(1)}% below yesterday (${CurrencyFormatter.format(metrics.yesterdayRevenue)}).';
        paceIcon = Icons.trending_down_rounded;
        paceColor = Colors.amber.shade800;
      }
    } else {
      paceText = 'First sales recorded for today (${CurrencyFormatter.format(metrics.todayRevenue)} across ${metrics.todayOrderCount} orders).';
      paceIcon = Icons.rocket_launch_rounded;
      paceColor = AppColors.secondary;
    }

    // 2. Top Dish Insight
    String dishText;
    if (metrics.todayTopDishName.isNotEmpty && metrics.todayTopDishCount > 0) {
      dishText = 'Top seller today: ${metrics.todayTopDishName} (${metrics.todayTopDishCount} units ordered).';
    } else if (metrics.topSellingItems.isNotEmpty) {
      final overallTop = metrics.topSellingItems.first['_id']?.toString() ?? 'Popular dish';
      final count = metrics.topSellingItems.first['totalQuantity'] ?? 0;
      dishText = 'All-time top dish: $overallTop ($count units sold total).';
    } else {
      dishText = 'No dish sales data yet.';
    }

    // 3. Payment insight
    String payText;
    final cash = metrics.todayPaymentBreakdown['cash'] ?? 0.0;
    final upi = metrics.todayPaymentBreakdown['upi'] ?? 0.0;
    final card = metrics.todayPaymentBreakdown['card'] ?? 0.0;
    final totalPay = cash + upi + card;

    if (totalPay > 0) {
      final topMethod = (upi >= cash && upi >= card)
          ? 'UPI / QR (${((upi / totalPay) * 100).toStringAsFixed(0)}%)'
          : (cash >= upi && cash >= card)
              ? 'Cash (${((cash / totalPay) * 100).toStringAsFixed(0)}%)'
              : 'Card (${((card / totalPay) * 100).toStringAsFixed(0)}%)';
      payText = 'Preferred payment today is $topMethod.';
    } else if (metrics.overallRevenue > 0) {
      final oCash = (metrics.paymentAnalytics['cash'] as num?)?.toDouble() ?? 0.0;
      final oUpi = (metrics.paymentAnalytics['upi'] as num?)?.toDouble() ?? 0.0;
      final oTotal = oCash + oUpi + ((metrics.paymentAnalytics['card'] as num?)?.toDouble() ?? 0.0);
      if (oTotal > 0) {
        payText = oUpi >= oCash
            ? 'Overall, guests prefer digital UPI payments.'
            : 'Overall, cash is the most frequent payment method.';
      } else {
        payText = 'Payment insights will appear once payments are recorded.';
      }
    } else {
      payText = 'No payment records yet.';
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInsightRow(paceIcon, paceColor, paceText),
            const Divider(height: 20),
            _buildInsightRow(Icons.restaurant_rounded, Colors.orange.shade800, dishText),
            const Divider(height: 20),
            _buildInsightRow(Icons.account_balance_rounded, Colors.blue.shade600, payText),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
