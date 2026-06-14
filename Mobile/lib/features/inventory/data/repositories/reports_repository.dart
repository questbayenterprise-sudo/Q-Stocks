import '../../../../core/database/database_helper.dart';

class ReportsRepository {
  Future<Map<String, dynamic>> getSummaryReport({String? shopId, DateTime? start, DateTime? end}) async {
    final db = await DatabaseHelper.instance.database;
    String dateFilter = "";
    List<dynamic> args = [];

    if (start != null && end != null) {
      dateFilter = " AND created_at BETWEEN ? AND ?";
      args.addAll([start.toIso8601String(), end.toIso8601String()]);
    }

    final sales = await db.rawQuery('SELECT SUM(total_amount) as total, SUM(paid_amount) as paid FROM orders WHERE 1=1 $dateFilter', args);
    final dues = await db.rawQuery('SELECT SUM(current_balance) as total FROM customers');

    return {
      'total_sales': sales.first['total'] ?? 0.0,
      'total_received': sales.first['paid'] ?? 0.0,
      'total_dues': dues.first['total'] ?? 0.0,
    };
  }
  Future<List<Map<String, dynamic>>> getDetailedSalesReport({DateTime? start, DateTime? end}) async {
    final db = await DatabaseHelper.instance.database;
    String dateFilter = "";
    List<dynamic> args = [];

    if (start != null && end != null) {
      dateFilter = " WHERE o.created_at BETWEEN ? AND ?";
      args.addAll([start.toIso8601String(), end.toIso8601String()]);
    }

    return await db.rawQuery('''
      SELECT o.order_ref, o.created_at, c.name as customer_name, 
             o.total_amount, o.paid_amount, o.balance_due
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      $dateFilter
      ORDER BY o.created_at DESC
    ''', args);
  }
}