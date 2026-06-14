import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart'; // ADD THIS
import '../../../../core/config/app_config.dart';
import '../../../../core/database/database_helper.dart';
import '../../../auth/Session/user_session.dart';
import '../models/shop_model.dart';

class ShopRepository {
  final String baseUrl = AppConfig.baseUrl;

  // Use this getter for all local DB calls to ensure optimization
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<ShopModel>> fetchShops() async {
    final session = UserSession();
    final String currentUserId = session.userId ?? '0';

    if (AppConfig.isCloudDb) {
      final url = Uri.parse('$baseUrl/Venue_overall_list');
      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": currentUserId,
            "user_type": session.userType?.name ?? "user",
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List rows = data['rows'] ?? [];
          return rows.map((json) => ShopModel.fromMap(json)).toList();
        }
      } catch (e) {
        throw Exception("Cloud connection error: $e");
      }
      throw Exception("Failed to load shops from cloud");
    } else {
      // --- LOCAL SQLITE LOGIC ---
      final db = await _db;
      
      List<Map<String, dynamic>> maps;
      if (session.userType == UserType.admin) {
        // Admins see everything
        maps = await db.query('shops', where: 'is_active = 1');
      } else {
        // Staff/Owners see only what is mapped to them
        maps = await db.rawQuery('''
          SELECT s.* FROM shops s
          INNER JOIN shop_user_mapping m ON s.id = m.shop_id
          WHERE m.user_id = ? AND s.is_active = 1 AND m.is_active = 1
        ''', [currentUserId]);
      }
      return maps.map((e) => ShopModel.fromMap(e)).toList();
    }
  }

  Future<void> saveShop(ShopModel shop) async {
    final session = UserSession();
    final String currentUserId = session.userId ?? '0';
    final bool isUpdate = shop.id.isNotEmpty && shop.id != "0";

    if (AppConfig.isCloudDb) {
      final url = Uri.parse(isUpdate ? '$baseUrl/UpdateVenue' : '$baseUrl/InsertVenue');
      var request = http.MultipartRequest('POST', url);
      
      if (isUpdate) request.fields['id'] = shop.id;
      request.fields['userid'] = currentUserId;
      request.fields['name'] = shop.name;
      request.fields['location'] = shop.locationName;
      request.fields['price'] = shop.price.toString();
      request.fields['description'] = shop.description;

      if (shop.imageUrl.isNotEmpty && File(shop.imageUrl).existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('image', shop.imageUrl));
      } else {
        request.fields['existing_image'] = shop.imageUrl;
      }

      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);
      if (res.statusCode != 200) {
        final errorData = jsonDecode(res.body);
        throw Exception(errorData['message'] ?? "Cloud Save Failed");
      }
    } else {
      // --- LOCAL SQLITE LOGIC ---
      final db = await _db;
      final shopData = shop.toMap();
      shopData['created_by'] = currentUserId;

      if (isUpdate) {
        await db.update('shops', shopData, where: 'id = ?', whereArgs: [shop.id]);
      } else {
        // Use a transaction for atomic insert + mapping
        await db.transaction((txn) async {
          // 1. Insert Shop
          int newShopId = await txn.insert('shops', shopData);
          
          // 2. Auto-map to current user (Owner/Admin)
          // Crucial: Use 'txn' instead of 'db' inside the transaction block
          await txn.insert('shop_user_mapping', {
            'user_id': int.tryParse(currentUserId) ?? 0,
            'shop_id': newShopId,
            'is_active': 1
          });
        });
      }
    }
  }

  Future<void> deleteShop(String id) async {
    if (AppConfig.isCloudDb) {
      final response = await http.post(
        Uri.parse('$baseUrl/DeleteVenue'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );
      if (response.statusCode != 200) throw Exception("Delete failed on server");
    } else {
      final db = await _db;
      // Perform Soft Delete
      await db.update(
        'shops', 
        {'is_active': 0}, 
        where: 'id = ?', 
        whereArgs: [id]
      );
    }
  }
}