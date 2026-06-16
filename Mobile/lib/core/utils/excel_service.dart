import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class ExcelService {
  static Future<void> exportSalesReport({
    required List<Map<String, dynamic>> salesData,
    required String fileName,
  }) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    // Set Headers
    sheet.getRangeByIndex(1, 1).setText("Order Ref");
    sheet.getRangeByIndex(1, 2).setText("Date");
    sheet.getRangeByIndex(1, 3).setText("Customer");
    sheet.getRangeByIndex(1, 4).setText("Total Amt");
    sheet.getRangeByIndex(1, 5).setText("Paid Amt");
    sheet.getRangeByIndex(1, 6).setText("Due");

    // Add Rows
    for (int i = 0; i < salesData.length; i++) {
      final sale = salesData[i];
      int row = i + 2;
      sheet.getRangeByIndex(row, 1).setText(sale['order_ref']?.toString());
      sheet.getRangeByIndex(row, 2).setText(sale['created_at']?.toString());
      sheet.getRangeByIndex(row, 3).setText(sale['customer_name']?.toString());
      sheet.getRangeByIndex(row, 4).setNumber(double.tryParse(sale['total_amount'].toString()));
      sheet.getRangeByIndex(row, 5).setNumber(double.tryParse(sale['paid_amount'].toString()));
      sheet.getRangeByIndex(row, 6).setNumber(double.tryParse(sale['balance_due'].toString()));
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getTemporaryDirectory();
    final String fullPath = '${directory.path}/$fileName.xlsx';
    final File file = File(fullPath);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([XFile(fullPath)], subject: 'Shop Sales Report');
  }
}