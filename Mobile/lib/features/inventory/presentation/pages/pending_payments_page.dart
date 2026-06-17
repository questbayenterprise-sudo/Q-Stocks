import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../customers/data/repositories/customer_repository.dart';

class PendingPaymentsPage extends StatelessWidget {
  const PendingPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CustomerRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Pending Collections", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repo.fetchPendingPayments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00A36C)));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) return const Center(child: Text("No pending dues found."));

          double total = list.fold(0, (sum, item) => sum + (double.tryParse(item['current_balance'].toString()) ?? 0));

          return Column(
            children: [
              // Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.red.shade50,
                child: Column(
                  children: [
                    const Text("TOTAL OUTSTANDING", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text("₹${NumberFormat('#,##,###').format(total)}", 
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.red)),
                  ],
                ),
              ),
              // Customer List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final customer = list[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        onTap: () => context.push('/customers/${customer['id']}'),
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Contact: ${customer['phone']}"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("₹${customer['current_balance']}", 
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 18)),
                            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}