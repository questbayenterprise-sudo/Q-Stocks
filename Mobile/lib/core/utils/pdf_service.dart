import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> exportSalesReport({
    required List<Map<String, dynamic>> salesData,
    required String fileName,
    required String period,
    String? customerName,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat('#,##,###.00');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // 1. HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("SALES STATEMENT",
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                  pw.SizedBox(height: 4),
                  pw.Text("Period: $period"),
                  if (customerName != null) pw.Text("Customer: $customerName"),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Broiler Shop Management", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Generated on: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}"),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 2, color: PdfColors.grey300),
          pw.SizedBox(height: 20),

          // 2. DATA TABLE
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // Date
              1: const pw.FlexColumnWidth(2), // Invoice
              2: const pw.FlexColumnWidth(3), // Customer
              3: const pw.FixedColumnWidth(80), // Total
              4: const pw.FixedColumnWidth(80), // Paid
              5: const pw.FixedColumnWidth(80), // Balance
            },
            headers: ['Date', 'Invoice #', 'Customer', 'Total', 'Paid', 'Balance'],
            data: salesData.map((sale) {
              return [
                sale['created_at'].toString().split('T')[0],
                sale['order_ref'] ?? "N/A",
                sale['customer_name'] ?? "Walk-in",
                currencyFormat.format(sale['total_amount'] ?? 0),
                currencyFormat.format(sale['paid_amount'] ?? 0),
                currencyFormat.format(sale['balance_due'] ?? 0),
              ];
            }).toList(),
          ),

          // 3. FOOTER SUMMARY
          pw.SizedBox(height: 20),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),
                _buildSummaryLine("Total Sales:", salesData.fold(0.0, (s, i) => s + (i['total_amount'] ?? 0)), currencyFormat),
                _buildSummaryLine("Total Collected:", salesData.fold(0.0, (s, i) => s + (i['paid_amount'] ?? 0)), currencyFormat),
                pw.SizedBox(height: 5),
                pw.Text(
                  "Grand Balance: ${currencyFormat.format(salesData.fold(0.0, (s, i) => s + (i['balance_due'] ?? 0)))}",
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Show Preview/Print/Share dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  static pw.Widget _buildSummaryLine(String label, double amount, NumberFormat format) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text("$label ", style: const pw.TextStyle(fontSize: 12)),
        pw.Text("INR ${format.format(amount)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
