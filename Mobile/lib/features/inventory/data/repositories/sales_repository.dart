import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/sale_item_line.dart';

class SalesRepository {
  // Singleton Database Access
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // 1. Fetch Paginated Sales for the List Page
  Future<List<Map<String, dynamic>>> fetchSales({int limit = 20, int offset = 0}) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT o.*, c.name as customer_name 
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ORDER BY o.created_at DESC
      LIMIT ? OFFSET ?
    ''', [limit, offset]);
  }

  // 2. Create Sale (Full Transaction Logic)
  // This method name matches your InventoryBloc call
  Future<void> createSale({
    required String customerId,
    required String shopId,
    required double totalAmount,
    required double advancePaid,
    required String status, // 'COMPLETED' or 'DRAFT'
    required List<SaleItemLine> items,
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      // --- A. GENERATE INVOICE NUMBER ---
      String invoiceNo = "INV-${DateTime.now().millisecondsSinceEpoch}";

      // --- B. INSERT INTO ORDERS (MASTER) ---
      int orderId = await txn.insert('orders', {
        'order_ref': invoiceNo,
        'shop_id': int.tryParse(shopId) ?? 1,
        'customer_id': int.tryParse(customerId) ?? 0,
        'total_amount': totalAmount,
        'paid_amount': advancePaid,
        'balance_due': totalAmount - advancePaid,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });

      // --- C. PROCESS ITEMS & STOCK ---
      for (var item in items) {
        if (item.product == null) continue;

        // 1. Insert into order_items (Detail)
        await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': int.tryParse(item.product!.id) ?? 0,
          'weight': item.quantity,
          'rate': item.unitPrice,
          'sub_total': item.lineTotal,
        });

        // 2. Deduct Stock if sale is finalized
        if (status == 'COMPLETED') {
          await txn.rawUpdate('''
            UPDATE stocks 
            SET current_qty = current_qty - ? 
            WHERE shop_id = ? AND product_id = ?
          ''', [
            item.quantity, 
            int.tryParse(shopId) ?? 1, 
            int.tryParse(item.product!.id) ?? 0
          ]);
        }
      }

      // --- D. UPDATE CUSTOMER ACCOUNT & LEDGER ---
      // We only update balance if customer is not "Walk-in" (id 0)
      if (customerId != "0") {
        // 1. Get current balance to calculate new running balance
        final List<Map<String, dynamic>> customerRes = await txn.query(
          'customers', 
          columns: ['current_balance'], 
          where: 'id = ?', 
          whereArgs: [customerId]
        );
        
        double currentBal = 0.0;
        if (customerRes.isNotEmpty) {
          currentBal = double.tryParse(customerRes.first['current_balance'].toString()) ?? 0.0;
        }

        double balanceChange = totalAmount - advancePaid;
        double newRunningBalance = currentBal + balanceChange;

        // 2. Update Customer Master Table
        await txn.update(
          'customers',
          {'current_balance': newRunningBalance},
          where: 'id = ?',
          whereArgs: [customerId],
        );

        // 3. Add entry to Customer Ledger (Notebook View)
        // For Multi-product invoices, we record the total summary line
        await txn.insert('customer_ledger', {
          'customer_id': int.tryParse(customerId),
          'shop_id': int.tryParse(shopId),
          'order_id': orderId,
          'transaction_date': DateTime.now().toIso8601String(),
          'weight': items.length == 1 ? items.first.quantity : 0, // specific weight if only 1 item
          'rate': items.length == 1 ? items.first.unitPrice : 0,  // specific rate if only 1 item
          'debit_amount': totalAmount,
          'credit_amount': advancePaid,
          'running_balance': newRunningBalance,
          'remarks': "Invoice $invoiceNo (${items.length} items)",
        });
      }
    });
  }

  // 3. Delete/Cancel Sale
  Future<void> deleteSale(int orderId) async {
    final db = await _db;
    await db.update('orders', {'status': 'CANCELLED'}, where: 'id = ?', whereArgs: [orderId]);
  }
}