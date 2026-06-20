import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';

class SettingsRepository {
  Future<Map<String, dynamic>> getGeneralSettings() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('tbl_general_settings', limit: 1);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return {
      'currency_symbol': '₹',
      'low_stock_limit': 5.0,
    };
  }
}