import '../../../../core/database/database_helper.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  Future<List<CustomerModel>> fetchCustomers() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map((e) => CustomerModel.fromMap(e)).toList();
  }

  Future<CustomerModel> quickAddCustomer(String name) async {
    final db = await DatabaseHelper.instance.database;
    int id = await db.insert('customers', {
      'name': name,
      'phone': '',
      'current_balance': 0.0
    });
    return CustomerModel(id: id.toString(), name: name);
  }
}