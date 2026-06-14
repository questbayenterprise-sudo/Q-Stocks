import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:open_file_plus/open_file_plus.dart';

import '../database/database_helper.dart';

class ExcelService {
  static Future<void> exportSalesReport({
    required List<Map<String, dynamic>> salesData,
    required String fileName,
  }) async {
    // 1. Create a workbook
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = "Sales Report";

    // 2. Set Headers
    sheet.getRangeByIndex(1, 1).setText("Order Ref");
    sheet.getRangeByIndex(1, 2).setText("Date");
    sheet.getRangeByIndex(1, 3).setText("Customer");
    sheet.getRangeByIndex(1, 4).setText("Total Amount");
    sheet.getRangeByIndex(1, 5).setText("Paid Amount");
    sheet.getRangeByIndex(1, 6).setText("Balance Due");

    // Style Headers
    final Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.backColor = '#00A36C';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.bold = true;
    sheet.getRangeByName('A1:F1').cellStyle = headerStyle;

    // 3. Add Data Rows
    for (int i = 0; i < salesData.length; i++) {
      final sale = salesData[i];
      int row = i + 2;

      sheet.getRangeByIndex(row, 1).setText(sale['order_ref'] ?? "");
      sheet.getRangeByIndex(row, 2).setText(sale['created_at'] ?? "");
      sheet.getRangeByIndex(row, 3).setText(sale['customer_name'] ?? "Walk-in");
      sheet.getRangeByIndex(row, 4).setNumber(double.tryParse(sale['total_amount'].toString()));
      sheet.getRangeByIndex(row, 5).setNumber(double.tryParse(sale['paid_amount'].toString()));
      sheet.getRangeByIndex(row, 6).setNumber(double.tryParse(sale['balance_due'].toString()));
    }

    // 4. Save and Open
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final String path = (await getApplicationDocumentsDirectory()).path;
    final String fullPath = '$path/$fileName.xlsx';
    final File file = File(fullPath);
    await file.writeAsBytes(bytes, flush: true);

    // Automatically open the file for the user
    await OpenFile.open(fullPath);
  }
  // Inside ReportsRepository
Future<Map<String, dynamic>> getSummaryReport({required DateTime start, required DateTime end}) async {
  final db = await DatabaseHelper.instance.database;
  // Use ISO strings for SQLite comparison
  String s = start.toIso8601String();
  String e = end.toIso8601String();

  final sales = await db.rawQuery('SELECT SUM(total_amount) as total, SUM(paid_amount) as paid FROM orders WHERE created_at BETWEEN ? AND ?', [s, e]);
  final dues = await db.rawQuery('SELECT SUM(current_balance) as total FROM customers');

  return {
    'total_sales': sales.first['total'] ?? 0.0,
    'total_received': sales.first['paid'] ?? 0.0,
    'total_dues': dues.first['total'] ?? 0.0,
  };
}

Future<List<Map<String, dynamic>>> getDetailedSalesReport({required DateTime start, required DateTime end}) async {
  final db = await DatabaseHelper.instance.database;
  return await db.rawQuery('''
    SELECT o.order_ref, o.created_at, c.name as customer_name, o.total_amount, o.paid_amount, o.balance_due
    FROM orders o
    LEFT JOIN customers c ON o.customer_id = c.id
    WHERE o.created_at BETWEEN ? AND ?
    ORDER BY o.created_at DESC
  ''', [start.toIso8601String(), end.toIso8601String()]);
}
}