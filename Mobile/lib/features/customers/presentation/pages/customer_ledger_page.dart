import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';

class CustomerLedgerPage extends StatelessWidget {
  final String customerId;
  const CustomerLedgerPage({super.key, required this.customerId});

  Future<List<Map<String, dynamic>>> _fetchLedger() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'customer_ledger',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'transaction_date DESC',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transaction History")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLedger(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final ledger = snapshot.data!;

          if (ledger.isEmpty) return const Center(child: Text("No transactions found"));

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.green.withOpacity(0.1)),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Weight')),
                  DataColumn(label: Text('Rate')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Paid')),
                  DataColumn(label: Text('Balance')),
                ],
                rows: ledger.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row['transaction_date'].toString().split(' ')[0])),
                    DataCell(Text("${row['weight']} kg")),
                    DataCell(Text("₹${row['rate']}")),
                    DataCell(Text("₹${row['debit_amount']}")),
                    DataCell(Text("₹${row['credit_amount']}", style: const TextStyle(color: Colors.green))),
                    DataCell(Text("₹${row['running_balance']}", style: const TextStyle(fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}