import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/report_export_helper.dart';
import '../../core/utils/snackbar_utils.dart';
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
  Widget build(BuildContext context) {
    final metrics = ref.watch(dashboardProvider);
    final settings = ref.watch(settingsProvider).settings;

    final currentRevenue = switch (_selectedTimeframe) {
      'Monthly' => metrics.monthRevenue,
      'Weekly' => metrics.weekRevenue,
      _ => metrics.todayRevenue,
    };

    final currentExpenses = switch (_selectedTimeframe) {
      'Monthly' => metrics.monthExpenseTotal,
      'Weekly' => metrics.weekExpenseTotal,
      _ => metrics.todayExpenseTotal,
    };

    final currentProfit = switch (_selectedTimeframe) {
      'Monthly' => metrics.monthlyProfit,
      'Weekly' => metrics.weeklyProfit,
      _ => metrics.netProfitToday,
    };

    final currentOrders = switch (_selectedTimeframe) {
      'Monthly' => metrics.monthOrderCount,
      'Weekly' => metrics.weekOrderCount,
      _ => metrics.todayOrderCount,
    };

    final chartXLabels = switch (_selectedTimeframe) {
      'Monthly' => ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5'],
      'Weekly' => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      _ => ['12 AM', '4 AM', '8 AM', '12 PM', '4 PM', '8 PM'],
    };

    final chartDataPoints = switch (_selectedTimeframe) {
      'Monthly' => metrics.monthlyWeeklyRevenue.isNotEmpty
          ? metrics.monthlyWeeklyRevenue
          : List.filled(5, 0.0),
      'Weekly' => metrics.recentDailyRevenue.isNotEmpty
          ? metrics.recentDailyRevenue
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
      _ => metrics.yesterdayRevenue > 0
          ? ((metrics.todayRevenue - metrics.yesterdayRevenue) / metrics.yesterdayRevenue * 100)
          : 0.0,
    };

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings?.businessName ?? 'HMB Bills',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Restaurant Business & Financial Reports',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF Report',
            onPressed: () async {
              try {
                await ReportExportHelper.exportReportToPdf(
                  metrics,
                  settings?.businessName ?? 'HMB Bills',
                );
              } catch (e) {
                if (context.mounted) {
                  SnackbarUtils.showError(context, 'Failed to export PDF report');
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Reports',
            onPressed: () => ref.read(dashboardProvider.notifier).refresh(forceSpinner: true),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Section 1: Revenue & Profit KPI Cards
                    Text(
                      '1. Profit & Loss Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Timeframe Switcher
                    Row(
                      children: ['Daily', 'Weekly', 'Monthly'].map((period) {
                        final isSelected = _selectedTimeframe == period;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(period),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setState(() => _selectedTimeframe = period),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: "$_selectedTimeframe Revenue",
                            value: CurrencyFormatter.format(currentRevenue),
                            icon: Icons.payments_rounded,
                            color: AppColors.secondary,
                            subtitle: "Gross Sales",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: "$_selectedTimeframe Expenses",
                            value: CurrencyFormatter.format(currentExpenses),
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.red.shade400,
                            subtitle: "Operational Costs",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: "$_selectedTimeframe Net Profit",
                            value: currentExpenses <= 0
                                ? 'Log expenses'
                                : CurrencyFormatter.format(currentProfit),
                            icon: Icons.trending_up_rounded,
                            color: currentExpenses <= 0
                                ? Colors.orange.shade800
                                : (currentProfit >= 0 ? AppColors.secondary : Colors.red),
                            subtitle: currentExpenses <= 0
                                ? 'Log expenses to see profit'
                                : 'Revenue - Expenses',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: "Average Bill Value",
                            value: CurrencyFormatter.format(metrics.averageBillValue),
                            icon: Icons.receipt_long_rounded,
                            color: Colors.blue.shade600,
                            subtitle: "Per Customer Order",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Sales Trends Chart (Dynamic X-Axis)
                    _buildSectionHeader(context, '2. Sales & Revenue Trends'),
                    const SizedBox(height: 8),

                    RevenueLineChartWidget(
                      title: 'Revenue Overview',
                      totalRevenue: currentRevenue,
                      percentageChange: pctChange,
                      percentageSubtitle: '',
                      xLabels: chartXLabels,
                      dataPoints: chartDataPoints,
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSummaryRow('Total Sales', CurrencyFormatter.format(currentRevenue)),
                            const Divider(height: 16),
                            _buildSummaryRow('Orders', '$currentOrders orders'),
                            const Divider(height: 16),
                            _buildSummaryRow('Expenses', CurrencyFormatter.format(currentExpenses)),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Profit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                ProfitDisplayWidget(
                                  expenseAmount: currentExpenses,
                                  profitAmount: currentProfit,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Orders & Operational KPIs
                    _buildSectionHeader(context, '3. Order Analytics & Operational Insights'),
                    const SizedBox(height: 8),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow('Total Completed Orders', '${metrics.overallOrderCount} orders', Icons.shopping_cart_rounded),
                            const Divider(height: 20),
                            _buildInfoRow('Peak Selling Hour', metrics.peakSellingHour, Icons.access_time_filled_rounded),
                            const Divider(height: 20),
                            _buildInfoRow('Average Bill Order Value', CurrencyFormatter.format(metrics.averageBillValue), Icons.analytics_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Menu Dish Performance (Best & Least Selling)
                    _buildSectionHeader(context, '4. Menu Dish Performance'),
                    const SizedBox(height: 8),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Top 5 Best Selling Dishes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 10),
                            if (metrics.topSellingItems.isEmpty)
                              const Text('No item sales recorded yet.', style: TextStyle(color: Colors.grey))
                            else
                              Column(
                                children: metrics.topSellingItems.map((item) {
                                  final name = item['_id']?.toString() ?? 'Dish';
                                  final qty = item['totalQuantity'] ?? 0;
                                  final sales = (item['totalSales'] as num?)?.toDouble() ?? 0.0;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const CircleAvatar(
                                      child: Text('🔥', style: TextStyle(fontSize: 16)),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('$qty units sold'),
                                    trailing: Text(CurrencyFormatter.format(sales), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 5: Customer & Loyalty Analytics
                    _buildSectionHeader(context, '5. Customer & Loyalty Analytics'),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: "Total Registered",
                            value: '${metrics.customerAnalytics['totalCustomers'] ?? 0}',
                            icon: Icons.people_rounded,
                            color: Colors.purple,
                            subtitle: "Total Guests",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: "Loyalty Members",
                            value: '${metrics.customerAnalytics['loyaltyMembers'] ?? 0}',
                            icon: Icons.card_membership_rounded,
                            color: Colors.amber.shade800,
                            subtitle: "With Loyalty Card",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: "Returning Guests",
                            value: '${metrics.customerAnalytics['returningCustomers'] ?? 0}',
                            icon: Icons.repeat_rounded,
                            color: Colors.blue,
                            subtitle: ">1 Visit",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: "Rewards Redeemed",
                            value: '${metrics.customerAnalytics['rewardsRedeemed'] ?? 0}',
                            icon: Icons.stars_rounded,
                            color: Colors.green,
                            subtitle: "Freebies Claimed",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 6: Payment Methods Breakdown
                    _buildSectionHeader(context, '6. Payment Breakdown'),
                    const SizedBox(height: 8),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildPaymentRow('Cash Payments', (metrics.paymentAnalytics['cash'] as num?)?.toDouble() ?? 0.0, Icons.money_rounded, Colors.green),
                            const Divider(height: 20),
                            _buildPaymentRow('UPI / QR Payments', (metrics.paymentAnalytics['upi'] as num?)?.toDouble() ?? 0.0, Icons.qr_code_2_rounded, Colors.blue),
                            const Divider(height: 20),
                            _buildPaymentRow('Card Payments', (metrics.paymentAnalytics['card'] as num?)?.toDouble() ?? 0.0, Icons.credit_card_rounded, Colors.purple),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildPaymentRow(String label, double amount, IconData icon, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withAlpha(30),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        Text(CurrencyFormatter.format(amount), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
      ],
    );
  }
}
