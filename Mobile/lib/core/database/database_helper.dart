import 'dart:async';
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
      // Splitting by semicolon followed by a newline is safer for large scripts
      final List<String> queries = script.split(RegExp(r';\s*\n'));

      await db.transaction((txn) async {
        for (String query in queries) {
          if (query.trim().isNotEmpty) {
            await txn.execute(query);
          }
        }
      });
      print("Database and Seed data initialized successfully.");
    } catch (e) {
      print("Error during database creation: $e");
    }
  }
}