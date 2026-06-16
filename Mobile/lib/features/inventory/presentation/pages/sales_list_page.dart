import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SalesListPage extends StatelessWidget {
  const SalesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Records"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
  onPressed: () => context.push('/inventory/sales/add'), // Navigates to the Add Form
  icon: const Icon(Icons.add, color: Colors.white),
  label: const Text("ADD SALE", style: TextStyle(color: Colors.white)),
  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('Invoice #')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Total (₹)')),
                    DataColumn(label: Text('Paid (₹)')),
                    DataColumn(label: Text('Balance (₹)')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: List.generate(10, (index) => _buildDataRow(index)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Invoice or Customer...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _filterDropdown("Status"),
          const SizedBox(width: 8),
          _filterDropdown("Date Range"),
        ],
      ),
    );
  }

  DataRow _buildDataRow(int index) {
    return DataRow(cells: [
      DataCell(Text("INV-2024-00${index + 1}")),
      const DataCell(Text("Raja Kumar")),
      DataCell(Text(DateFormat('dd-MM-yyyy').format(DateTime.now()))),
      const DataCell(Text("1250.00")),
      const DataCell(Text("500.00")),
      const DataCell(Text("750.00", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      DataCell(_statusBadge("COMPLETED")),
      DataCell(Row(
        children: [
          IconButton(icon: const Icon(Icons.visibility_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.print_outlined), onPressed: () {}),
        ],
      )),
    ]);
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _filterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: DropdownButton<String>(
        hint: Text(label),
        underline: const SizedBox(),
        items: const [],
        onChanged: (v) {},
      ),
    );
  }
}