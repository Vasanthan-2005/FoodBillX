import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/currency_formatter.dart';

import '../widgets/profit_display_widget.dart';

class RevenueLineChartWidget extends StatelessWidget {
  final String title;
  final double totalRevenue;
  final double? totalProfit;
  final double? expenseAmount;
  final double percentageChange;
  final String percentageSubtitle;
  final List<String> xLabels;
  final List<double> dataPoints;
  final Color? lineColor;

  const RevenueLineChartWidget({
    super.key,
    required this.title,
    required this.totalRevenue,
    this.totalProfit,
    this.expenseAmount,
    required this.percentageChange,
    required this.percentageSubtitle,
    required this.xLabels,
    required this.dataPoints,
    this.lineColor,
  });

  String _formatYLabel(double val) {
    if (val <= 0) return '0';
    if (val >= 100000) {
      return '${(val / 100000).toStringAsFixed(1)}L';
    }
    if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}K';
    }
    return val.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryLineColor = lineColor ?? AppColors.primary;

    final values = dataPoints.isEmpty ? [0.0] : dataPoints;
    final maxY = values.fold<double>(100.0, (m, v) => math.max(m, v)) * 1.15;
    final isPositivePct = percentageChange >= 0;

    final spots = List<FlSpot>.generate(values.length, (i) {
      return FlSpot(i.toDouble(), values[i]);
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Title on Left, Revenue/Profit on Right if provided)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                if (totalProfit != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Profit',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      ProfitDisplayWidget(
                        expenseAmount: expenseAmount ?? 0,
                        profitAmount: totalProfit!,
                        showPercentBadge: false,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Revenue Amount + % Change Pill Badge
            Row(
              children: [
                Text(
                  CurrencyFormatter.format(totalRevenue),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (percentageChange != 0.0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPositivePct ? Colors.green : Colors.red)
                          .withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isPositivePct ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPositivePct
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                        if (percentageSubtitle.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            percentageSubtitle,
                            style: TextStyle(
                              fontSize: 10,
                              color: isPositivePct
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Line Chart
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (values.length - 1).toDouble().clamp(0, 100),
                  minY: 0,
                  maxY: maxY <= 0 ? 100 : maxY,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF0F172A),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final xLabel = (idx >= 0 && idx < xLabels.length)
                              ? xLabels[idx]
                              : '';
                          return LineTooltipItem(
                            '$xLabel\n${CurrencyFormatter.format(spot.y)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 4) <= 0 ? 25 : (maxY / 4),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.white10 : Colors.black12,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: (maxY / 4) <= 0 ? 25 : (maxY / 4),
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            _formatYLabel(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= xLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              xLabels[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      barWidth: 3.5,
                      color: primaryLineColor,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: primaryLineColor,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            primaryLineColor.withAlpha(90),
                            primaryLineColor.withAlpha(5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
