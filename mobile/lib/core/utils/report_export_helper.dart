import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../providers/dashboard_provider.dart';
import 'currency_formatter.dart';

class ReportExportHelper {
  static Future<void> exportReportToPdf(DashboardState metrics, String businessName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        businessName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange900,
                        ),
                      ),
                      pw.Text(
                        'Restaurant Business & Financial Report',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, height: 20),

              pw.Text('1. Profit & Revenue Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Timeframe', 'Revenue', 'Expenses', 'Net Profit'],
                data: [
                  ['Today', CurrencyFormatter.format(metrics.todayRevenue), CurrencyFormatter.format(metrics.todayExpenseTotal), CurrencyFormatter.format(metrics.netProfitToday)],
                  ['This Week', CurrencyFormatter.format(metrics.weekRevenue), CurrencyFormatter.format(metrics.weekExpenseTotal), CurrencyFormatter.format(metrics.weeklyProfit)],
                  ['This Month', CurrencyFormatter.format(metrics.monthRevenue), CurrencyFormatter.format(metrics.monthExpenseTotal), CurrencyFormatter.format(metrics.monthlyProfit)],
                  ['Overall', CurrencyFormatter.format(metrics.overallRevenue), CurrencyFormatter.format(metrics.overallExpenseTotal), CurrencyFormatter.format(metrics.overallProfit)],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
              ),
              pw.SizedBox(height: 16),

              pw.Text('2. Key Performance Indicators', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Bullet(text: 'Total Orders: ${metrics.overallOrderCount} orders'),
              pw.Bullet(text: 'Average Bill Value: ${CurrencyFormatter.format(metrics.averageBillValue)}'),
              pw.Bullet(text: 'Peak Selling Hour: ${metrics.peakSellingHour}'),
              pw.SizedBox(height: 16),

              pw.Text('3. Top Selling Dishes', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Dish Name', 'Units Sold', 'Total Revenue'],
                data: metrics.topSellingItems.map((item) {
                  return [
                    item['_id']?.toString() ?? 'Dish',
                    '${item['totalQuantity'] ?? 0}',
                    CurrencyFormatter.format((item['totalSales'] as num?)?.toDouble() ?? 0.0),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
              ),
              pw.Spacer(),

              pw.Center(
                child: pw.Text('HMB Bills POS Engine • Confidential Financial Document', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/HMB_Bills_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: 'HMB Bills Business Report PDF');
  }

  static Future<void> exportReportToExcel(DashboardState metrics, String businessName) async {
    final StringBuffer csvBuffer = StringBuffer();

    csvBuffer.writeln('HMB Bills - Restaurant Financial & Business Report');
    csvBuffer.writeln('Business Name,$businessName');
    csvBuffer.writeln('Generated Date,${DateTime.now().toIso8601String()}');
    csvBuffer.writeln('');

    csvBuffer.writeln('PROFIT & REVENUE SUMMARY');
    csvBuffer.writeln('Timeframe,Revenue,Expenses,Net Profit');
    csvBuffer.writeln('Today,${metrics.todayRevenue},${metrics.todayExpenseTotal},${metrics.netProfitToday}');
    csvBuffer.writeln('This Week,${metrics.weekRevenue},${metrics.weekExpenseTotal},${metrics.weeklyProfit}');
    csvBuffer.writeln('This Month,${metrics.monthRevenue},${metrics.monthExpenseTotal},${metrics.monthlyProfit}');
    csvBuffer.writeln('Overall,${metrics.overallRevenue},${metrics.overallExpenseTotal},${metrics.overallProfit}');
    csvBuffer.writeln('');

    csvBuffer.writeln('KEY PERFORMANCE INDICATORS');
    csvBuffer.writeln('Metric,Value');
    csvBuffer.writeln('Total Orders,${metrics.overallOrderCount}');
    csvBuffer.writeln('Average Bill Value,${metrics.averageBillValue}');
    csvBuffer.writeln('Peak Selling Hour,${metrics.peakSellingHour}');
    csvBuffer.writeln('');

    csvBuffer.writeln('TOP SELLING DISHES');
    csvBuffer.writeln('Dish Name,Units Sold,Total Revenue');
    for (final item in metrics.topSellingItems) {
      csvBuffer.writeln('"${item['_id'] ?? 'Dish'}",${item['totalQuantity'] ?? 0},${item['totalSales'] ?? 0}');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/HMB_Bills_Report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvBuffer.toString());

    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: 'HMB Bills Excel/CSV Business Report');
  }
}
