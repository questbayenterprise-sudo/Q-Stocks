import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('broiler_shop_v1.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }
Future _createDB(Database db, int version) async {
    try {
      final String script = await rootBundle.loadString('assets/sql/init_db.sql');
      
      // Split script into queries
      final List<String> queries = script.split(RegExp(r';\s*\n'));

      // OPTIMIZATION: Use a Batch for massive performance gains
      await db.transaction((txn) async {
        final batch = txn.batch(); // Create a batch
        
        for (String query in queries) {
          if (query.trim().isNotEmpty) {
            batch.execute(query); // Queue the query
          }
        }
        
        await batch.commit(noResult: true); // Execute all at once natively
      });
      
      debugPrint("Database logic finished on background thread.");
    } catch (e) {
      debugPrint("DB Init Error: $e");
    }
  }
}