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
    required String orderNumber,
    required DateTime orderDate,
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double gstAmount,
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
                      pw.Text('Phone: $businessPhone'),
                      if (businessAddress.isNotEmpty)
                        pw.Text('Address: $businessAddress'),
                      if (gstin.isNotEmpty) pw.Text('GSTIN: $gstin'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Invoice #: $orderNumber'),
                      pw.Text(
                        'Date: ${orderDate.day}/${orderDate.month}/${orderDate.year} ${orderDate.hour}:${orderDate.minute}',
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, height: 24),

              // Customer Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Customer: $customerName'),
                  if (customerPhone.isNotEmpty)
                    pw.Text('Phone: $customerPhone'),
                  pw.Text('Payment: ${paymentMethod.toUpperCase()}'),
                ],
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
                    '₹${item['price']}',
                    '₹${item['subtotal']}',
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
                            pw.Text('₹${subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (discount > 0) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount:'),
                              pw.Text('- ₹${discount.toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('GST Tax:'),
                            pw.Text('+ ₹${gstAmount.toStringAsFixed(2)}'),
                          ],
                        ),
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
                              '₹${grandTotal.toStringAsFixed(2)}',
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
                      'Thank you for dining with us!',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'FoodBillX Mobile POS Engine',
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
          'Here is your invoice #$orderNumber from our food outlet. Thank you for your visit!',
    );
  }
}
