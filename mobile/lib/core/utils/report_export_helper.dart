import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../models/business_settings_model.dart';
import '../../models/category_model.dart';
import '../../models/customer_model.dart';
import '../../models/expense_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/order_model.dart';
import '../../providers/dashboard_provider.dart';
import '../storage/local_database.dart';

enum ExportFormat {
  excel,
  pdf,
}

class ReportExportHelper {
  // ─────────────────────────────────────────────────────────────────
  // Formatting Utilities
  // ─────────────────────────────────────────────────────────────────
  static String _formatIndianInt(String rawDigits) {
    if (rawDigits.length <= 3) return rawDigits;
    final lastThree = rawDigits.substring(rawDigits.length - 3);
    final remaining = rawDigits.substring(0, rawDigits.length - 3);
    final formattedLeading = remaining.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (Match _) => ',',
    );
    return '$formattedLeading,$lastThree';
  }

  static String _formatPdfCurrency(double amount, [String currency = 'Rs. ']) {
    final isNeg = amount < 0;
    final parts = amount.abs().toStringAsFixed(2).split('.');
    final intPart = _formatIndianInt(parts[0]);
    return '${isNeg ? '-' : ''}$currency$intPart.${parts[1]}';
  }

  static String _formatPdfProfit(double profit, double expenses, [String currency = 'Rs. ']) {
    if (expenses <= 0) return 'Add expense';
    return _formatPdfCurrency(profit, currency);
  }

  // ─────────────────────────────────────────────────────────────────
  // Gorgeous Executive PDF Components
  // ─────────────────────────────────────────────────────────────────
  static final _pdfPrimary = PdfColor.fromInt(0xFF1E293B); // Slate Navy
  static final _pdfAccent = PdfColor.fromInt(0xFFD97706); // Warm Amber/Gold
  static final _pdfBgSubtle = PdfColor.fromInt(0xFFF8FAFC);
  static final _pdfBorder = PdfColor.fromInt(0xFFE2E8F0);
  static final _pdfTextDark = PdfColor.fromInt(0xFF0F172A);
  static final _pdfTextMuted = PdfColor.fromInt(0xFF64748B);

  static pw.Widget _buildPdfHeader({
    required String title,
    required String subtitle,
    required String businessName,
    BusinessSettingsModel? settings,
    String? dateRangeLabel,
  }) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(now);
    final phone = settings?.phone ?? '';
    final address = settings?.address ?? '';

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        color: _pdfPrimary,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  businessName.isNotEmpty ? businessName : 'HMB Bills',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: _pdfAccent,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        title.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        subtitle,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey300),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                if (dateRangeLabel != null && dateRangeLabel.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blueGrey800,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Text(
                      'TIMEFRAME: ${dateRangeLabel.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
                if (address.isNotEmpty || phone.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    [
                      if (address.isNotEmpty) address,
                      if (phone.isNotEmpty) 'Ph: $phone',
                    ].join(' • '),
                    style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey400),
                  ),
                ],
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF334155),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'GENERATED ON',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey400),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      dateStr,
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'FoodBillX Restaurant POS Engine • Official Financial Record',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12, bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 14,
            decoration: pw.BoxDecoration(
              color: _pdfAccent,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _pdfPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfKpiTile(String title, String value, String subtitle, PdfColor accentColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        margin: const pw.EdgeInsets.only(right: 6),
        decoration: pw.BoxDecoration(
          color: _pdfBgSubtle,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: _pdfBorder, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 3),
            pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                value,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: accentColor),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // 1. BUSINESS REPORTS EXPORT (PDF WITH CHARTS & Excel)
  // ─────────────────────────────────────────────────────────────────
  static Future<void> exportReport({
    required DashboardState metrics,
    required String businessName,
    required ExportFormat format,
    BusinessSettingsModel? settings,
    String? dateRangeLabel,
    bool isPeriodSlice = false,
    List<String>? chartLabels,
  }) async {
    if (format == ExportFormat.pdf) {
      await _exportReportToPdf(
        metrics,
        businessName,
        settings,
        dateRangeLabel,
        isPeriodSlice,
        chartLabels,
      );
    } else {
      await _exportReportToExcel(metrics, businessName, dateRangeLabel, isPeriodSlice);
    }
  }

  static Future<void> exportReportToPdf(
    DashboardState metrics,
    String businessName, [
    BusinessSettingsModel? settings,
    String? dateRangeLabel,
    bool isPeriodSlice = false,
    List<String>? chartLabels,
  ]) =>
      exportReport(
        metrics: metrics,
        businessName: businessName,
        format: ExportFormat.pdf,
        settings: settings,
        dateRangeLabel: dateRangeLabel,
        isPeriodSlice: isPeriodSlice,
        chartLabels: chartLabels,
      );

  static Future<void> exportReportToExcel(
    DashboardState metrics,
    String businessName, [
    String? dateRangeLabel,
    bool isPeriodSlice = false,
  ]) =>
      exportReport(
        metrics: metrics,
        businessName: businessName,
        format: ExportFormat.excel,
        dateRangeLabel: dateRangeLabel,
        isPeriodSlice: isPeriodSlice,
      );

  static String _formatCompactAxis(double val) {
    if (val <= 0) return '0';
    if (val >= 10000000) {
      final cr = val / 10000000;
      return '${cr >= 10 ? cr.toStringAsFixed(0) : cr.toStringAsFixed(1)}Cr';
    }
    if (val >= 100000) {
      final l = val / 100000;
      return '${l >= 10 ? l.toStringAsFixed(0) : l.toStringAsFixed(1)}L';
    }
    if (val >= 1000) {
      final k = val / 1000;
      return '${k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}K';
    }
    return val.toStringAsFixed(0);
  }

  static pw.Widget _buildPdfRevenueTrendChart(
    List<double> rawValues,
    List<String> rawLabels,
  ) {
    final values = rawValues.isEmpty ? [0.0] : rawValues;
    final maxVal = values.fold<double>(0.0, (m, v) => v > m ? v : m);
    final safeMax = maxVal <= 0 ? 100.0 : maxVal * 1.15;
    final hasData = values.any((v) => v > 0);
    final peakVal = maxVal;
    final peakIdx = hasData ? values.indexOf(peakVal) : 0;
    final peakLabel = (peakIdx >= 0 && peakIdx < rawLabels.length) ? rawLabels[peakIdx] : '';

    final effectiveLabels = rawLabels.length == values.length
        ? rawLabels
        : List<String>.generate(values.length, (i) => '${i + 1}');

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _pdfBgSubtle,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _pdfBorder, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Sales Trend Graph',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfPrimary,
                ),
              ),
              if (hasData)
                pw.Text(
                  'Peak: ${_formatPdfCurrency(peakVal)}${peakLabel.isNotEmpty ? ' ($peakLabel)' : ''}',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _pdfAccent,
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                width: 36,
                height: 112,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(_formatCompactAxis(safeMax), style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    pw.Text(_formatCompactAxis(safeMax * 0.5), style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    pw.Text('0', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                  ],
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.SizedBox(
                      height: 112,
                      width: double.infinity,
                      child: pw.CustomPaint(
                        painter: (PdfGraphics canvas, PdfPoint size) {
                          const padH = 8.0;
                          const padV = 6.0;
                          final w = size.x - padH * 2;
                          final h = size.y - padV * 2;

                          // Gridlines (top, mid, bottom)
                          canvas
                            ..setStrokeColor(_pdfBorder)
                            ..setLineWidth(0.6);
                          for (final t in [0.0, 0.5, 1.0]) {
                            final gy = padV + h * t;
                            canvas.drawLine(padH, gy, padH + w, gy);
                          }
                          canvas.strokePath();

                          if (!hasData || values.isEmpty) return;

                          final points = <PdfPoint>[];
                          if (values.length == 1) {
                            final y = padV + (values[0] / safeMax).clamp(0.0, 1.0) * h;
                            points.add(PdfPoint(padH + w * 0.5, y));
                          } else {
                            for (int i = 0; i < values.length; i++) {
                              final x = padH + (i / (values.length - 1)) * w;
                              final y = padV + (values[i] / safeMax).clamp(0.0, 1.0) * h;
                              points.add(PdfPoint(x, y));
                            }
                          }

                          // Vertical subtle bars beneath each point for easy visual reading
                          final barWidth = values.length > 1
                              ? (w / values.length * 0.42).clamp(4.0, 18.0)
                              : 16.0;
                          canvas.setFillColor(PdfColor.fromInt(0x28FF6D00));
                          for (final pt in points) {
                            final bh = pt.y - padV;
                            if (bh > 0.5) {
                              canvas.drawRect(pt.x - barWidth / 2, padV, barWidth, bh);
                            }
                          }
                          canvas.fillPath();

                          // Trend line connecting points
                          if (points.length >= 2) {
                            canvas
                              ..setStrokeColor(_pdfAccent)
                              ..setLineWidth(2.0);
                            canvas.moveTo(points.first.x, points.first.y);
                            for (int i = 1; i < points.length; i++) {
                              canvas.lineTo(points[i].x, points[i].y);
                            }
                            canvas.strokePath();
                          }

                          // Point markers
                          for (final pt in points) {
                            canvas
                              ..setFillColor(_pdfAccent)
                              ..drawEllipse(pt.x, pt.y, 3.2, 3.2)
                              ..fillPath();
                            canvas
                              ..setFillColor(PdfColors.white)
                              ..drawEllipse(pt.x, pt.y, 1.5, 1.5)
                              ..fillPath();
                          }
                        },
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: effectiveLabels
                          .map(
                            (lbl) => pw.Expanded(
                              child: pw.Text(
                                lbl,
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfDistributionBar(
    List<({String label, double value, PdfColor color})> segments,
  ) {
    final total = segments.fold<double>(0.0, (s, e) => s + e.value);
    if (total <= 0) {
      return pw.Text('No transactions recorded in this period.', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.ClipRRect(
          horizontalRadius: 4,
          verticalRadius: 4,
          child: pw.SizedBox(
            height: 10,
            child: pw.Row(
              children: segments
                  .where((s) => s.value > 0)
                  .map(
                    (s) => pw.Expanded(
                      flex: ((s.value / total) * 1000).round().clamp(1, 1000),
                      child: pw.Container(color: s.color),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Wrap(
          spacing: 14,
          runSpacing: 4,
          children: segments
              .where((s) => s.value > 0)
              .map(
                (s) => pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(width: 7, height: 7, color: s.color),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      '${s.label}: ${((s.value / total) * 100).toStringAsFixed(1)}%',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  static Future<void> _exportReportToPdf(
    DashboardState metrics,
    String businessName,
    BusinessSettingsModel? settings, [
    String? dateRangeLabel,
    bool isPeriodSlice = false,
    List<String>? chartLabels,
  ]) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildPdfHeader(
          title: 'Business & Financial Report',
          subtitle: 'Revenue Trends, P&L, Expense Analysis & Dish Performance',
          businessName: businessName,
          settings: settings,
          dateRangeLabel: dateRangeLabel,
        ),
        footer: (ctx) => _buildPdfFooter(ctx),
        build: (pw.Context context) {
          final dishes = metrics.todayDishBreakdown.isNotEmpty
              ? metrics.todayDishBreakdown
              : metrics.topSellingItems;
          final margin = metrics.todayRevenue > 0
              ? ((metrics.netProfitToday / metrics.todayRevenue) * 100).clamp(-100.0, 100.0)
              : 0.0;

          final cash = (metrics.paymentAnalytics['cash'] as num?)?.toDouble() ?? 0.0;
          final upi = (metrics.paymentAnalytics['upi'] as num?)?.toDouble() ?? 0.0;
          final card = (metrics.paymentAnalytics['card'] as num?)?.toDouble() ?? 0.0;
          final wallet = (metrics.paymentAnalytics['wallet'] as num?)?.toDouble() ?? 0.0;
          final payTotal = cash + upi + card + wallet;

          // Resolve trend series & labels for visual chart
          List<double> trendPoints;
          List<String> trendLabels;
          if (isPeriodSlice && metrics.hourlyRevenueToday.isNotEmpty) {
            trendPoints = metrics.hourlyRevenueToday;
            trendLabels = (chartLabels != null && chartLabels.length == trendPoints.length)
                ? chartLabels
                : List<String>.generate(trendPoints.length, (i) => 'P${i + 1}');
          } else if (metrics.recentDailyRevenue.isNotEmpty) {
            trendPoints = metrics.recentDailyRevenue;
            final now = DateTime.now();
            trendLabels = List<String>.generate(trendPoints.length, (i) {
              final d = now.subtract(Duration(days: trendPoints.length - 1 - i));
              return DateFormat('E').format(d);
            });
          } else {
            trendPoints = [
              metrics.todayRevenue,
              metrics.weekRevenue,
              metrics.monthRevenue,
              metrics.overallRevenue,
            ];
            trendLabels = const ['Today', 'Week', 'Month', 'Overall'];
          }

          final totalDishQty = dishes.fold<int>(
            0,
            (s, d) => s + ((d['totalQuantity'] ?? d['quantity'] ?? 0) as num).toInt(),
          );
          final expenseRows = metrics.expenseBreakdown;
          final totalExpForPct = isPeriodSlice
              ? metrics.todayExpenseTotal
              : (expenseRows.fold<double>(
                  0.0,
                  (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0.0),
                ));
          final cust = metrics.customerAnalytics;

          return [
            // KPI Summary Row
            if (isPeriodSlice)
              pw.Row(
                children: [
                  _buildPdfKpiTile('Period Sales', _formatPdfCurrency(metrics.todayRevenue), '${_formatIndianInt('${metrics.todayOrderCount}')} orders billed', _pdfAccent),
                  _buildPdfKpiTile('Expenses', _formatPdfCurrency(metrics.todayExpenseTotal), 'Operating costs', PdfColors.red800),
                  _buildPdfKpiTile('Net Profit', _formatPdfProfit(metrics.netProfitToday, metrics.todayExpenseTotal), metrics.todayExpenseTotal > 0 ? 'Margin: ${margin.toStringAsFixed(1)}%' : 'Revenue - Expenses', PdfColors.green800),
                  _buildPdfKpiTile('Avg Bill Value', _formatPdfCurrency(metrics.averageBillValue), 'Peak: ${metrics.peakSellingHour}', _pdfPrimary),
                ],
              )
            else
              pw.Row(
                children: [
                  _buildPdfKpiTile('Today Sales', _formatPdfCurrency(metrics.todayRevenue), '${_formatIndianInt('${metrics.todayOrderCount}')} orders billed', _pdfAccent),
                  _buildPdfKpiTile('Net Profit Today', _formatPdfProfit(metrics.netProfitToday, metrics.todayExpenseTotal), 'Revenue - Expenses', PdfColors.green800),
                  _buildPdfKpiTile('Month Revenue', _formatPdfCurrency(metrics.monthRevenue), '${_formatIndianInt('${metrics.monthOrderCount}')} monthly orders', PdfColors.blue800),
                  _buildPdfKpiTile('Avg Bill Value', _formatPdfCurrency(metrics.averageBillValue), 'Peak: ${metrics.peakSellingHour}', _pdfPrimary),
                ],
              ),
            pw.SizedBox(height: 12),

            // 1. Visual Trend Graph
            _buildPdfSectionHeader('1. Revenue Trend Overview'),
            _buildPdfRevenueTrendChart(trendPoints, trendLabels),
            pw.SizedBox(height: 12),

            // 2. Profit & Revenue Summary Table
            _buildPdfSectionHeader('2. Profit & Operating Summary'),
            pw.TableHelper.fromTextArray(
              headers: ['Timeframe', 'Gross Revenue', 'Operating Expenses', 'Net Profit'],
              data: isPeriodSlice
                  ? [
                      [
                        dateRangeLabel ?? 'Selected Period',
                        _formatPdfCurrency(metrics.todayRevenue),
                        _formatPdfCurrency(metrics.todayExpenseTotal),
                        _formatPdfProfit(metrics.netProfitToday, metrics.todayExpenseTotal),
                      ],
                    ]
                  : [
                      ['Today', _formatPdfCurrency(metrics.todayRevenue), _formatPdfCurrency(metrics.todayExpenseTotal), _formatPdfProfit(metrics.netProfitToday, metrics.todayExpenseTotal)],
                      ['This Week', _formatPdfCurrency(metrics.weekRevenue), _formatPdfCurrency(metrics.weekExpenseTotal), _formatPdfProfit(metrics.weeklyProfit, metrics.weekExpenseTotal)],
                      ['This Month', _formatPdfCurrency(metrics.monthRevenue), _formatPdfCurrency(metrics.monthExpenseTotal), _formatPdfProfit(metrics.monthlyProfit, metrics.monthExpenseTotal)],
                      ['Overall', _formatPdfCurrency(metrics.overallRevenue), _formatPdfCurrency(metrics.overallExpenseTotal), _formatPdfProfit(metrics.overallProfit, metrics.overallExpenseTotal)],
                    ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: _pdfPrimary),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
            ),
            pw.SizedBox(height: 12),

            // 3. Payment Settlement Breakdown + Visual Stacked Chart
            _buildPdfSectionHeader('3. Payment Methods & Share'),
            _buildPdfDistributionBar([
              (label: 'Cash', value: cash, color: PdfColors.green700),
              (label: 'UPI / QR', value: upi, color: PdfColors.blue700),
              (label: 'Card', value: card, color: PdfColors.purple700),
              (label: 'Wallet', value: wallet, color: PdfColors.amber700),
            ]),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Payment Mode', 'Settlement Amount', 'Share %'],
              data: [
                ['Cash In Hand', _formatPdfCurrency(cash), payTotal > 0 ? '${(cash / payTotal * 100).toStringAsFixed(1)}%' : '0.0%'],
                ['UPI / QR Payments', _formatPdfCurrency(upi), payTotal > 0 ? '${(upi / payTotal * 100).toStringAsFixed(1)}%' : '0.0%'],
                ['Card POS Swipe', _formatPdfCurrency(card), payTotal > 0 ? '${(card / payTotal * 100).toStringAsFixed(1)}%' : '0.0%'],
                if (wallet > 0)
                  ['Wallet / Other', _formatPdfCurrency(wallet), payTotal > 0 ? '${(wallet / payTotal * 100).toStringAsFixed(1)}%' : '0.0%'],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: _pdfPrimary),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
            ),
            pw.SizedBox(height: 12),

            // 4. Expense Category Visual Breakdown
            _buildPdfSectionHeader('4. Expense Breakdown by Category'),
            if (expenseRows.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Text('No operating expenses logged for this period.', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
              )
            else ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: _pdfBgSubtle,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: _pdfBorder, width: 0.7),
                ),
                child: pw.Column(
                  children: expenseRows.take(10).map((row) {
                    final cat = row['category']?.toString() ?? 'Miscellaneous';
                    final amt = (row['amount'] as num?)?.toDouble() ?? 0.0;
                    final cnt = (row['count'] as num?)?.toInt() ?? 0;
                    final pct = totalExpForPct > 0 ? (amt / totalExpForPct).clamp(0.0, 1.0) : 0.0;
                    final filledFlex = (pct * 100).round().clamp(1, 100);
                    final emptyFlex = (100 - filledFlex).clamp(0, 99);
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 90,
                            child: pw.Text('$cat ($cnt)', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Expanded(
                            child: pw.ClipRRect(
                              horizontalRadius: 3,
                              verticalRadius: 3,
                              child: pw.SizedBox(
                                height: 7,
                                child: pw.Row(
                                  children: [
                                    pw.Expanded(flex: filledFlex, child: pw.Container(color: PdfColors.red600)),
                                    if (emptyFlex > 0)
                                      pw.Expanded(flex: emptyFlex, child: pw.Container(color: PdfColors.grey200)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.SizedBox(
                            width: 105,
                            child: pw.Text(
                              '${_formatPdfCurrency(amt)} (${(pct * 100).toStringAsFixed(0)}%)',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            pw.SizedBox(height: 12),

            // 5. Customer & Loyalty Snapshot
            if (cust.isNotEmpty) ...[
              _buildPdfSectionHeader('5. Customer & Loyalty Summary'),
              pw.Row(
                children: [
                  _buildPdfKpiTile('Active Guests', _formatIndianInt('${(cust['periodActiveGuests'] ?? cust['totalCustomers'] ?? 0)}'), 'In period', PdfColors.teal700),
                  _buildPdfKpiTile('Total Registered', _formatIndianInt('${(cust['totalCustomers'] ?? 0)}'), 'Guest directory', PdfColors.purple700),
                  _buildPdfKpiTile('Loyalty Members', _formatIndianInt('${(cust['loyaltyMembers'] ?? 0)}'), 'Cardholders', PdfColors.amber800),
                  _buildPdfKpiTile('Returning Guests', _formatIndianInt('${(cust['returningCustomers'] ?? 0)}'), '>1 visits', PdfColors.blue700),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 6. Dishes Sold Leaderboard
            _buildPdfSectionHeader('6. Menu Dishes Sold Leaderboard (${_formatIndianInt('$totalDishQty')} items)'),
            if (dishes.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text('No dishes recorded for this period.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: ['Rank', 'Dish Name', 'Units Sold', 'Share', 'Revenue'],
                data: dishes.take(30).toList().asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  final name = (item['name'] ?? item['_id'])?.toString() ?? 'Dish';
                  final qty = ((item['totalQuantity'] ?? item['quantity'] ?? 0) as num).toInt();
                  final sales = (item['totalSales'] as num?)?.toDouble() ?? 0.0;
                  final share = totalDishQty > 0 ? '${(qty / totalDishQty * 100).toStringAsFixed(1)}%' : '0.0%';
                  return [
                    '#${idx + 1}',
                    name,
                    '${_formatIndianInt('$qty')} unit${qty > 1 ? 's' : ''}',
                    share,
                    sales > 0 ? _formatPdfCurrency(sales) : '-',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: _pdfPrimary),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              ),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${businessName.replaceAll(' ', '_')}_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: '$businessName Business Report PDF');
  }

  static Future<void> _exportReportToExcel(
    DashboardState metrics,
    String businessName, [
    String? dateRangeLabel,
    bool isPeriodSlice = false,
  ]) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Financial Summary');
    final sheet = excel['Financial Summary'];

    sheet.appendRow([TextCellValue('FoodBillX Financial & Business Report')]);
    sheet.appendRow([TextCellValue('Business Name: $businessName')]);
    if (dateRangeLabel != null && dateRangeLabel.isNotEmpty) {
      sheet.appendRow([TextCellValue('Timeframe: $dateRangeLabel')]);
    }
    sheet.appendRow([TextCellValue('Export Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}')]);
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([TextCellValue('PROFIT & REVENUE SUMMARY')]);
    sheet.appendRow([
      TextCellValue('Timeframe'),
      TextCellValue('Revenue (Rs)'),
      TextCellValue('Expenses (Rs)'),
      TextCellValue('Net Profit (Rs)'),
    ]);
    if (isPeriodSlice) {
      sheet.appendRow([
        TextCellValue(dateRangeLabel ?? 'Selected Period'),
        DoubleCellValue(metrics.todayRevenue),
        DoubleCellValue(metrics.todayExpenseTotal),
        DoubleCellValue(metrics.netProfitToday),
      ]);
      sheet.appendRow([TextCellValue('Orders Completed'), IntCellValue(metrics.todayOrderCount)]);
      sheet.appendRow([TextCellValue('Average Bill Value'), DoubleCellValue(metrics.averageBillValue)]);
      sheet.appendRow([TextCellValue('Peak Selling Hour'), TextCellValue(metrics.peakSellingHour)]);
    } else {
      sheet.appendRow([TextCellValue('Today'), DoubleCellValue(metrics.todayRevenue), DoubleCellValue(metrics.todayExpenseTotal), DoubleCellValue(metrics.netProfitToday)]);
      sheet.appendRow([TextCellValue('This Week'), DoubleCellValue(metrics.weekRevenue), DoubleCellValue(metrics.weekExpenseTotal), DoubleCellValue(metrics.weeklyProfit)]);
      sheet.appendRow([TextCellValue('This Month'), DoubleCellValue(metrics.monthRevenue), DoubleCellValue(metrics.monthExpenseTotal), DoubleCellValue(metrics.monthlyProfit)]);
      sheet.appendRow([TextCellValue('Overall'), DoubleCellValue(metrics.overallRevenue), DoubleCellValue(metrics.overallExpenseTotal), DoubleCellValue(metrics.overallProfit)]);
    }
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([TextCellValue('PAYMENT METHODS BREAKDOWN')]);
    sheet.appendRow([TextCellValue('Payment Mode'), TextCellValue('Amount (Rs)')]);
    sheet.appendRow([TextCellValue('Cash'), DoubleCellValue((metrics.paymentAnalytics['cash'] as num?)?.toDouble() ?? 0.0)]);
    sheet.appendRow([TextCellValue('UPI / QR'), DoubleCellValue((metrics.paymentAnalytics['upi'] as num?)?.toDouble() ?? 0.0)]);
    sheet.appendRow([TextCellValue('Card'), DoubleCellValue((metrics.paymentAnalytics['card'] as num?)?.toDouble() ?? 0.0)]);
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([TextCellValue('DISHES SOLD BREAKDOWN')]);
    sheet.appendRow([TextCellValue('Dish Name'), TextCellValue('Units Sold'), TextCellValue('Revenue')]);
    final dishes = metrics.todayDishBreakdown.isNotEmpty ? metrics.todayDishBreakdown : metrics.topSellingItems;
    for (final it in dishes) {
      final name = (it['name'] ?? it['_id'])?.toString() ?? 'Dish';
      final qty = ((it['totalQuantity'] ?? it['quantity'] ?? 0) as num).toInt();
      final sales = (it['totalSales'] as num?)?.toDouble() ?? 0.0;
      sheet.appendRow([TextCellValue(name), IntCellValue(qty), DoubleCellValue(sales)]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${businessName.replaceAll(' ', '_')}_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: '$businessName Report Excel');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // 2. ORDERS REGISTER EXPORT (PDF & Excel)
  // ─────────────────────────────────────────────────────────────────
  static Future<void> exportOrders({
    required List<OrderModel> orders,
    required String businessName,
    required ExportFormat format,
    BusinessSettingsModel? settings,
    String? dateRangeLabel,
  }) async {
    if (format == ExportFormat.pdf) {
      await _exportOrdersToPdf(orders, businessName, settings, dateRangeLabel);
    } else {
      await _exportOrdersToExcel(orders, businessName, dateRangeLabel);
    }
  }

  static Future<void> exportOrdersToPdf(
    List<OrderModel> orders,
    String businessName, [
    BusinessSettingsModel? settings,
    String? dateRangeLabel,
  ]) =>
      exportOrders(
        orders: orders,
        businessName: businessName,
        format: ExportFormat.pdf,
        settings: settings,
        dateRangeLabel: dateRangeLabel,
      );

  static Future<void> exportOrdersToExcel(
    List<OrderModel> orders,
    String businessName, [
    String? dateRangeLabel,
  ]) =>
      exportOrders(
        orders: orders,
        businessName: businessName,
        format: ExportFormat.excel,
        dateRangeLabel: dateRangeLabel,
      );

  static Future<void> _exportOrdersToPdf(
    List<OrderModel> orders,
    String businessName,
    BusinessSettingsModel? settings, [
    String? dateRangeLabel,
  ]) async {
    final pdf = pw.Document();

    double totalRevenue = 0.0;
    double totalDiscount = 0.0;
    for (final o in orders) {
      totalRevenue += o.grandTotal;
      totalDiscount += o.discountAmount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _buildPdfHeader(
          title: 'Order Data Register',
          subtitle: 'Itemized Order Ledger & Collections',
          businessName: businessName,
          settings: settings,
          dateRangeLabel: dateRangeLabel,
        ),
        footer: (ctx) => _buildPdfFooter(ctx),
        build: (pw.Context context) {
          final avgOrder = orders.isNotEmpty ? totalRevenue / orders.length : 0.0;
          return [
            // KPI Summary Row
            pw.Row(
              children: [
                _buildPdfKpiTile('Total Bills', _formatIndianInt('${orders.length}'), 'Orders count', _pdfAccent),
                _buildPdfKpiTile('Gross Revenue', _formatPdfCurrency(totalRevenue), 'Total collections', PdfColors.green800),
                _buildPdfKpiTile('Total Discounts', _formatPdfCurrency(totalDiscount), 'Deductions given', PdfColors.red800),
                _buildPdfKpiTile('Avg Order Value', _formatPdfCurrency(avgOrder), 'Per order ticket', PdfColors.blue800),
              ],
            ),
            pw.SizedBox(height: 12),

            _buildPdfSectionHeader('Complete Orders Ledger (${orders.length} Bills)'),
            pw.TableHelper.fromTextArray(
              headers: ['Order #', 'Date & Time', 'Customer', 'Items Summary', 'Payment', 'Amount'],
              data: orders.map((o) {
                final dateStr = DateFormat('dd/MM/yy HH:mm').format(o.createdAt);
                final itemsSummary = o.items.map((i) => '${i.name} x${i.quantity}').join('; ');
                return [
                  o.orderNumber,
                  dateStr,
                  o.customerName,
                  itemsSummary.length > 32 ? '${itemsSummary.substring(0, 32)}...' : itemsSummary,
                  o.paymentMethod.toUpperCase(),
                  _formatPdfCurrency(o.grandTotal),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8.5),
              headerDecoration: pw.BoxDecoration(color: _pdfPrimary),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _pdfBgSubtle,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: _pdfBorder),
                  ),
                  child: pw.Text(
                    'TOTAL SETTLED REVENUE: ${_formatPdfCurrency(totalRevenue)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: _pdfPrimary),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${businessName.replaceAll(' ', '_')}_Orders_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: '$businessName Sales Register PDF');
  }

  static Future<void> _exportOrdersToExcel(
    List<OrderModel> orders,
    String businessName, [
    String? dateRangeLabel,
  ]) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Orders');
    final sheet = excel['Orders'];

    if (dateRangeLabel != null && dateRangeLabel.isNotEmpty) {
      sheet.appendRow([TextCellValue('Timeframe: $dateRangeLabel')]);
      sheet.appendRow([TextCellValue('')]);
    }

    sheet.appendRow([
      TextCellValue('Order Number'),
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Customer Name'),
      TextCellValue('Customer Phone'),
      TextCellValue('Loyalty Card'),
      TextCellValue('Payment Method'),
      TextCellValue('Payment Status'),
      TextCellValue('Items Summary'),
      TextCellValue('Subtotal (Rs)'),
      TextCellValue('Discount (Rs)'),
      TextCellValue('Grand Total (Rs)'),
      TextCellValue('Order Status'),
    ]);

    for (final order in orders) {
      final dateStr = DateFormat('yyyy-MM-dd').format(order.createdAt);
      final timeStr = DateFormat('HH:mm').format(order.createdAt);
      final itemsSummary = order.items.map((i) => '${i.name} x${i.quantity}').join('; ');

      sheet.appendRow([
        TextCellValue(order.orderNumber),
        TextCellValue(dateStr),
        TextCellValue(timeStr),
        TextCellValue(order.customerName),
        TextCellValue(order.customerPhone),
        TextCellValue(order.loyaltyCardNumber),
        TextCellValue(order.paymentMethod.toUpperCase()),
        TextCellValue(order.paymentStatus.toUpperCase()),
        TextCellValue(itemsSummary),
        DoubleCellValue(order.subtotal),
        DoubleCellValue(order.discountAmount),
        DoubleCellValue(order.grandTotal),
        TextCellValue(order.orderStatus.toUpperCase()),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${businessName.replaceAll(' ', '_')}_Orders_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: '$businessName Orders Register Excel');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // 3. CUSTOMERS REGISTER EXPORT (PDF & Excel)
  // ─────────────────────────────────────────────────────────────────
  static Future<void> exportCustomers({
    required List<CustomerModel> customers,
    required String businessName,
    required ExportFormat format,
    BusinessSettingsModel? settings,
    String? dateRangeLabel,
  }) async {
    if (format == ExportFormat.pdf) {
      await _exportCustomersToPdf(customers, businessName, settings, dateRangeLabel);
    } else {
      await _exportCustomersToExcel(customers, businessName, dateRangeLabel);
    }
  }

  static Future<void> exportCustomersToPdf(
    List<CustomerModel> customers,
    String businessName, [
    BusinessSettingsModel? settings,
    String? dateRangeLabel,
  ]) =>
      exportCustomers(
        customers: customers,
        businessName: businessName,
        format: ExportFormat.pdf,
        settings: settings,
        dateRangeLabel: dateRangeLabel,
      );

  static Future<void> exportCustomersToExcel(
    List<CustomerModel> customers,
    String businessName, [
    String? dateRangeLabel,
  ]) =>
      exportCustomers(
        customers: customers,
        businessName: businessName,
        format: ExportFormat.excel,
        dateRangeLabel: dateRangeLabel,
      );

  static Future<void> _exportCustomersToPdf(
    List<CustomerModel> customers,
    String businessName,
    BusinessSettingsModel? settings, [
    String? dateRangeLabel,
  ]) async {
    final pdf = pw.Document();

    double totalSpent = 0.0;
    int totalVisits = 0;
    for (final c in customers) {
      totalSpent += c.totalSpent;
      totalVisits += c.totalVisits;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _buildPdfHeader(
          title: 'Customer Directory & Loyalty',
          subtitle: 'Client Profiles, Visit Counts & Loyalty Points',
          businessName: businessName,
          settings: settings,
          dateRangeLabel: dateRangeLabel,
        ),
        footer: (ctx) => _buildPdfFooter(ctx),
        build: (pw.Context context) {
          return [
            // KPI Summary Row
            pw.Row(
              children: [
                _buildPdfKpiTile('Total Clients', '${customers.length}', 'Registered customers', _pdfAccent),
                _buildPdfKpiTile('Total Visits', '$totalVisits', 'Cumulative store visits', PdfColors.blue800),
                _buildPdfKpiTile('Lifetime Spend', _formatPdfCurrency(totalSpent), 'Total spend across clients', PdfColors.green800),
              ],
            ),
            pw.SizedBox(height: 12),

            _buildPdfSectionHeader('Customer Profiles (${customers.length} Registered)'),
            pw.TableHelper.fromTextArray(
              headers: ['Customer Name', 'Phone Number', 'Card #', 'Visits', 'Total Spent', 'Loyalty Points'],
              data: customers.map((c) {
                return [
                  c.name,
                  c.phone.isNotEmpty ? c.phone : '-',
                  c.loyaltyCardNumber.isNotEmpty ? c.loyaltyCardNumber : '-',
                  '${c.totalVisits}',
                  _formatPdfCurrency(c.totalSpent),
                  '${c.loyaltyPoints} pts',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8.5),
              headerDecoration: pw.BoxDecoration(color: _pdfPrimary),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
            ),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${businessName.replaceAll(' ', '_')}_Customers_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: '$businessName Customer Directory PDF');
  }

  static Future<void> _exportCustomersToExcel(
    List<CustomerModel> customers,
    String businessName, [
    String? dateRangeLabel,
  ]) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Customers');
    final sheet = excel['Customers'];

    sheet.appendRow([
      TextCellValue('Customer Name'),
      TextCellValue('Phone Number'),
      TextCellValue('Address'),
      TextCellValue('Loyalty Card'),
      TextCellValue('Total Visits'),
      TextCellValue('Total Spent (Rs)'),
      TextCellValue('Loyalty Points'),
      TextCellValue('Notes'),
    ]);

    for (final cust in customers) {
      sheet.appendRow([
        TextCellValue(cust.name),
        TextCellValue(cust.phone),
        TextCellValue(cust.address),
        TextCellValue(cust.loyaltyCardNumber),
        IntCellValue(cust.totalVisits),
        DoubleCellValue(cust.totalSpent),
        IntCellValue(cust.loyaltyPoints),
        TextCellValue(cust.notes),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${businessName.replaceAll(' ', '_')}_Customers_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: '$businessName Customer Directory Excel');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // 4. COMPLETE APP BACKUP EXPORT (⭐️ EXCEL ONLY)
  // ─────────────────────────────────────────────────────────────────
  static Future<void> exportCompleteAppBackup({
    required LocalDatabase db,
    required String businessName,
    BusinessSettingsModel? settings,
    DateTime? startDate,
    DateTime? endDate,
    String? dateRangeLabel,
  }) async {
    final excel = Excel.createExcel();

    // 1. Orders Sheet
    excel.rename('Sheet1', 'Orders');
    final ordersSheet = excel['Orders'];
    ordersSheet.appendRow([
      TextCellValue('Order Number'),
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Customer Name'),
      TextCellValue('Customer Phone'),
      TextCellValue('Loyalty Card'),
      TextCellValue('Payment Method'),
      TextCellValue('Payment Status'),
      TextCellValue('Items Summary'),
      TextCellValue('Subtotal (Rs)'),
      TextCellValue('Discount (Rs)'),
      TextCellValue('Grand Total (Rs)'),
      TextCellValue('Order Status'),
    ]);
    final orders = await db.getOrders(startDate: startDate, endDate: endDate, limit: 50000);
    for (final o in orders) {
      final dateStr = DateFormat('yyyy-MM-dd').format(o.createdAt);
      final timeStr = DateFormat('HH:mm').format(o.createdAt);
      final itemsSummary = o.items.map((i) => '${i.name} x${i.quantity}').join('; ');
      ordersSheet.appendRow([
        TextCellValue(o.orderNumber),
        TextCellValue(dateStr),
        TextCellValue(timeStr),
        TextCellValue(o.customerName),
        TextCellValue(o.customerPhone),
        TextCellValue(o.loyaltyCardNumber),
        TextCellValue(o.paymentMethod.toUpperCase()),
        TextCellValue(o.paymentStatus.toUpperCase()),
        TextCellValue(itemsSummary),
        DoubleCellValue(o.subtotal),
        DoubleCellValue(o.discountAmount),
        DoubleCellValue(o.grandTotal),
        TextCellValue(o.orderStatus.toUpperCase()),
      ]);
    }

    // 2. Customers Sheet
    final custSheet = excel['Customers'];
    custSheet.appendRow([
      TextCellValue('Customer Name'),
      TextCellValue('Phone Number'),
      TextCellValue('Address'),
      TextCellValue('Loyalty Card'),
      TextCellValue('Total Visits'),
      TextCellValue('Total Spent (Rs)'),
      TextCellValue('Loyalty Points'),
      TextCellValue('Notes'),
    ]);
    final customers = await db.getCustomers();
    for (final c in customers) {
      custSheet.appendRow([
        TextCellValue(c.name),
        TextCellValue(c.phone),
        TextCellValue(c.address),
        TextCellValue(c.loyaltyCardNumber),
        IntCellValue(c.totalVisits),
        DoubleCellValue(c.totalSpent),
        IntCellValue(c.loyaltyPoints),
        TextCellValue(c.notes),
      ]);
    }

    // 3. Menu Sheet
    final menuSheet = excel['Menu'];
    menuSheet.appendRow([
      TextCellValue('Category Name'),
      TextCellValue('Dish Name'),
      TextCellValue('Description'),
      TextCellValue('Price (Rs)'),
      TextCellValue('Discount (Rs)'),
      TextCellValue('Is Veg'),
      TextCellValue('Is Available'),
    ]);
    final categories = await db.getMenuCategories();
    final catMap = {for (final c in categories) c.id: c.name};
    final items = await db.getMenuItems();
    for (final it in items) {
      menuSheet.appendRow([
        TextCellValue(catMap[it.categoryId] ?? 'General'),
        TextCellValue(it.name),
        TextCellValue(it.description),
        DoubleCellValue(it.price),
        DoubleCellValue(it.discount),
        TextCellValue(it.isVeg ? 'YES' : 'NO'),
        TextCellValue(it.isAvailable ? 'YES' : 'NO'),
      ]);
    }

    // 4. Expenses Sheet
    final expSheet = excel['Expenses'];
    expSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Category'),
      TextCellValue('Expense Title'),
      TextCellValue('Amount (Rs)'),
      TextCellValue('Notes'),
    ]);
    final expenses = await db.getExpenses(startDate: startDate, endDate: endDate);
    for (final exp in expenses) {
      expSheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(exp.date)),
        TextCellValue(exp.category),
        TextCellValue(exp.title),
        DoubleCellValue(exp.amount),
        TextCellValue(exp.notes),
      ]);
    }

    // 5. Settings Sheet
    final setSheet = excel['Settings'];
    setSheet.appendRow([
      TextCellValue('Setting Key'),
      TextCellValue('Setting Value'),
    ]);
    if (dateRangeLabel != null && dateRangeLabel.isNotEmpty) {
      setSheet.appendRow([TextCellValue('Backup Timeframe'), TextCellValue(dateRangeLabel)]);
    }
    final currentSettings = settings ?? await db.getSettings();
    if (currentSettings != null) {
      setSheet.appendRow([TextCellValue('Business Name'), TextCellValue(currentSettings.businessName)]);
      setSheet.appendRow([TextCellValue('Phone Number'), TextCellValue(currentSettings.phone)]);
      setSheet.appendRow([TextCellValue('Address'), TextCellValue(currentSettings.address)]);
      setSheet.appendRow([TextCellValue('Currency'), TextCellValue(currentSettings.currency)]);
      setSheet.appendRow([TextCellValue('Invoice Prefix'), TextCellValue(currentSettings.invoicePrefix)]);
      setSheet.appendRow([TextCellValue('Service Charge Percentage'), DoubleCellValue(currentSettings.serviceChargePercentage)]);
      setSheet.appendRow([TextCellValue('Invoice Footer'), TextCellValue(currentSettings.invoiceFooter)]);
      setSheet.appendRow([TextCellValue('Loyalty Target Visits'), IntCellValue(currentSettings.loyaltyTargetVisits)]);
      setSheet.appendRow([TextCellValue('Loyalty Reward Type'), TextCellValue(currentSettings.loyaltyRewardType)]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      final dir = await getTemporaryDirectory();
      final tag = dateRangeLabel != null ? dateRangeLabel.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') : 'Full';
      final file = File('${dir.path}/${businessName.replaceAll(' ', '_')}_Backup_${tag}_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: '$businessName Complete App Backup Excel');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────
  // 5. TOTAL APP DATA IMPORT (Single Excel or CSV)
  // ─────────────────────────────────────────────────────────────────

  /// Normalizes OpenXML relationship targets in memory.
  /// Standard OpenXML files from openpyxl, Office, etc. can contain targets like
  /// Target="/xl/worksheets/sheet1.xml". The excel package assumes relative paths
  /// ('xl/$target'), which causes null dereferences if leading slashes exist.
  static List<int> _sanitizeExcelBytes(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final newArchive = Archive();
      bool modified = false;

      for (final file in archive.files) {
        if (file.name == 'xl/_rels/workbook.xml.rels' || file.name.endsWith('.rels')) {
          final raw = file.content;
          final content = utf8.decode(raw is List<int> ? raw : (raw as dynamic).toList());
          if (content.contains('Target="/') || content.contains("Target='/")) {
            final fixed = content
                .replaceAll('Target="/xl/', 'Target="')
                .replaceAll('Target="/', 'Target="')
                .replaceAll("Target='/xl/", "Target='")
                .replaceAll("Target='/", "Target='");
            final fixedBytes = utf8.encode(fixed);
            newArchive.addFile(ArchiveFile(file.name, fixedBytes.length, fixedBytes));
            modified = true;
            continue;
          }
        }
        newArchive.addFile(file);
      }

      if (modified) {
        final encoded = ZipEncoder().encode(newArchive);
        if (encoded != null) return encoded;
      }
    } catch (e) {
      debugPrint('Excel sanitize fallback: $e');
    }
    return bytes;
  }

  static Future<Map<String, dynamic>> importTotalAppData(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Selected file does not exist on device storage');
    }

    if (filePath.toLowerCase().endsWith('.xlsx') || filePath.toLowerCase().endsWith('.xls')) {
      try {
        final rawBytes = await file.readAsBytes();
        final cleanBytes = _sanitizeExcelBytes(rawBytes);
        final excel = Excel.decodeBytes(cleanBytes);
        return await _importExcelWorkbook(excel);
      } catch (excelError) {
        debugPrint('Excel decode error, attempting CSV fallback: $excelError');
        try {
          final content = await file.readAsString();
          return await _importFromCsvAutoDetect(content);
        } catch (_) {
          rethrow;
        }
      }
    } else {
      // CSV / TXT import (handles both single-section and stacked multi-section CSVs)
      try {
        final content = await file.readAsString();
        return await _importFromCsvAutoDetect(content);
      } catch (_) {
        try {
          final rawBytes = await file.readAsBytes();
          final cleanBytes = _sanitizeExcelBytes(rawBytes);
          final excel = Excel.decodeBytes(cleanBytes);
          return await _importExcelWorkbook(excel);
        } catch (_) {
          rethrow;
        }
      }
    }
  }

  static String _extractCellValue(Data? c) {
    if (c == null) return '';
    try {
      final val = c.value;
      if (val == null) return '';
      if (val is TextCellValue) {
        return (val.value.text ?? val.toString()).trim();
      }
      if (val is IntCellValue) return val.value.toString();
      if (val is DoubleCellValue) return val.value.toString();
      if (val is DateCellValue) {
        return '${val.year}-${val.month.toString().padLeft(2, '0')}-${val.day.toString().padLeft(2, '0')}';
      }
      if (val is DateTimeCellValue) {
        return '${val.year}-${val.month.toString().padLeft(2, '0')}-${val.day.toString().padLeft(2, '0')} ${val.hour.toString().padLeft(2, '0')}:${val.minute.toString().padLeft(2, '0')}';
      }
      if (val is BoolCellValue) return val.value ? 'true' : 'false';
      return val.toString().trim();
    } catch (_) {
      return '';
    }
  }

  static DateTime? _parseFlexibleDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    final d = DateTime.tryParse(dateStr);
    if (d != null) return d;
    final parts = dateStr.split(RegExp(r'[/.-]'));
    if (parts.length >= 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2].split(' ')[0]);
      if (p0 != null && p1 != null && p2 != null) {
        if (p2 > 1000) {
          return DateTime(p2, p1, p0);
        } else if (p0 > 1000) {
          return DateTime(p0, p1, p2);
        }
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>> _importExcelWorkbook(Excel excel) async {
    int importedOrders = 0;
    int importedCustomers = 0;
    int importedMenuItems = 0;
    int importedExpenses = 0;
    bool settingsUpdated = false;

    for (final sheetName in excel.tables.keys) {
      final nameLower = sheetName.toLowerCase().trim();
      final sheet = excel.tables[sheetName];
      if (sheet == null) continue;
      final sheetRows = sheet.rows;
      if (sheetRows.length < 2) continue;

      // Extract raw string matrix safely across all cell types
      final rows = <List<String>>[];
      for (final r in sheetRows) {
        final rowList = <String>[];
        for (final c in r) {
          rowList.add(_extractCellValue(c));
        }
        rows.add(rowList);
      }
      if (rows.length < 2) continue;
      final header = rows.first.map((h) => h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();

      try {
        // Check sheet name first (User: "the sheet anme matters")
        if (nameLower.contains('order') || nameLower.contains('bill') || nameLower.contains('sale')) {
          importedOrders += await _importOrdersRows(rows, header);
        } else if (nameLower.contains('customer') || nameLower.contains('client') || nameLower.contains('user')) {
          importedCustomers += await _importCustomersRows(rows, header);
        } else if (nameLower.contains('menu') || nameLower.contains('dish') || nameLower.contains('food') || (nameLower.contains('item') && !nameLower.contains('order'))) {
          importedMenuItems += await _importMenuRows(rows, header);
        } else if (nameLower.contains('expense') || nameLower.contains('spend') || nameLower.contains('cost')) {
          importedExpenses += await _importExpensesRows(rows, header);
        } else if (nameLower.contains('setting') || nameLower.contains('config') || nameLower.contains('pref')) {
          final res = await _importSettingsRows(rows);
          if (res) settingsUpdated = true;
        } else {
          // Fallback for single sheet files or custom named sheets (e.g., "Sheet1", "Data")
          if (header.any((h) => h.contains('order') || h.contains('invoice') || h.contains('bill')) ||
              (header.any((h) => h.contains('total') || h.contains('subtotal')) && header.any((h) => h.contains('item') || h.contains('summary')))) {
            importedOrders += await _importOrdersRows(rows, header);
          } else if (header.any((h) => h.contains('customer') || h.contains('phone') || h.contains('mobile') || h.contains('loyalty'))) {
            importedCustomers += await _importCustomersRows(rows, header);
          } else if (header.any((h) => h.contains('category')) && header.any((h) => h.contains('price') || h.contains('dish'))) {
            importedMenuItems += await _importMenuRows(rows, header);
          } else if (header.any((h) => h.contains('expense')) || (header.any((h) => h.contains('amount')) && header.any((h) => h.contains('category')))) {
            importedExpenses += await _importExpensesRows(rows, header);
          }
        }
      } catch (_) {}
    }

    return {
      'orders': importedOrders,
      'customers': importedCustomers,
      'menu': importedMenuItems,
      'menuItems': importedMenuItems,
      'expenses': importedExpenses,
      'settings': settingsUpdated,
      'settingsUpdated': settingsUpdated,
    };
  }

  static Future<int> _importOrdersRows(List<List<String>> rows, List<String> header) async {
    final numIdx = header.indexWhere((h) => h.contains('order') || h.contains('bill') || h.contains('invoice'));
    final dateIdx = header.indexWhere((h) => h.contains('date'));
    final timeIdx = header.indexWhere((h) => h.contains('time'));
    final nameIdx = header.indexWhere((h) => h.contains('customer') || h.contains('client') || (h.contains('name') && !h.contains('order')));
    final phoneIdx = header.indexWhere((h) => h.contains('phone') || h.contains('mobile'));
    final totalIdx = header.indexWhere((h) => h.contains('grand') || h.contains('total') || h.contains('amount'));
    final subtotalIdx = header.indexWhere((h) => h.contains('subtotal') || h.contains('sub'));
    final discIdx = header.indexWhere((h) => h.contains('discount'));
    final taxIdx = header.indexWhere((h) => h.contains('tax') || h.contains('gst'));
    final payIdx = header.indexWhere((h) => h.contains('payment') || h.contains('method') || h.contains('mode'));
    final itemsIdx = header.indexWhere((h) => h.contains('item') || h.contains('dishes') || h.contains('summary'));

    final payloads = <Map<String, dynamic>>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      try {
        final orderNum = numIdx >= 0 && numIdx < row.length ? row[numIdx] : '';
        final custName = nameIdx >= 0 && nameIdx < row.length ? row[nameIdx] : 'Guest';
        final custPhone = phoneIdx >= 0 && phoneIdx < row.length ? row[phoneIdx] : '';
        final grandTotal = totalIdx >= 0 && totalIdx < row.length ? double.tryParse(row[totalIdx]) ?? 0.0 : 0.0;
        final subtotal = subtotalIdx >= 0 && subtotalIdx < row.length ? double.tryParse(row[subtotalIdx]) ?? grandTotal : grandTotal;
        final discount = discIdx >= 0 && discIdx < row.length ? double.tryParse(row[discIdx]) ?? 0.0 : 0.0;
        final tax = taxIdx >= 0 && taxIdx < row.length ? double.tryParse(row[taxIdx]) ?? 0.0 : 0.0;
        final paymentMethod = payIdx >= 0 && payIdx < row.length ? row[payIdx].toLowerCase() : 'cash';
        final itemsSummary = itemsIdx >= 0 && itemsIdx < row.length ? row[itemsIdx] : 'Sales Items';

        if (grandTotal <= 0 && orderNum.isEmpty) continue;

        DateTime? orderDate;
        if (dateIdx >= 0 && dateIdx < row.length && row[dateIdx].isNotEmpty) {
          final dateStr = row[dateIdx].trim();
          final timeStr = timeIdx >= 0 && timeIdx < row.length ? row[timeIdx].trim() : '';
          try {
            if (timeStr.isNotEmpty) {
              orderDate = DateTime.tryParse('${dateStr}T$timeStr') ??
                  DateTime.tryParse('$dateStr $timeStr') ??
                  DateTime.tryParse(dateStr);
            } else {
              orderDate = DateTime.tryParse(dateStr);
            }
          } catch (_) {}
          orderDate ??= _parseFlexibleDate(dateStr);
        }

        List<OrderItemModel> items = [];
        if (itemsSummary.isNotEmpty && itemsSummary.contains(';')) {
          final parts = itemsSummary.split(';');
          for (int pIdx = 0; pIdx < parts.length; pIdx++) {
            final part = parts[pIdx].trim();
            if (part.isEmpty) continue;
            final match = RegExp(r'^(.*?)\s*x\s*(\d+)$').firstMatch(part);
            if (match != null) {
              final itemName = match.group(1)?.trim() ?? part;
              final qty = int.tryParse(match.group(2) ?? '1') ?? 1;
              final itemPrice = (subtotal > 0 ? subtotal : grandTotal) / (parts.length * qty);
              items.add(OrderItemModel(
                menuItemId: 'imported_${i}_$pIdx',
                name: itemName,
                quantity: qty,
                price: itemPrice,
                subtotal: itemPrice * qty,
              ));
            } else {
              items.add(OrderItemModel(
                menuItemId: 'imported_${i}_$pIdx',
                name: part,
                quantity: 1,
                price: (subtotal > 0 ? subtotal : grandTotal) / parts.length,
                subtotal: (subtotal > 0 ? subtotal : grandTotal) / parts.length,
              ));
            }
          }
        }
        if (items.isEmpty) {
          items = [
            OrderItemModel(
              menuItemId: 'imported_$i',
              name: itemsSummary.isNotEmpty ? itemsSummary : 'Imported Item',
              quantity: 1,
              price: subtotal > 0 ? subtotal : grandTotal,
              subtotal: subtotal > 0 ? subtotal : grandTotal,
            ),
          ];
        }

        payloads.add({
          'orderNumber': orderNum,
          'customerName': custName.isNotEmpty ? custName : 'Guest',
          'customerPhone': custPhone,
          'items': items,
          'subtotal': subtotal,
          'discountAmount': discount,
          'gstAmount': tax,
          'serviceChargeAmount': 0.0,
          'grandTotal': grandTotal,
          'paymentMethod': paymentMethod.isNotEmpty ? paymentMethod : 'cash',
          'notes': 'Imported from Backup',
          'createdAt': orderDate,
        });
      } catch (_) {}
    }
    return await LocalDatabase.instance.importOrdersBatch(payloads);
  }

  static Future<int> _importCustomersRows(List<List<String>> rows, List<String> header) async {
    final nameIdx = header.indexWhere((h) => h.contains('name') || h.contains('customer'));
    final phoneIdx = header.indexWhere((h) => h.contains('phone') || h.contains('mobile') || h.contains('contact'));
    final addrIdx = header.indexWhere((h) => h.contains('address') || h.contains('location'));
    final cardIdx = header.indexWhere((h) => h.contains('card') || h.contains('loyalty'));
    final visitsIdx = header.indexWhere((h) => h.contains('visit') || h.contains('count'));
    final spentIdx = header.indexWhere((h) => h.contains('spent') || h.contains('total') || h.contains('amount'));
    final ptsIdx = header.indexWhere((h) => h.contains('point') || h.contains('pts'));
    final notesIdx = header.indexWhere((h) => h.contains('note') || h.contains('comment'));

    final payloads = <Map<String, dynamic>>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      try {
        final name = nameIdx >= 0 && nameIdx < row.length ? row[nameIdx] : (row.isNotEmpty ? row[0] : '');
        final phone = phoneIdx >= 0 && phoneIdx < row.length ? row[phoneIdx] : (row.length > 1 ? row[1] : '');
        if (name.trim().isEmpty && phone.trim().isEmpty) continue;

        final address = addrIdx >= 0 && addrIdx < row.length ? row[addrIdx] : '';
        final card = cardIdx >= 0 && cardIdx < row.length ? row[cardIdx] : '';
        final visits = visitsIdx >= 0 && visitsIdx < row.length ? int.tryParse(row[visitsIdx]) ?? 0 : 0;
        final spent = spentIdx >= 0 && spentIdx < row.length ? double.tryParse(row[spentIdx]) ?? 0.0 : 0.0;
        final pts = ptsIdx >= 0 && ptsIdx < row.length ? int.tryParse(row[ptsIdx]) ?? 0 : 0;
        final notes = notesIdx >= 0 && notesIdx < row.length ? row[notesIdx] : '';

        payloads.add({
          'name': name.isEmpty ? 'Customer ${phone.isNotEmpty ? phone : i}' : name,
          'phone': phone,
          'address': address,
          'loyaltyCardNumber': card,
          'totalVisits': visits,
          'totalSpent': spent,
          'loyaltyPoints': pts,
          'notes': notes,
        });
      } catch (_) {}
    }
    return await LocalDatabase.instance.importCustomersBatch(payloads);
  }

  static Future<int> _importMenuRows(List<List<String>> rows, List<String> header) async {
    final catIdx = header.indexWhere((h) => h.contains('category'));
    final nameIdx = header.indexWhere((h) => h.contains('name') || h.contains('dish') || h.contains('item'));
    final priceIdx = header.indexWhere((h) => h.contains('price') || h.contains('rate') || h.contains('cost'));
    final descIdx = header.indexWhere((h) => h.contains('desc'));
    final discIdx = header.indexWhere((h) => h.contains('discount'));
    final vegIdx = header.indexWhere((h) => h.contains('veg'));

    final existingCats = await LocalDatabase.instance.getMenuCategories();
    final catMap = {for (final c in existingCats) c.name.toLowerCase().trim(): c.id};

    final itemsToInsert = <MenuItemModel>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      try {
        final dishName = nameIdx >= 0 && nameIdx < row.length ? row[nameIdx].trim() : '';
        if (dishName.isEmpty) continue;

        final catName = catIdx >= 0 && catIdx < row.length && row[catIdx].isNotEmpty ? row[catIdx].trim() : 'General';
        String? catId = catMap[catName.toLowerCase()];
        if (catId == null) {
          final newCat = await LocalDatabase.instance.insertMenuCategory(catName, 'fastfood');
          catId = newCat.id;
          catMap[catName.toLowerCase()] = catId;
        }

        final price = priceIdx >= 0 && priceIdx < row.length ? double.tryParse(row[priceIdx]) ?? 0.0 : 0.0;
        final desc = descIdx >= 0 && descIdx < row.length ? row[descIdx] : '';
        final disc = discIdx >= 0 && discIdx < row.length ? double.tryParse(row[discIdx]) ?? 0.0 : 0.0;
        final isVegStr = vegIdx >= 0 && vegIdx < row.length ? row[vegIdx].toLowerCase() : 'yes';
        final isVeg = !isVegStr.contains('no') && !isVegStr.contains('non');

        itemsToInsert.add(
          MenuItemModel(
            id: '',
            categoryId: catId,
            name: dishName,
            description: desc,
            price: price,
            discount: disc,
            gstPercentage: 0.0,
            image: '',
            isVeg: isVeg,
            isAvailable: true,
          ),
        );
      } catch (_) {}
    }
    return await LocalDatabase.instance.importMenuItemsBatch(itemsToInsert);
  }

  static Future<int> _importExpensesRows(List<List<String>> rows, List<String> header) async {
    final dateIdx = header.indexWhere((h) => h.contains('date'));
    final catIdx = header.indexWhere((h) => h.contains('cat'));
    final titleIdx = header.indexWhere((h) => h.contains('title') || h.contains('name') || h.contains('desc'));
    final amtIdx = header.indexWhere((h) => h.contains('amt') || h.contains('amount') || h.contains('cost') || h.contains('price'));
    final notesIdx = header.indexWhere((h) => h.contains('note'));

    final payloads = <Map<String, dynamic>>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      try {
        final amount = amtIdx >= 0 && amtIdx < row.length ? double.tryParse(row[amtIdx]) ?? 0.0 : 0.0;
        if (amount <= 0) continue;

        final title = titleIdx >= 0 && titleIdx < row.length ? row[titleIdx] : 'Expense';
        final cat = catIdx >= 0 && catIdx < row.length && row[catIdx].isNotEmpty ? row[catIdx] : 'Miscellaneous';
        final rawDateStr = dateIdx >= 0 && dateIdx < row.length ? row[dateIdx].trim() : '';
        final parsedExpenseDate = rawDateStr.isNotEmpty
            ? (DateTime.tryParse(rawDateStr) ?? _parseFlexibleDate(rawDateStr))
            : null;
        final date = (parsedExpenseDate ?? DateTime.now()).toIso8601String();
        final notes = notesIdx >= 0 && notesIdx < row.length ? row[notesIdx] : '';

        payloads.add({
          'title': title,
          'category': cat,
          'amount': amount,
          'date': date,
          'notes': notes,
        });
      } catch (_) {}
    }
    return await LocalDatabase.instance.importExpensesBatch(payloads);
  }

  static Future<bool> _importSettingsRows(List<List<String>> rows) async {
    try {
      final settingsMap = <String, dynamic>{};
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 2) continue;
        final key = row[0].toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        final val = row[1].trim();
        if (val.isEmpty) continue;

        if (key.contains('name')) settingsMap['businessName'] = val;
        if (key.contains('phone')) settingsMap['phone'] = val;
        if (key.contains('address')) settingsMap['address'] = val;
        if (key.contains('gst')) settingsMap['gstin'] = val;
        if (key.contains('prefix')) settingsMap['invoicePrefix'] = val;
        if (key.contains('currency')) settingsMap['currency'] = val;
        if (key.contains('footer')) settingsMap['invoiceFooter'] = val;
        if (key.contains('tax')) settingsMap['taxPercentage'] = double.tryParse(val) ?? 0.0;
        if (key.contains('service')) settingsMap['serviceChargePercentage'] = double.tryParse(val) ?? 0.0;
        if (key.contains('target')) settingsMap['loyaltyTargetVisits'] = int.tryParse(val) ?? 6;
        if (key.contains('reward')) settingsMap['loyaltyRewardType'] = val;
      }
      if (settingsMap.isNotEmpty) {
        await LocalDatabase.instance.upsertSettings(settingsMap);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<Map<String, dynamic>> _importFromCsvAutoDetect(String csvContent) async {
    final allRows = parseCsv(csvContent);
    if (allRows.isEmpty) {
      return {
        'orders': 0,
        'customers': 0,
        'menu': 0,
        'menuItems': 0,
        'expenses': 0,
        'settings': false,
        'settingsUpdated': false,
      };
    }

    // Check if this CSV contains multiple sections
    final sections = <String, List<List<String>>>{};
    String currentSection = 'unknown';

    for (final row in allRows) {
      if (row.isEmpty || row.every((c) => c.trim().isEmpty)) continue;
      final normalizedRow = row.map((c) => c.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();

      // Detect section header
      if (normalizedRow.any((h) => h.contains('ordernumber') || (h.contains('order') && h.contains('number')) || h.contains('itemssummary'))) {
        currentSection = 'orders';
        sections.putIfAbsent('orders', () => []).add(row);
      } else if (normalizedRow.any((h) => h.contains('customername') || (h.contains('customer') && h.contains('name'))) &&
                 normalizedRow.any((h) => h.contains('phonenumber') || h.contains('phone') || h.contains('totalvisits'))) {
        currentSection = 'customers';
        sections.putIfAbsent('customers', () => []).add(row);
      } else if (normalizedRow.any((h) => h.contains('categoryname') || (h.contains('category') && h.contains('name'))) &&
                 normalizedRow.any((h) => h.contains('dishname') || h.contains('price') || h.contains('isveg'))) {
        currentSection = 'menu';
        sections.putIfAbsent('menu', () => []).add(row);
      } else if (normalizedRow.any((h) => h.contains('expensetitle') || (h.contains('expense') && h.contains('title'))) ||
                 (normalizedRow.any((h) => h.contains('date')) && normalizedRow.any((h) => h.contains('category')) && normalizedRow.any((h) => h.contains('amount')))) {
        currentSection = 'expenses';
        sections.putIfAbsent('expenses', () => []).add(row);
      } else if (normalizedRow.any((h) => h.contains('settingkey') || (h.contains('setting') && h.contains('key')))) {
        currentSection = 'settings';
        sections.putIfAbsent('settings', () => []).add(row);
      } else {
        // Regular data row
        if (currentSection != 'unknown') {
          sections.putIfAbsent(currentSection, () => []).add(row);
        } else {
          // If first row didn't match specific multi-section keywords, auto-classify single-table CSV
          sections.putIfAbsent('default', () => []).add(row);
        }
      }
    }

    int importedOrders = 0;
    int importedCustomers = 0;
    int importedMenuItems = 0;
    int importedExpenses = 0;
    bool settingsUpdated = false;

    if (sections.containsKey('orders')) {
      final rows = sections['orders']!;
      if (rows.length >= 2) {
        final header = rows.first.map((h) => h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
        importedOrders += await _importOrdersRows(rows, header);
      }
    }
    if (sections.containsKey('customers')) {
      final rows = sections['customers']!;
      if (rows.length >= 2) {
        final header = rows.first.map((h) => h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
        importedCustomers += await _importCustomersRows(rows, header);
      }
    }
    if (sections.containsKey('menu')) {
      final rows = sections['menu']!;
      if (rows.length >= 2) {
        final header = rows.first.map((h) => h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
        importedMenuItems += await _importMenuRows(rows, header);
      }
    }
    if (sections.containsKey('expenses')) {
      final rows = sections['expenses']!;
      if (rows.length >= 2) {
        final header = rows.first.map((h) => h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
        importedExpenses += await _importExpensesRows(rows, header);
      }
    }
    if (sections.containsKey('settings')) {
      final rows = sections['settings']!;
      if (rows.length >= 2) {
        final res = await _importSettingsRows(rows);
        if (res) settingsUpdated = true;
      }
    }

    // Fallback for single-table CSV without explicit multi-section headers
    if (sections.containsKey('default')) {
      final rows = sections['default']!;
      if (rows.length >= 2) {
        final header = rows.first.map((h) => h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
        if (header.any((h) => h.contains('order') || h.contains('bill') || h.contains('invoice')) ||
            (header.any((h) => h.contains('grand') || h.contains('subtotal')) && header.any((h) => h.contains('item') || h.contains('summary')))) {
          importedOrders += await _importOrdersRows(rows, header);
        } else if (header.any((h) => h.contains('customer') || h.contains('phone') || h.contains('loyalty'))) {
          importedCustomers += await _importCustomersRows(rows, header);
        } else if (header.any((h) => h.contains('category')) && header.any((h) => h.contains('price') || h.contains('dish'))) {
          importedMenuItems += await _importMenuRows(rows, header);
        } else if (header.any((h) => h.contains('expense')) || (header.any((h) => h.contains('amount')) && header.any((h) => h.contains('category')))) {
          importedExpenses += await _importExpensesRows(rows, header);
        } else {
          importedOrders += await _importOrdersRows(rows, header);
        }
      }
    }

    return {
      'orders': importedOrders,
      'customers': importedCustomers,
      'menu': importedMenuItems,
      'menuItems': importedMenuItems,
      'expenses': importedExpenses,
      'settings': settingsUpdated,
      'settingsUpdated': settingsUpdated,
    };
  }

  // ─────────────────────────────────────────────────────────────────
  // CSV Parser & Legacy Compatibility Helpers
  // ─────────────────────────────────────────────────────────────────
  static List<List<String>> parseCsv(String input) {
    final List<List<String>> rows = [];
    List<String> currentRow = [];
    final StringBuffer currentField = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            currentField.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentRow.add(currentField.toString().trim());
          currentField.clear();
        } else if (char == '\n' || char == '\r') {
          if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
            i++;
          }
          currentRow.add(currentField.toString().trim());
          currentField.clear();
          if (currentRow.any((c) => c.isNotEmpty)) {
            rows.add(currentRow);
          }
          currentRow = [];
        } else {
          currentField.write(char);
        }
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString().trim());
      if (currentRow.any((c) => c.isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }

  // Legacy wrappers so any existing calls continue to work seamlessly
  static Future<int> importOrdersFromCsv(String csvContent) async {
    final res = await _importFromCsvAutoDetect(csvContent);
    return res['orders'] as int? ?? 0;
  }

  static Future<int> importCustomersFromCsv(String csvContent) async {
    final rows = parseCsv(csvContent);
    if (rows.length < 2) return 0;
    final header = rows.first.map((h) => h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
    return await _importCustomersRows(rows, header);
  }
}
