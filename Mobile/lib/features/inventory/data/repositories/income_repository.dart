import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class IncomeRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<void> recordPayment({
    required String customerId,
    required String shopId,
    required double amountPaid,
    required int paymodeId,
    String? remarks,
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      // 1. Get current balance of the customer
      final List<Map<String, dynamic>> res = await txn.query(
        'customers',
        columns: ['current_balance'],
        where: 'id = ?',
        whereArgs: [customerId],
      );
      
      double currentBal = double.tryParse(res.first['current_balance'].toString()) ?? 0.0;
      
      // 2. Calculate NEW Running Balance (Reduction)
      double newBalance = currentBal - amountPaid;

      // 3. Insert into customer_ledger (The Notebook Entry)
      await txn.insert('customer_ledger', {
        'customer_id': customerId,
        'shop_id': shopId,
        'transaction_date': DateTime.now().toIso8601String(),
        'weight': 0,          // No weight for payment
        'rate': 0,            // No rate for payment
        'debit_amount': 0,    // No sale amount
        'credit_amount': amountPaid, // "Paid" column in your sketch
        'running_balance': newBalance,
        'paymode_id': paymodeId,
        'remarks': remarks ?? "Payment Received",
      });

      // 4. Update the Master Customer table
      await txn.update(
        'customers',
        {'current_balance': newBalance},
        where: 'id = ?',
        whereArgs: [customerId],
      );
    });
  }
}