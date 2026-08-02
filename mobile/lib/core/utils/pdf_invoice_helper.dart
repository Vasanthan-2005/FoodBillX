import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfInvoiceHelper {
  static Future<File> generateInvoicePdf({
    required String businessName,
    required String businessPhone,
    required String businessAddress,
    required String gstin,
    required String invoicePrefix,
    String invoiceFooter = 'Thank you for dining with us!',
    required String orderNumber,
    required DateTime orderDate,
    required String customerName,
    required String customerPhone,
    String loyaltyCardNumber = '',
    int visitCount = 1,
    String rewardStatus = '',
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double gstAmount,
    double serviceChargeAmount = 0,
    required double grandTotal,
    required String paymentMethod,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Business Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        businessName,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (businessPhone.isNotEmpty) pw.Text('Phone: $businessPhone'),
                      if (businessAddress.isNotEmpty) pw.Text('Address: $businessAddress'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'BILL RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Bill #: $orderNumber'),
                      pw.Text(
                        'Date: ${orderDate.day}/${orderDate.month}/${orderDate.year} ${orderDate.hour}:${orderDate.minute}',
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, height: 24),

              // Customer & Loyalty Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Customer: $customerName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        if (customerPhone.isNotEmpty) pw.Text('Phone: $customerPhone'),
                        pw.Text('Payment: ${paymentMethod.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    if (loyaltyCardNumber.isNotEmpty || rewardStatus.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          if (loyaltyCardNumber.isNotEmpty) pw.Text('Loyalty Card #: $loyaltyCardNumber'),
                          pw.Text('Visit Count: #$visitCount'),
                          if (rewardStatus.isNotEmpty)
                            pw.Text('Loyalty Status: $rewardStatus', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Items Table
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Item Description', 'Qty', 'Price', 'Subtotal'],
                data: items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  return [
                    '$idx',
                    item['name'],
                    '${item['quantity']}',
                    'Rs. ${item['price']}',
                    'Rs. ${item['subtotal']}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.orange800,
                ),
                cellHeight: 28,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 16),

              // Summary Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:'),
                            pw.Text('Rs. ${subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (discount > 0) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount:'),
                              pw.Text('- Rs. ${discount.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                        if (serviceChargeAmount > 0) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Service charge:'),
                              pw.Text(
                                '+ Rs. ${serviceChargeAmount.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ],
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Grand Total:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            pw.Text(
                              'Rs. ${grandTotal.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 16,
                                color: PdfColors.orange900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      invoiceFooter,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'HMB Bills POS Engine - Honeymoon Biryani',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final file = File("${outputDir.path}/$orderNumber.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> shareInvoiceViaWhatsApp(
    File pdfFile,
    String customerPhone,
    String orderNumber,
  ) async {
    final xFile = XFile(pdfFile.path);
    await Share.shareXFiles(
      [xFile],
      text:
          'Here is your bill #$orderNumber from Honeymoon Biryani. Thank you for your visit!',
    );
  }
}
