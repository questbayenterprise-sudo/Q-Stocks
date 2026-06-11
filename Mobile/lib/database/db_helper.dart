// lib/database/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  initDb() async {
    String path = join(await getDatabasesPath(), "bookings.db");
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE bookings (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          court_id INTEGER,
          slot_id INTEGER
        )
      ''');
    });
  }
  
  // Add your Insert/Query methods here...
}