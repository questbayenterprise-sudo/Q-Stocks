import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/sale_model.dart';

class SalesRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<void> createSale(SaleModel sale) async {
    final db = await _db;

    await db.transaction((txn) async {
      // 1. Generate Order Ref
      final String orderRef = "ORD-${DateTime.now().millisecondsSinceEpoch}";

      // 2. Insert into Orders
      int orderId = await txn.insert('orders', {
        'order_ref': orderRef,
        'shop_id': sale.shopId,
        'customer_id': sale.customerId,
        'total_amount': sale.totalAmount,
        'paid_amount': sale.paidAmount,
        'balance_due': sale.totalAmount - sale.paidAmount,
        'paymode_id': sale.paymodeId,
      });

      // 3. Update Customer Current Balance
      double balanceChange = sale.totalAmount - sale.paidAmount;
      await txn.rawUpdate(
        'UPDATE customers SET current_balance = current_balance + ? WHERE id = ?',
        [balanceChange, sale.customerId]
      );

      // 4. Get New Running Balance for Ledger
      final List<Map<String, dynamic>> res = await txn.query(
        'customers', columns: ['current_balance'], where: 'id = ?', whereArgs: [sale.customerId]
      );
      double runningBal = double.tryParse(res.first['current_balance'].toString()) ?? 0.0;

      // 5. Insert into Ledger (Mirroring your handwritten Notebook)
      await txn.insert('customer_ledger', {
        'customer_id': sale.customerId,
        'shop_id': sale.shopId,
        'order_id': orderId,
        'weight': sale.weight,
        'rate': sale.rate,
        'debit_amount': sale.totalAmount, // "Amount" column in sketch
        'credit_amount': sale.paidAmount, // "Paid" column in sketch
        'running_balance': runningBal,   // "Balance" column in sketch
        'paymode_id': sale.paymodeId,
      });

      // 6. Deduct Stock
      await txn.rawUpdate(
        'UPDATE stocks SET current_qty = current_qty - ? WHERE shop_id = ? AND product_id = ?',
        [sale.weight, sale.shopId, sale.productId]
      );
    });
  }
}