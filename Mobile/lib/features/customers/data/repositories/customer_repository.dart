import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/database/database_helper.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final String baseUrl = AppConfig.baseUrl;

  // Helper to get the database instance
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // 1. Save Customer (Add or Edit)
  Future<void> saveCustomer(CustomerModel customer) async {
    if (AppConfig.isCloudDb) {
      // --- CLOUD LOGIC ---
      final isUpdate = customer.id != "0";
      final url = Uri.parse(isUpdate ? '$baseUrl/UpdateCustomer' : '$baseUrl/CreateCustomer');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'id': customer.id,
          'name': customer.name,
          'phone': customer.phone,
          'usertype': 'Customer',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to save customer to cloud");
      }
    } else {
      // --- LOCAL SQLITE LOGIC ---
      final db = await _db;
      bool isUpdate = customer.id != "0" && customer.id.isNotEmpty;

      final data = {
        'name': customer.name,
        'phone': customer.phone,
        'is_active': 1,
      };

      if (isUpdate) {
        await db.update('customers', data, where: 'id = ?', whereArgs: [customer.id]);
      } else {
        // Initial values for a new customer
        data['current_balance'] = 0.0;
        data['opening_balance'] = 0.0;
        data['created_at'] = DateTime.now().toIso8601String();
        await db.insert('customers', data);
      }
    }
  }

  // 2. Soft Delete Customer (Deactivate)
  Future<void> deleteCustomer(String id) async {
    if (AppConfig.isCloudDb) {
      // --- CLOUD LOGIC ---
      final response = await http.post(
        Uri.parse('$baseUrl/DeleteCustomer'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'id': id}),
      );
      if (response.statusCode != 200) throw Exception("Cloud delete failed");
    } else {
      // --- LOCAL SQLITE LOGIC ---
      final db = await _db;
      // We set is_active to 0 so we don't break the Ledger history
      await db.update('customers', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
    }
  }

  // 3. Fetch All Active Customers
  Future<List<CustomerModel>> fetchCustomers() async {
    if (AppConfig.isCloudDb) {
      // --- CLOUD LOGIC ---
      final response = await http.get(Uri.parse('$baseUrl/GetAllCustomers'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List rows = data['data'] ?? [];
        return rows.map((json) => CustomerModel.fromMap(json)).toList();
      }
      throw Exception("Failed to fetch customers from server");
    } else {
      // --- LOCAL SQLITE LOGIC ---
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers', 
        where: 'is_active = 1', 
        orderBy: 'name ASC'
      );
      return maps.map((e) => CustomerModel.fromMap(e)).toList();
    }
  }

  // 4. Quick Add Customer (Used in Sales Searchable Dropdown)
  Future<CustomerModel> quickAddCustomer(String name) async {
    if (AppConfig.isCloudDb) {
      // --- CLOUD LOGIC ---
      final response = await http.post(
        Uri.parse('$baseUrl/CreateCustomer'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'name': name, 'phone': '', 'balance': 0.0}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return CustomerModel.fromMap(data['data']);
      }
      throw Exception(data['message'] ?? "Quick add failed");
    } else {
      // --- LOCAL SQLITE LOGIC ---
      final db = await _db;
      int id = await db.insert('customers', {
        'name': name,
        'phone': '',
        'current_balance': 0.0,
        'opening_balance': 0.0,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });

      // FIXED: Included all required parameters to match CustomerModel constructor
      return CustomerModel(
        id: id.toString(), 
        name: name, 
        phone: '', 
        currentBalance: 0.0
      );
    }
  }

  // 5. Fetch specific Customer Transaction History (The "Notebook" Query)
  Future<List<Map<String, dynamic>>> fetchCustomerLedger(String customerId) async {
    final db = await _db;
    
    // We use a query to get all ledger entries for this customer
    return await db.query(
      'customer_ledger',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'transaction_date DESC',
    );
  }

  // 6. Fetch only customers who owe money (For the Pending Payments page)
  Future<List<Map<String, dynamic>>> fetchPendingPayments() async {
    final db = await _db;
    return await db.query(
      'customers',
      where: 'current_balance > 0 AND is_active = 1',
      orderBy: 'current_balance DESC',
    );
  }
}