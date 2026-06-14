import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class StocksRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Get current stock levels for a specific shop
  Future<List<Map<String, dynamic>>> getShopStocks(String shopId) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT p.name, p.uom, s.current_qty, s.product_id, s.min_stock_lvl
      FROM products p
      LEFT JOIN stocks s ON p.id = s.product_id AND s.shop_id = ?
      WHERE p.is_active = 1
    ''', [shopId]);
  }

  // Add or Adjust Stock (Manual Entry)
  Future<void> updateStock({
    required String shopId,
    required String productId,
    required double quantity,
    required String type, // 'IN' or 'WASTE'
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      // 1. Check if record exists
      final List<Map<String, dynamic>> existing = await txn.query(
        'stocks', 
        where: 'shop_id = ? AND product_id = ?', 
        whereArgs: [shopId, productId]
      );

      if (existing.isEmpty) {
        await txn.insert('stocks', {
          'shop_id': shopId,
          'product_id': productId,
          'current_qty': quantity,
        });
      } else {
        double newQty = type == 'IN' 
            ? (existing.first['current_qty'] + quantity) 
            : (existing.first['current_qty'] - quantity);
        
        await txn.update('stocks', {'current_qty': newQty}, 
            where: 'shop_id = ? AND product_id = ?', whereArgs: [shopId, productId]);
      }

      // 2. Log the movement
      await txn.insert('stock_logs', {
        'stock_id': existing.isNotEmpty ? existing.first['id'] : null,
        'change_qty': quantity,
        'log_type': type,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }
}