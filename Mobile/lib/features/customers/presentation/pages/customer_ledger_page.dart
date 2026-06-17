import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database_helper.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerLedgerPage extends StatefulWidget {
  final String customerId;
  const CustomerLedgerPage({super.key, required this.customerId});

  @override
  State<CustomerLedgerPage> createState() => _CustomerLedgerPageState();
}

class _CustomerLedgerPageState extends State<CustomerLedgerPage> {
  final repo = CustomerRepository();
  String _customerName = "Loading...";
  double _finalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  // Fetch basic customer details for the header
  Future<void> _loadCustomerInfo() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('customers', where: 'id = ?', whereArgs: [widget.customerId]);
    
    if (res.isNotEmpty && mounted) {
      setState(() {
        // FIXED: Added .toString() to resolve the "Object? to String" assignment error
        _customerName = res.first['name']?.toString() ?? "Unknown Customer";
        
        // FIXED: Safe parsing for the balance
        _finalBalance = double.tryParse(res.first['current_balance'].toString()) ?? 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Statement of Account", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "Total: ₹${_finalBalance.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repo.fetchCustomerLedger(widget.customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00A36C)));
          }

          final ledgerItems = snapshot.data ?? [];

          if (ledgerItems.isEmpty) {
            return const Center(
              child: Text("No transactions recorded yet.", style: TextStyle(color: Colors.grey)),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Allows the 6 columns to scroll sideways
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F1F1)),
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Weight')),
                  DataColumn(label: Text('Rate')),
                  DataColumn(label: Text('Sales (+)')),
                  DataColumn(label: Text('Paid (-)')),
                  DataColumn(label: Text('Balance')),
                ],
                rows: ledgerItems.map((item) {
                  // Safe parsing for all numeric values from SQLite
                  double debit = double.tryParse(item['debit_amount']?.toString() ?? '0') ?? 0;
                  double credit = double.tryParse(item['credit_amount']?.toString() ?? '0') ?? 0;
                  double bal = double.tryParse(item['running_balance']?.toString() ?? '0') ?? 0;
                  String weight = item['weight']?.toString() ?? "0";
                  String rate = item['rate']?.toString() ?? "0";
                  
                  // Clean up date formatting
                  String dateLabel = "";
                  try {
                    dateLabel = DateFormat('dd/MM/yy').format(DateTime.parse(item['transaction_date']));
                  } catch (e) {
                    dateLabel = item['transaction_date'].toString().split(' ')[0];
                  }

                  return DataRow(
                    cells: [
                      DataCell(Text(dateLabel, style: const TextStyle(fontSize: 12))),
                      DataCell(Text(debit > 0 ? "$weight kg" : "-")),
                      DataCell(Text(debit > 0 ? "₹$rate" : "-")),
                      DataCell(
                        Text(debit > 0 ? "₹${debit.toStringAsFixed(0)}" : "", 
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600))
                      ),
                      DataCell(
                        Text(credit > 0 ? "₹${credit.toStringAsFixed(0)}" : "", 
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600))
                      ),
                      DataCell(
                        Text("₹${bal.toStringAsFixed(0)}", 
                        style: TextStyle(
                          color: bal > 0 ? Colors.red : Colors.black, 
                          fontWeight: FontWeight.bold
                        ))
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inventory/sales/add'), // Navigate to the Sale Form
        backgroundColor: const Color(0xFF00A36C),
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
    );
  }
}