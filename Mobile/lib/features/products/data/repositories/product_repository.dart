import 'package:sqflite/sqflite.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/database/database_helper.dart';
import '../models/product_model.dart';

class ProductRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<ProductModel>> fetchProducts() async {
    if (AppConfig.isCloudDb) {
      return [];
    } else {
      final db = await _db;
      
      // DEBUG: Check total count regardless of is_active
      final allRows = await db.rawQuery('SELECT COUNT(*) as cnt FROM products');
      print("DB DEBUG: Total products in table: ${allRows.first['cnt']}");

      final List<Map<String, dynamic>> maps = await db.query('products', where: 'is_active = 1');
      print("DB DEBUG: Rows with is_active=1: ${maps.length}");

      return maps.map((e) => ProductModel.fromMap(e)).toList();
    }
  }

  Future<void> saveProduct(ProductModel product) async {
    if (AppConfig.isCloudDb) {
      // Cloud Implementation (http.post)
    } else {
      final db = await _db;
      final data = product.toMap();
      if (product.id != "0") {
        await db.update('products', data, where: 'id = ?', whereArgs: [product.id]);
      } else {
        await db.insert('products', data);
      }
    }
  }

  Future<void> deleteProduct(String id) async {
    final db = await _db;
    await db.update('products', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
  }
}