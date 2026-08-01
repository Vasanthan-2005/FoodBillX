import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/metric_card_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/empty_state_widget.dart';
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
    final dashboardState = ref.watch(dashboardProvider);
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
              'Commercial POS Insights & Analytics',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Insights',
            onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: dashboardState.isLoading
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
                    if (dashboardState.errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                dashboardState.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(dashboardProvider.notifier)
                                  .refresh(forceSpinner: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    // Timeframe Segmented Switcher
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['Daily', 'Weekly', 'Monthly'].map((
                                period,
                              ) {
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
                                    onSelected: (_) {
                                      setState(
                                        () => _selectedTimeframe = period,
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: widget.onGoToBilling,
                          icon: const Icon(
                            Icons.point_of_sale_rounded,
                            size: 18,
                          ),
                          label: const Text('POS Bill'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Top Metrics Cards
                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: "$_selectedTimeframe Sales",
                            value: CurrencyFormatter.format(
                              switch (_selectedTimeframe) {
                                'Monthly' => dashboardState.monthRevenue,
                                'Weekly' => dashboardState.weekRevenue,
                                _ => dashboardState.todayRevenue,
                              },
                            ),
                            icon: Icons.payments_rounded,
                            color: AppColors.secondary,
                            subtitle: "Revenue",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: "$_selectedTimeframe Orders",
                            value:
                                '${switch (_selectedTimeframe) {
                                  'Monthly' => dashboardState.monthOrderCount,
                                  'Weekly' => dashboardState.weekOrderCount,
                                  _ => dashboardState.todayOrderCount,
                                }}',
                            icon: Icons.receipt_long_rounded,
                            color: AppColors.primary,
                            subtitle: "Volume",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCardWidget(
                            title: "Today's Expenses",
                            value: CurrencyFormatter.format(
                              dashboardState.todayExpenseTotal,
                            ),
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.red.shade400,
                            subtitle: "Costs",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCardWidget(
                            title: "Today's Net Profit",
                            value: CurrencyFormatter.format(
                              dashboardState.netProfitToday,
                            ),
                            icon: Icons.trending_up_rounded,
                            color: dashboardState.netProfitToday >= 0
                                ? AppColors.secondary
                                : Colors.red,
                            subtitle: dashboardState.netProfitToday >= 0
                                ? "Gain"
                                : "Loss",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (dashboardState.todayOrderCount == 0 &&
                        dashboardState.monthRevenue == 0 &&
                        dashboardState.todayExpenseTotal == 0)
                      EmptyStateWidget(
                        iconEmoji: '📈',
                        title: 'Start selling to view analytics',
                        description:
                            'Create your first POS order to unlock live revenue, expense, and profit charts.',
                        actionLabel: 'Open POS Billing',
                        onActionPressed: widget.onGoToBilling,
                      )
                    else ...[
                      // Sales Trend Line Chart Card
                      _buildChartCard(
                        context,
                        title: 'Recent Sales Trend',
                        subtitle:
                            'Local revenue totals for the last seven days',
                        child: SizedBox(
                          height: 180,
                          child: CustomPaint(
                            painter: SalesTrendPainter(
                              isDark: isDark,
                              primaryColor: AppColors.primary,
                              accentColor: AppColors.secondary,
                              values: dashboardState.recentDailyRevenue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Expenses vs Revenue Bar Chart
                      _buildChartCard(
                        context,
                        title: 'Expenses vs Revenue',
                        subtitle:
                            'Operational costs compared to gross billing income',
                        child: SizedBox(
                          height: 180,
                          child: CustomPaint(
                            painter: RevenueExpenseBarPainter(
                              revenue: dashboardState.todayRevenue,
                              expense: dashboardState.todayExpenseTotal,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Top Selling Items Section
                      Text(
                        "Top Selling Dishes This Month",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      dashboardState.topSellingItems.isEmpty
                          ? const Card(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(
                                  child: Text(
                                    'No item sales recorded yet this month',
                                  ),
                                ),
                              ),
                            )
                          : Card(
                              child: Column(
                                children: dashboardState.topSellingItems.map((
                                  item,
                                ) {
                                  final name = item['_id'] ?? 'Dish';
                                  final qty = item['totalQuantity'] ?? 0;
                                  final sales =
                                      (item['totalSales'] as num?)
                                          ?.toDouble() ??
                                      0.0;

                                  return ListTile(
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(30),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '🍔',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text('$qty orders sold'),
                                    trailing: Text(
                                      CurrencyFormatter.format(sales),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ).animate().fadeIn(duration: 400.ms),
                    ],
                  ],
                ),
              ),
      ),
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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
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

    // Draw background grid lines
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

    // Fill Gradient under curve
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

    // Stroke line
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw Data Point Circles
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

// Custom Painter for Revenue vs Expenses Bar Chart
class RevenueExpenseBarPainter extends CustomPainter {
  final double revenue;
  final double expense;
  final bool isDark;

  RevenueExpenseBarPainter({
    required this.revenue,
    required this.expense,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = math.max(revenue, expense) * 1.2;
    if (maxVal == 0) return;

    final revHeight = (revenue / maxVal) * size.height;
    final expHeight = (expense / maxVal) * size.height;

    final barWidth = size.width * 0.28;
    final revX = size.width * 0.2;
    final expX = size.width * 0.52;

    // Revenue Bar
    final revRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(revX, size.height - revHeight, barWidth, revHeight),
      const Radius.circular(8),
    );
    final revPaint = Paint()..color = AppColors.secondary;
    canvas.drawRRect(revRect, revPaint);

    // Expense Bar
    final expRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(expX, size.height - expHeight, barWidth, expHeight),
      const Radius.circular(8),
    );
    final expPaint = Paint()..color = Colors.red.shade400;
    canvas.drawRRect(expRect, expPaint);
  }

  @override
  bool shouldRepaint(covariant RevenueExpenseBarPainter oldDelegate) =>
      oldDelegate.revenue != revenue ||
      oldDelegate.expense != expense ||
      oldDelegate.isDark != isDark;
}
