import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/report_export_helper.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/live_badge_widget.dart';
import '../../core/widgets/metric_card_widget.dart';
import '../../core/widgets/profit_display_widget.dart';
import '../../core/widgets/revenue_line_chart_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onGoToBilling;
  final VoidCallback onOpenSettings;

  const DashboardScreen({
    super.key,
    required this.onGoToBilling,
    required this.onOpenSettings,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedTimeframe = 'Daily';

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

    final currentRevenue = switch (_selectedTimeframe) {
      'All Time' => metrics.overallRevenue,
      'Monthly' => metrics.monthRevenue,
      'Weekly' => metrics.weekRevenue,
      _ => metrics.todayRevenue,
    };

    final currentExpenses = switch (_selectedTimeframe) {
      'All Time' => metrics.overallExpenseTotal,
      'Monthly' => metrics.monthExpenseTotal,
      'Weekly' => metrics.weekExpenseTotal,
      _ => metrics.todayExpenseTotal,
    };

    final currentProfit = switch (_selectedTimeframe) {
      'All Time' => metrics.overallProfit,
      'Monthly' => metrics.monthlyProfit,
      'Weekly' => metrics.weeklyProfit,
      _ => metrics.netProfitToday,
    };

    final currentOrders = switch (_selectedTimeframe) {
      'All Time' => metrics.overallOrderCount,
      'Monthly' => metrics.monthOrderCount,
      'Weekly' => metrics.weekOrderCount,
      _ => metrics.todayOrderCount,
    };

    final chartXLabels = switch (_selectedTimeframe) {
      'All Time' => const ['Past', '3 Mo', '2 Mo', 'Last Mo', 'Now'],
      'Monthly' => ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5'],
      'Weekly' => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      _ => const ['12-4A', '4-8A', '8-12P', '12-4P', '4-8P', '8-12A'],
    };

    final chartDataPoints = switch (_selectedTimeframe) {
      'All Time' => metrics.monthlyWeeklyRevenue.isNotEmpty
          ? metrics.monthlyWeeklyRevenue
          : List.filled(5, 0.0),
      'Monthly' => metrics.monthlyWeeklyRevenue.isNotEmpty
          ? metrics.monthlyWeeklyRevenue
          : List.filled(5, 0.0),
      'Weekly' => metrics.currentWeekDailyRevenue.isNotEmpty
          ? metrics.currentWeekDailyRevenue
          : List.filled(7, 0.0),
      _ => metrics.hourlyRevenueToday.isNotEmpty
          ? metrics.hourlyRevenueToday
          : List.filled(6, 0.0),
    };

    final double pctChange = switch (_selectedTimeframe) {
      'Monthly' => metrics.previousMonthRevenue > 0
          ? ((metrics.monthRevenue - metrics.previousMonthRevenue) / metrics.previousMonthRevenue * 100)
          : 0.0,
      'Weekly' => metrics.previousWeekRevenue > 0
          ? ((metrics.weekRevenue - metrics.previousWeekRevenue) / metrics.previousWeekRevenue * 100)
          : 0.0,
      'Daily' => metrics.yesterdayRevenue > 0
          ? ((metrics.todayRevenue - metrics.yesterdayRevenue) / metrics.yesterdayRevenue * 100)
          : 0.0,
      _ => 0.0,
    };

    // Calculate profit margin percentage
    final double profitMargin = currentRevenue > 0
        ? ((currentProfit / currentRevenue) * 100).clamp(-100.0, 100.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings?.businessName ?? 'FoodBillX',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Business & Financial Reports',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF Report',
            onPressed: () => _exportPdf(metrics, settings?.businessName),
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
        child: metrics.isLoading
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    MetricCardSkeleton(),
                    SizedBox(height: 12),
                    MetricCardSkeleton(),
                    SizedBox(height: 20),
                    SkeletonLoader(width: double.infinity, height: 220),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeframe Filter Bar
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: ['Daily', 'Weekly', 'Monthly', 'All Time'].map((period) {
                          final isSelected = _selectedTimeframe == period;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTimeframe = period),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  period,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 1: Executive P&L Overview Cards
                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: '$_selectedTimeframe Revenue',
                            value: CurrencyFormatter.format(currentRevenue),
                            icon: Icons.payments_rounded,
                            color: AppColors.secondary,
                            subtitle: '$currentOrders orders completed',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: '$_selectedTimeframe Expenses',
                            value: CurrencyFormatter.format(currentExpenses),
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.red.shade400,
                            subtitle: currentExpenses > 0 ? 'Recorded costs' : '₹0 recorded',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: '$_selectedTimeframe Profit',
                            value: currentExpenses > 0
                                ? CurrencyFormatter.format(currentProfit)
                                : 'Add expense',
                            icon: currentExpenses > 0
                                ? Icons.trending_up_rounded
                                : Icons.info_outline_rounded,
                            color: currentExpenses > 0
                                ? (currentProfit >= 0 ? AppColors.secondary : Colors.red)
                                : Colors.amber.shade700,
                            subtitle: currentExpenses > 0
                                ? 'Margin: ${profitMargin.toStringAsFixed(1)}%'
                                : 'to know profit',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: 'Avg Order Value',
                            value: CurrencyFormatter.format(
                              currentOrders > 0 ? (currentRevenue / currentOrders) : 0.0,
                            ),
                            icon: Icons.receipt_long_rounded,
                            color: Colors.blue.shade600,
                            subtitle: 'Per order ticket',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Sales & Revenue Trends Chart
                    _buildSectionHeader('1. Sales & Revenue Trends'),
                    const SizedBox(height: 8),

                    RevenueLineChartWidget(
                      title: '$_selectedTimeframe Revenue Breakdown',
                      totalRevenue: currentRevenue,
                      totalProfit: currentProfit,
                      expenseAmount: currentExpenses,
                      percentageChange: pctChange,
                      percentageSubtitle: _selectedTimeframe == 'Daily'
                          ? 'vs yesterday'
                          : (_selectedTimeframe == 'Weekly'
                              ? 'vs prior week'
                              : (_selectedTimeframe == 'Monthly' ? 'vs prior month' : '')),
                      xLabels: chartXLabels,
                      dataPoints: chartDataPoints,
                    ),
                    const SizedBox(height: 12),

                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSummaryRow('Gross Revenue', CurrencyFormatter.format(currentRevenue)),
                            const Divider(height: 16),
                            _buildSummaryRow('Total Orders', '$currentOrders orders'),
                            const Divider(height: 16),
                            _buildSummaryRow('Operating Expenses', CurrencyFormatter.format(currentExpenses)),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Net Profit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                ProfitDisplayWidget(
                                  expenseAmount: currentExpenses,
                                  profitAmount: currentProfit,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            if (currentRevenue > 0 && currentExpenses > 0) ...[
                              const Divider(height: 16),
                              _buildSummaryRow('Net Profit Margin', '${profitMargin.toStringAsFixed(1)}%'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Order Analytics & Operational Insights
                    _buildSectionHeader('2. Order & Peak Hours Analytics'),
                    const SizedBox(height: 8),

                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Total Completed Orders',
                              '${metrics.overallOrderCount} orders',
                              Icons.shopping_cart_rounded,
                              Colors.blue.shade600,
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              'Peak Selling Hour',
                              metrics.peakSellingHour,
                              Icons.access_time_filled_rounded,
                              Colors.amber.shade800,
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              'All-Time Average Bill',
                              CurrencyFormatter.format(metrics.averageBillValue),
                              Icons.analytics_rounded,
                              AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Menu Dish Performance
                    _buildSectionHeader('3. Menu Dish Performance'),
                    const SizedBox(height: 8),

                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Top 5 Selling Dishes',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 10),
                            if (metrics.topSellingItems.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu_rounded,
                                        size: 36,
                                        color: isDark ? Colors.white24 : Colors.black26,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No sales data yet.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Billed menu items will be ranked here',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: metrics.topSellingItems.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final item = entry.value;
                                  final name = item['_id']?.toString() ?? 'Dish';
                                  final qty = item['totalQuantity'] ?? 0;
                                  final sales = (item['totalSales'] as num?)?.toDouble() ?? 0.0;
                                  final isLast = idx == metrics.topSellingItems.length - 1;

                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: idx == 0
                                              ? Colors.amber.withAlpha(40)
                                              : (idx == 1
                                                  ? Colors.grey.withAlpha(40)
                                                  : Colors.orange.withAlpha(20)),
                                          child: Text(
                                            '#${idx + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: idx == 0
                                                  ? Colors.amber.shade800
                                                  : (idx == 1
                                                      ? Colors.grey.shade400
                                                      : Colors.orange.shade800),
                                            ),
                                          ),
                                        ),
                                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('$qty units sold'),
                                        trailing: Text(
                                          CurrencyFormatter.format(sales),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                      if (!isLast) const Divider(height: 8),
                                    ],
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 5: Payment Breakdown
                    _buildSectionHeader('4. Payment Methods Breakdown'),
                    const SizedBox(height: 8),

                    _buildPaymentBreakdownCard(metrics, isDark),

                    const SizedBox(height: 24),

                    // Section 6: Customer & Loyalty Analytics
                    _buildSectionHeader('5. Customer & Loyalty Analytics'),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: 'Total Registered',
                            value: '${metrics.customerAnalytics['totalCustomers'] ?? 0}',
                            icon: Icons.people_rounded,
                            color: Colors.purple,
                            subtitle: 'Guest database',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: 'Loyalty Members',
                            value: '${metrics.customerAnalytics['loyaltyMembers'] ?? 0}',
                            icon: Icons.card_membership_rounded,
                            color: Colors.amber.shade800,
                            subtitle: 'Cardholders',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: 'Returning Guests',
                            value: '${metrics.customerAnalytics['returningCustomers'] ?? 0}',
                            icon: Icons.repeat_rounded,
                            color: Colors.blue,
                            subtitle: '>1 Visit recorded',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: 'Rewards Claimed',
                            value: '${metrics.customerAnalytics['rewardsRedeemed'] ?? 0}',
                            icon: Icons.stars_rounded,
                            color: Colors.green,
                            subtitle: 'Free rewards issued',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 7: Export Official PDF Report Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _exportPdf(metrics, settings?.businessName),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                        label: const Text(
                          'Export Official PDF Report',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _exportPdf(DashboardState metrics, String? businessName) async {
    try {
      await ReportExportHelper.exportReportToPdf(
        metrics,
        businessName ?? 'FoodBillX',
      );
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to export PDF report');
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdownCard(DashboardState metrics, bool isDark) {
    final cash = (metrics.paymentAnalytics['cash'] as num?)?.toDouble() ?? 0.0;
    final upi = (metrics.paymentAnalytics['upi'] as num?)?.toDouble() ?? 0.0;
    final card = (metrics.paymentAnalytics['card'] as num?)?.toDouble() ?? 0.0;
    final total = cash + upi + card;

    final cashPct = total > 0 ? (cash / total) : 0.0;
    final upiPct = total > 0 ? (upi / total) : 0.0;
    final cardPct = total > 0 ? (card / total) : 0.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Distribution Progress Bar
            if (total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      if (cashPct > 0)
                        Expanded(flex: (cashPct * 100).toInt(), child: Container(color: Colors.green)),
                      if (upiPct > 0)
                        Expanded(flex: (upiPct * 100).toInt(), child: Container(color: Colors.blue)),
                      if (cardPct > 0)
                        Expanded(flex: (cardPct * 100).toInt(), child: Container(color: Colors.purple)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildPaymentMethodRow('Cash Payments', cash, cashPct, Icons.money_rounded, Colors.green),
            const Divider(height: 16),
            _buildPaymentMethodRow('UPI / QR Payments', upi, upiPct, Icons.qr_code_2_rounded, Colors.blue),
            const Divider(height: 16),
            _buildPaymentMethodRow('Card Payments', card, cardPct, Icons.credit_card_rounded, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodRow(
    String label,
    double amount,
    double pct,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withAlpha(25),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (pct > 0)
                Text(
                  '${(pct * 100).toStringAsFixed(1)}% of total sales',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }
}
