import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/report_export_helper.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/metric_card_widget.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            value: CurrencyFormatter.format(
                              switch (_selectedTimeframe) {
                                'Monthly' => metrics.monthRevenue,
                                'Weekly' => metrics.weekRevenue,
                                _ => metrics.todayRevenue,
                              },
                            ),
                            icon: Icons.payments_rounded,
                            color: AppColors.secondary,
                            subtitle: "Gross Sales",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: "$_selectedTimeframe Expenses",
                            value: CurrencyFormatter.format(
                              switch (_selectedTimeframe) {
                                'Monthly' => metrics.monthExpenseTotal,
                                'Weekly' => metrics.weekExpenseTotal,
                                _ => metrics.todayExpenseTotal,
                              },
                            ),
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
                            value: CurrencyFormatter.format(
                              switch (_selectedTimeframe) {
                                'Monthly' => metrics.monthlyProfit,
                                'Weekly' => metrics.weeklyProfit,
                                _ => metrics.netProfitToday,
                              },
                            ),
                            icon: Icons.trending_up_rounded,
                            color: (switch (_selectedTimeframe) {
                                      'Monthly' => metrics.monthlyProfit,
                                      'Weekly' => metrics.weeklyProfit,
                                      _ => metrics.netProfitToday,
                                    }) >= 0
                                ? AppColors.secondary
                                : Colors.red,
                            subtitle: "Revenue - Expenses",
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

                    // Section 2: Sales Trends Chart
                    _buildSectionHeader(context, '2. Sales & Revenue Trends'),
                    const SizedBox(height: 8),

                    _buildChartCard(
                      context,
                      title: '7-Day Revenue Trend',
                      subtitle: 'Daily gross revenue comparison',
                      child: SizedBox(
                        height: 180,
                        child: CustomPaint(
                          painter: SalesTrendPainter(
                            isDark: isDark,
                            primaryColor: AppColors.primary,
                            accentColor: AppColors.secondary,
                            values: metrics.recentDailyRevenue,
                          ),
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

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// Custom Painter for Sales Trend Line Chart
class SalesTrendPainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;
  final Color accentColor;
  final List<double> values;

  SalesTrendPainter({
    required this.isDark,
    required this.primaryColor,
    required this.accentColor,
    required this.values,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..strokeWidth = 1;

    for (double i = 0; i <= size.height; i += size.height / 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    if (values.isEmpty) return;
    final maxValue = values.reduce(math.max);
    final divisor = maxValue <= 0 ? 1.0 : maxValue;
    final step = values.length == 1 ? 0.0 : size.width / (values.length - 1);
    final dataPoints = List<Offset>.generate(values.length, (index) {
      final normalized = values[index] / divisor;
      return Offset(index * step, size.height * (1 - normalized * 0.85));
    });

    final path = Path()..moveTo(dataPoints[0].dx, dataPoints[0].dy);
    for (int i = 1; i < dataPoints.length; i++) {
      final p0 = dataPoints[i - 1];
      final p1 = dataPoints[i];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor.withAlpha(100), primaryColor.withAlpha(0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final p in dataPoints) {
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SalesTrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.isDark != isDark;
}
