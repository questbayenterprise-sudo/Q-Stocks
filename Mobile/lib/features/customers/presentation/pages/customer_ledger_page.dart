import 'package:flutter/material.dart';

class CustomerLedgerPage extends StatelessWidget {
  final String customerId;
  const CustomerLedgerPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ledger Notebook")),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Weight')),
            DataColumn(label: Text('Rate')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Paid')),
            DataColumn(label: Text('Balance')),
          ],
          rows: List.generate(5, (index) => DataRow(cells: [
            DataCell(Text("1${index+1}/06/26")),
            const DataCell(Text("10.0")),
            const DataCell(Text("100")),
            const DataCell(Text("1000")),
            const DataCell(Text("500")),
            const DataCell(Text("500", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          ])),
        ),
      ),
    );
  }
}