import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class IncomeRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // 1. Fetch all Income/Payment records
  Future<List<Map<String, dynamic>>> fetchIncomes() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT l.*, c.name as customer_name 
      FROM customer_ledger l
      JOIN customers c ON l.customer_id = c.id
      WHERE l.credit_amount > 0
      ORDER BY l.transaction_date DESC
    ''');
  }

  // 2. Record New Payment (Corrected with remarks)
  Future<void> recordPayment({
    required String customerId,
    required String shopId,
    required double amountPaid,
    required int paymodeId,
    String? remarks, // Added to fix the 'undefined_named_parameter' error
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Get current balance
      final List<Map<String, dynamic>> res = await txn.query(
        'customers', 
        columns: ['current_balance'], 
        where: 'id = ?', 
        whereArgs: [customerId]
      );
      
      double currentBal = double.tryParse(res.first['current_balance'].toString()) ?? 0.0;
      double newBalance = currentBal - amountPaid;

      // Insert into ledger (Notebook view)
      await txn.insert('customer_ledger', {
        'customer_id': customerId,
        'shop_id': shopId,
        'transaction_date': DateTime.now().toIso8601String(),
        'debit_amount': 0,
        'credit_amount': amountPaid,
        'running_balance': newBalance,
        'paymode_id': paymodeId,
        'remarks': remarks ?? "Payment Received",
      });

      // Update master balance
      await txn.update(
        'customers', 
        {'current_balance': newBalance}, 
        where: 'id = ?', 
        whereArgs: [customerId]
      );
    });
  }

  // 3. Delete Payment (With Balance Reversal)
  Future<void> deleteIncome(int ledgerId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> ledger = await txn.query(
        'customer_ledger', 
        where: 'id = ?', 
        whereArgs: [ledgerId]
      );
      if (ledger.isEmpty) return;

      double amountToReverse = double.tryParse(ledger.first['credit_amount'].toString()) ?? 0.0;
      int customerId = ledger.first['customer_id'];

      // Add the money back to the customer's debt
      await txn.rawUpdate(
        'UPDATE customers SET current_balance = current_balance + ? WHERE id = ?', 
        [amountToReverse, customerId]
      );

      await txn.delete('customer_ledger', where: 'id = ?', whereArgs: [ledgerId]);
    });
  }
}