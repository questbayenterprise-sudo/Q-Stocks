import '../../../../core/database/database_helper.dart';

class ReportsRepository {
  // 1. Get Summary for a specific customer or all
  Future<Map<String, dynamic>> getSummaryReport({
    String? customerId, 
    required DateTime start, 
    required DateTime end
  }) async {
    final db = await DatabaseHelper.instance.database;
    String filter = " WHERE created_at BETWEEN ? AND ?";
    List<dynamic> args = [start.toIso8601String(), end.toIso8601String()];

    if (customerId != null && customerId != "0") {
      filter += " AND customer_id = ?";
      args.add(customerId);
    }

    final sales = await db.rawQuery('SELECT SUM(total_amount) as total, SUM(paid_amount) as paid FROM orders $filter', args);
    
    // For dues, we always check current balance from customer table
    double totalDues = 0.0;
    if (customerId != null && customerId != "0") {
      final d = await db.query('customers', columns: ['current_balance'], where: 'id = ?', whereArgs: [customerId]);
      totalDues = double.tryParse(d.first['current_balance'].toString()) ?? 0.0;
    } else {
      final d = await db.rawQuery('SELECT SUM(current_balance) as total FROM customers');
      totalDues = double.tryParse(d.first['total'].toString()) ?? 0.0;
    }

    return {
      'total_sales': sales.first['total'] ?? 0.0,
      'total_received': sales.first['paid'] ?? 0.0,
      'total_dues': totalDues,
    };
  }

  // 2. Fetch rows for Excel Export (Filtered by Customer)
  Future<List<Map<String, dynamic>>> getDetailedSalesReport({
    String? customerId, 
    required DateTime start, 
    required DateTime end
  }) async {
    final db = await DatabaseHelper.instance.database;
    String filter = " WHERE o.created_at BETWEEN ? AND ?";
    List<dynamic> args = [start.toIso8601String(), end.toIso8601String()];

    if (customerId != null && customerId != "0") {
      filter += " AND o.customer_id = ?";
      args.add(customerId);
    }

    return await db.rawQuery('''
      SELECT o.order_ref, o.created_at, COALESCE(c.name, 'Walk-in') as customer_name, 
             o.total_amount, o.paid_amount, o.balance_due
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      $filter
      ORDER BY o.created_at DESC
    ''', args);
  }
  // Get a list of all customers with their total sales, total paid, and pending balance
  Future<List<Map<String, dynamic>>> getCustomerWiseSummary() async {
    final db = await DatabaseHelper.instance.database;
    
    // This query joins customers with their order totals
    return await db.rawQuery('''
      SELECT 
        c.id, 
        c.name, 
        c.phone,
        c.current_balance as pending_balance,
        COALESCE(SUM(o.total_amount), 0) as total_sales,
        COALESCE(SUM(o.paid_amount), 0) as total_paid
      FROM customers c
      LEFT JOIN orders o ON c.id = o.customer_id
      GROUP BY c.id
      ORDER BY c.current_balance DESC
    ''');
  }
}