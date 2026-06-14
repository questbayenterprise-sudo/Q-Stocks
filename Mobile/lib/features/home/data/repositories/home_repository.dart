import '../../../../core/config/app_config.dart';
import '../../../../core/database/database_helper.dart';
import '../models/home_data.dart';

class HomeRepository {
  final _dbHelper = DatabaseHelper.instance;

  Future<ShopAnalytics> fetchAnalytics(String userId, String userType) async {
    if (AppConfig.isCloudDb) {
      // TODO: Implement Cloud API call via http.post
      return ShopAnalytics(
        totalSales: 0, 
        totalStockValue: 0, 
        customerDues: 0, 
        weeklyTrend: []
      );
    } else {
      final db = await _dbHelper.database;
      
      // 1. Fetch Totals with COALESCE to avoid nulls if tables are empty
      final salesData = await db.rawQuery('SELECT SUM(total_amount) as total FROM orders');
      final stockData = await db.rawQuery('SELECT SUM(current_qty) as total FROM stocks'); 
      final dueData = await db.rawQuery('SELECT SUM(current_balance) as total FROM customers');

      // 2. Fetch Weekly Trend (Last 7 Days)
      // Logic: Group by date and count orders
      final trendData = await db.rawQuery('''
        SELECT strftime('%d/%m', created_at) as day, COUNT(*) as count 
        FROM orders 
        WHERE created_at > date('now', '-7 days')
        GROUP BY day
        ORDER BY created_at ASC
      ''');

      return ShopAnalytics(
        // Use null-aware operators to handle empty tables
        totalSales: double.tryParse(salesData.first['total']?.toString() ?? '0.0') ?? 0.0,
        totalStockValue: double.tryParse(stockData.first['total']?.toString() ?? '0.0') ?? 0.0,
        customerDues: double.tryParse(dueData.first['total']?.toString() ?? '0.0') ?? 0.0,
        weeklyTrend: trendData.map((e) => WeeklyTrend(
          day: e['day'].toString(), 
          count: int.tryParse(e['count'].toString()) ?? 0
        )).toList(),
      );
    }
  }

  Future<List<RecentSale>> fetchRecentSales() async {
    if (AppConfig.isCloudDb) {
      // TODO: Implement Cloud API call
      return [];
    } else {
      final db = await _dbHelper.database;
      
      // Join orders with customers to get the name
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT 
          o.order_ref, 
          COALESCE(c.name, 'Walk-in') as customer_name, 
          o.total_amount as amount, 
          o.created_at as date
        FROM orders o
        LEFT JOIN customers c ON o.customer_id = c.id
        ORDER BY o.created_at DESC 
        LIMIT 5
      ''');

      return maps.map((e) => RecentSale.fromJson(e)).toList();
    }
  }
}