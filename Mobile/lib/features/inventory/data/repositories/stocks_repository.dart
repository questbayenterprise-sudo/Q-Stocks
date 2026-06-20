import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class StocksRepository {
  // Access the singleton database instance
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  /// 1. Fetch current stock levels for a specific shop
  /// Returns product details merged with stock data
  Future<List<Map<String, dynamic>>> getShopStocks(String shopId) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT 
        s.id as stock_id, 
        p.id as product_id, 
        p.name, 
        p.uom, 
        COALESCE(s.current_qty, 0) as current_qty, 
        COALESCE(s.min_stock_lvl, 5) as min_stock_lvl
      FROM products p
      INNER JOIN stocks s ON p.id = s.product_id
      WHERE s.shop_id = ? AND p.is_active = 1
    ''', [shopId]);
  }

  /// 2. Add or Update Stock Level (Absolute Value)
  /// Used by the "Edit" dialog to set specific quantities
  Future<void> saveStock({
    required String shopId,
    required String productId,
    required double quantity,
    required double minLevel,
  }) async {
    final db = await _db;
    await db.insert(
      'stocks',
      {
        'shop_id': shopId,
        'product_id': productId,
        'current_qty': quantity,
        'min_stock_lvl': minLevel,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 3. Adjust Stock (Relative Value)
  /// Used for "Stock In" (Purchases) or "Waste" (Death/Damage)
  Future<void> updateStock({
    required String shopId,
    required String productId,
    required double changeQty,
    required String type, // 'IN' or 'WASTE'
    String? remarks,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      // 1. Check if record exists in this shop
      final List<Map<String, dynamic>> existing = await txn.query(
        'stocks',
        where: 'shop_id = ? AND product_id = ?',
        whereArgs: [shopId, productId],
      );

      int stockId;
      double currentQty = 0;

      if (existing.isEmpty) {
        // Create new stock entry if it doesn't exist
        currentQty = (type == 'IN') ? changeQty : -changeQty;
        stockId = await txn.insert('stocks', {
          'shop_id': shopId,
          'product_id': productId,
          'current_qty': currentQty,
          'min_stock_lvl': 5.0, // Default
        });
      } else {
        // Update existing quantity
        stockId = existing.first['id'];
        double oldQty = double.tryParse(existing.first['current_qty'].toString()) ?? 0.0;
        currentQty = (type == 'IN') ? (oldQty + changeQty) : (oldQty - changeQty);

        await txn.update(
          'stocks',
          {'current_qty': currentQty},
          where: 'id = ?',
          whereArgs: [stockId],
        );
      }

      // 2. Log the movement for reports
      await txn.insert('stock_logs', {
        'stock_id': stockId,
        'change_qty': (type == 'IN') ? changeQty : -changeQty,
        'log_type': type,
        'remarks': remarks ?? (type == 'IN' ? "Purchase Restock" : "Wastage/Adjustment"),
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  /// 4. Remove a product from a shop's stock list
  Future<void> deleteStock(int stockId) async {
    final db = await _db;
    await db.delete(
      'stocks',
      where: 'id = ?',
      whereArgs: [stockId],
    );
  }

  /// 5. Fetch Stock History (For Audit/Reports)
  Future<List<Map<String, dynamic>>> getStockLogs(String shopId) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT l.*, p.name as product_name, p.uom
      FROM stock_logs l
      JOIN stocks s ON l.stock_id = s.id
      JOIN products p ON s.product_id = p.id
      WHERE s.shop_id = ?
      ORDER BY l.created_at DESC
    ''', [shopId]);
  }
  // Fetch all stocks across all shops
  Future<List<Map<String, dynamic>>> getAllShopsStocks() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT 
        s.id as stock_id, 
        p.id as product_id, 
        p.name as product_name, 
        sh.name as shop_name,
        sh.id as shop_id,
        p.uom, 
        COALESCE(s.current_qty, 0) as current_qty, 
        COALESCE(s.min_stock_lvl, 5) as min_stock_lvl
      FROM stocks s
      JOIN products p ON s.product_id = p.id
      JOIN shops sh ON s.shop_id = sh.id
      WHERE p.is_active = 1
      ORDER BY sh.name ASC, p.name ASC
    ''');
  }
}