import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../models/customer_model.dart';
import '../../models/expense_model.dart';
import '../../models/order_model.dart';
import '../../providers/dashboard_provider.dart';
import '../storage/local_database.dart';

class ReportExportHelper {
  static String _formatPdfCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return 'Rs. $intPart.${parts[1]}';
  }

  static String _formatPdfProfit(double profit, double expenses) {
    if (expenses <= 0) return 'Add expense';
    return _formatPdfCurrency(profit);
  }

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
                  ['Today', _formatPdfCurrency(metrics.todayRevenue), _formatPdfCurrency(metrics.todayExpenseTotal), _formatPdfProfit(metrics.netProfitToday, metrics.todayExpenseTotal)],
                  ['This Week', _formatPdfCurrency(metrics.weekRevenue), _formatPdfCurrency(metrics.weekExpenseTotal), _formatPdfProfit(metrics.weeklyProfit, metrics.weekExpenseTotal)],
                  ['This Month', _formatPdfCurrency(metrics.monthRevenue), _formatPdfCurrency(metrics.monthExpenseTotal), _formatPdfProfit(metrics.monthlyProfit, metrics.monthExpenseTotal)],
                  ['Overall', _formatPdfCurrency(metrics.overallRevenue), _formatPdfCurrency(metrics.overallExpenseTotal), _formatPdfProfit(metrics.overallProfit, metrics.overallExpenseTotal)],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
              ),
              pw.SizedBox(height: 16),

              pw.Text('2. Key Performance Indicators', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Bullet(text: 'Total Orders: ${metrics.overallOrderCount} orders'),
              pw.Bullet(text: 'Average Bill Value: ${_formatPdfCurrency(metrics.averageBillValue)}'),
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
                    _formatPdfCurrency((item['totalSales'] as num?)?.toDouble() ?? 0.0),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
              ),
              pw.Spacer(),

              pw.Center(
                child: pw.Text('HMB Bills POS Engine - Confidential Financial Document', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
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
    await Share.shareXFiles([xFile], text: '$businessName Business Summary Report CSV');
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Exports full sales & order ledger with all details to Excel / CSV format
  static Future<void> exportOrdersToExcel(List<OrderModel> orders, String businessName) async {
    final StringBuffer csvBuffer = StringBuffer();

    csvBuffer.writeln('FoodBillX - Complete Sales & Orders Register');
    csvBuffer.writeln('Business Name,$businessName');
    csvBuffer.writeln('Export Date,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    csvBuffer.writeln('Total Bills / Orders,${orders.length}');
    csvBuffer.writeln('');

    csvBuffer.writeln(
      'Order Number,Date,Time,Customer Name,Customer Phone,Loyalty Card,Payment Method,Payment Status,Items Count,Items Summary,Subtotal (Rs),Discount (Rs),Tax (Rs),Service Charge (Rs),Grand Total (Rs),Order Status',
    );

    double totalRevenue = 0.0;
    double totalDiscount = 0.0;
    double totalTax = 0.0;

    for (final order in orders) {
      totalRevenue += order.grandTotal;
      totalDiscount += order.discountAmount;
      totalTax += order.gstAmount;

      final dateStr = DateFormat('yyyy-MM-dd').format(order.createdAt);
      final timeStr = DateFormat('HH:mm').format(order.createdAt);
      final itemsSummary = order.items.map((i) => '${i.name} x${i.quantity}').join('; ');

      csvBuffer.writeln([
        _escapeCsv(order.orderNumber),
        dateStr,
        timeStr,
        _escapeCsv(order.customerName),
        _escapeCsv(order.customerPhone),
        _escapeCsv(order.loyaltyCardNumber),
        _escapeCsv(order.paymentMethod.toUpperCase()),
        _escapeCsv(order.paymentStatus.toUpperCase()),
        order.items.length.toString(),
        _escapeCsv(itemsSummary),
        order.subtotal.toStringAsFixed(2),
        order.discountAmount.toStringAsFixed(2),
        order.gstAmount.toStringAsFixed(2),
        order.serviceChargeAmount.toStringAsFixed(2),
        order.grandTotal.toStringAsFixed(2),
        _escapeCsv(order.orderStatus.toUpperCase()),
      ].join(','));
    }

    csvBuffer.writeln('');
    csvBuffer.writeln(',,,,,,,,,,TOTAL REVENUE,${totalRevenue.toStringAsFixed(2)},TOTAL DISCOUNT,${totalDiscount.toStringAsFixed(2)},TOTAL TAX,${totalTax.toStringAsFixed(2)}');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/FoodBillX_Orders_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvBuffer.toString());

    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: '$businessName Sales & Orders Register CSV');
  }

  /// Exports itemized expenses log to Excel / CSV format
  static Future<void> exportExpensesToExcel(List<ExpenseModel> expenses, String businessName) async {
    final StringBuffer csvBuffer = StringBuffer();

    csvBuffer.writeln('FoodBillX - Complete Expenses Register');
    csvBuffer.writeln('Business Name,$businessName');
    csvBuffer.writeln('Export Date,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    csvBuffer.writeln('Total Expenses Count,${expenses.length}');
    csvBuffer.writeln('');

    csvBuffer.writeln('Date,Category,Expense Title,Amount (Rs),Notes');

    double totalAmount = 0.0;
    for (final exp in expenses) {
      totalAmount += exp.amount;
      final dateStr = DateFormat('yyyy-MM-dd').format(exp.date);

      csvBuffer.writeln([
        dateStr,
        _escapeCsv(exp.category),
        _escapeCsv(exp.title),
        exp.amount.toStringAsFixed(2),
        _escapeCsv(exp.notes),
      ].join(','));
    }

    csvBuffer.writeln('');
    csvBuffer.writeln(',,TOTAL EXPENSES,${totalAmount.toStringAsFixed(2)},');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/FoodBillX_Expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvBuffer.toString());

    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: '$businessName Expenses Register CSV');
  }

  /// Exports official Sales & Orders ledger as a multi-page PDF document
  static Future<void> exportOrdersToPdf(List<OrderModel> orders, String businessName) async {
    final pdf = pw.Document();

    double totalSales = 0.0;
    for (final o in orders) {
      totalSales += o.grandTotal;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
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
                    pw.Text('Sales & Orders Ledger', style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(
                  'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Divider(thickness: 1, height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Bills: ${orders.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('Total Sales: ${_formatPdfCurrency(totalSales)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.orange900)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['Order #', 'Date/Time', 'Customer', 'Payment', 'Amount'],
              data: orders.map((o) {
                final dateStr = DateFormat('dd/MM HH:mm').format(o.createdAt);
                return [
                  o.orderNumber,
                  dateStr,
                  o.customerName,
                  o.paymentMethod.toUpperCase(),
                  _formatPdfCurrency(o.grandTotal),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text('FoodBillX POS Engine - Official Sales Ledger', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/FoodBillX_Orders_Ledger_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: '$businessName Sales & Orders Register PDF');
  }

  /// Exports full Customer Directory with contact info & loyalty status to Excel / CSV
  static Future<void> exportCustomersToExcel(List<CustomerModel> customers, String businessName) async {
    final StringBuffer csvBuffer = StringBuffer();

    csvBuffer.writeln('FoodBillX - Customer Directory & Loyalty Register');
    csvBuffer.writeln('Business Name,$businessName');
    csvBuffer.writeln('Export Date,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    csvBuffer.writeln('Total Customers,${customers.length}');
    csvBuffer.writeln('');

    csvBuffer.writeln(
      'Customer Name,Phone Number,Address,Loyalty Card,Total Visits,Total Spent (Rs),Loyalty Points,Notes',
    );

    double totalRevenue = 0.0;
    int totalVisits = 0;

    for (final cust in customers) {
      totalRevenue += cust.totalSpent;
      totalVisits += cust.totalVisits;

      csvBuffer.writeln([
        _escapeCsv(cust.name),
        _escapeCsv(cust.phone),
        _escapeCsv(cust.address),
        _escapeCsv(cust.loyaltyCardNumber),
        cust.totalVisits.toString(),
        cust.totalSpent.toStringAsFixed(2),
        cust.loyaltyPoints.toString(),
        _escapeCsv(cust.notes),
      ].join(','));
    }

    csvBuffer.writeln('');
    csvBuffer.writeln(',,,,TOTAL VISITS,$totalVisits,TOTAL SPENT,${totalRevenue.toStringAsFixed(2)}');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/FoodBillX_Customers_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvBuffer.toString());

    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: '$businessName Customer Directory CSV');
  }

  /// Exports Customer Directory as a multi-page PDF document
  static Future<void> exportCustomersToPdf(List<CustomerModel> customers, String businessName) async {
    final pdf = pw.Document();

    double totalSpent = 0.0;
    for (final c in customers) {
      totalSpent += c.totalSpent;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
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
                    pw.Text('Customer Directory & Loyalty Ledger', style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text(
                  'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Divider(thickness: 1, height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Registered Customers: ${customers.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('Total Cumulative Spent: ${_formatPdfCurrency(totalSpent)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.orange900)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['Customer Name', 'Phone', 'Card #', 'Visits', 'Total Spent', 'Points'],
              data: customers.map((c) {
                return [
                  c.name,
                  c.phone,
                  c.loyaltyCardNumber.isNotEmpty ? c.loyaltyCardNumber : '-',
                  '${c.totalVisits}',
                  _formatPdfCurrency(c.totalSpent),
                  '${c.loyaltyPoints}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text('FoodBillX POS Engine - Customer Directory', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/FoodBillX_Customers_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: '$businessName Customer Directory PDF');
  }

  /// Robust RFC 4180 CSV parser supporting quotes, commas, escaped quotes and multi-line values
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

  /// Parses and imports customer records from CSV into local SQLite
  static Future<int> importCustomersFromCsv(String csvContent) async {
    final rows = parseCsv(csvContent);
    if (rows.length < 2) return 0;

    final header = rows.first.map((h) => h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
    final nameIdx = header.indexWhere((h) => h.contains('name') || h.contains('customer'));
    final phoneIdx = header.indexWhere((h) => h.contains('phone') || h.contains('mobile') || h.contains('contact'));
    final addrIdx = header.indexWhere((h) => h.contains('address') || h.contains('location'));
    final cardIdx = header.indexWhere((h) => h.contains('card') || h.contains('loyalty'));
    final visitsIdx = header.indexWhere((h) => h.contains('visit') || h.contains('count'));
    final spentIdx = header.indexWhere((h) => h.contains('spent') || h.contains('total') || h.contains('amount'));
    final ptsIdx = header.indexWhere((h) => h.contains('point') || h.contains('pts'));
    final notesIdx = header.indexWhere((h) => h.contains('note') || h.contains('comment'));

    int count = 0;
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final name = nameIdx >= 0 && nameIdx < row.length ? row[nameIdx] : (row.isNotEmpty ? row[0] : '');
      final phone = phoneIdx >= 0 && phoneIdx < row.length ? row[phoneIdx] : (row.length > 1 ? row[1] : '');
      if (name.trim().isEmpty && phone.trim().isEmpty) continue;

      final address = addrIdx >= 0 && addrIdx < row.length ? row[addrIdx] : '';
      final card = cardIdx >= 0 && cardIdx < row.length ? row[cardIdx] : '';
      final visits = visitsIdx >= 0 && visitsIdx < row.length ? int.tryParse(row[visitsIdx]) ?? 0 : 0;
      final spent = spentIdx >= 0 && spentIdx < row.length ? double.tryParse(row[spentIdx]) ?? 0.0 : 0.0;
      final pts = ptsIdx >= 0 && ptsIdx < row.length ? int.tryParse(row[ptsIdx]) ?? 0 : 0;
      final notes = notesIdx >= 0 && notesIdx < row.length ? row[notesIdx] : '';

      await LocalDatabase.instance.insertCustomer({
        'name': name.isEmpty ? 'Customer ${phone.isNotEmpty ? phone : i}' : name,
        'phone': phone,
        'address': address,
        'loyaltyCardNumber': card,
        'totalVisits': visits,
        'totalSpent': spent,
        'loyaltyPoints': pts,
        'notes': notes,
      });
      count++;
    }
    return count;
  }

  /// Parses and imports order records from CSV into local SQLite
  static Future<int> importOrdersFromCsv(String csvContent) async {
    final rows = parseCsv(csvContent);
    if (rows.length < 2) return 0;

    final header = rows.first.map((h) => h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
    final numIdx = header.indexWhere((h) => h.contains('order') || h.contains('bill') || h.contains('invoice'));
    final nameIdx = header.indexWhere((h) => h.contains('customer') || h.contains('client') || h.contains('name'));
    final phoneIdx = header.indexWhere((h) => h.contains('phone') || h.contains('mobile'));
    final totalIdx = header.indexWhere((h) => h.contains('grand') || h.contains('total') || h.contains('amount'));
    final subtotalIdx = header.indexWhere((h) => h.contains('subtotal') || h.contains('sub'));
    final payIdx = header.indexWhere((h) => h.contains('payment') || h.contains('method') || h.contains('mode'));
    final itemsIdx = header.indexWhere((h) => h.contains('item') || h.contains('dishes') || h.contains('summary'));

    int count = 0;
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final orderNum = numIdx >= 0 && numIdx < row.length ? row[numIdx] : '';
      final custName = nameIdx >= 0 && nameIdx < row.length ? row[nameIdx] : 'Guest';
      final custPhone = phoneIdx >= 0 && phoneIdx < row.length ? row[phoneIdx] : '';
      final grandTotal = totalIdx >= 0 && totalIdx < row.length ? double.tryParse(row[totalIdx]) ?? 0.0 : 0.0;
      final subtotal = subtotalIdx >= 0 && subtotalIdx < row.length ? double.tryParse(row[subtotalIdx]) ?? grandTotal : grandTotal;
      final paymentMethod = payIdx >= 0 && payIdx < row.length ? row[payIdx] : 'cash';
      final itemsSummary = itemsIdx >= 0 && itemsIdx < row.length ? row[itemsIdx] : 'Sales Items';

      if (grandTotal <= 0 && orderNum.isEmpty) continue;

      final items = [
        OrderItemModel(
          menuItemId: 'imported_$i',
          name: itemsSummary.isNotEmpty ? itemsSummary : 'Imported Item',
          quantity: 1,
          price: subtotal > 0 ? subtotal : grandTotal,
          subtotal: subtotal > 0 ? subtotal : grandTotal,
        ),
      ];

      await LocalDatabase.instance.insertOrder(
        orderNumber: orderNum.isNotEmpty ? orderNum : null,
        customerName: custName.isNotEmpty ? custName : 'Guest',
        customerPhone: custPhone,
        items: items,
        subtotal: subtotal,
        discountAmount: 0.0,
        gstAmount: 0.0,
        serviceChargeAmount: 0.0,
        grandTotal: grandTotal,
        paymentMethod: paymentMethod.isNotEmpty ? paymentMethod : 'cash',
        notes: 'Imported from CSV',
      );
      count++;
    }
    return count;
  }
}
