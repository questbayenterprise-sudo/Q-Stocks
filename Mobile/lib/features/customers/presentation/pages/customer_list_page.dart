import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/customer_bloc.dart';
import '../../data/models/customer_model.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Customer Directory", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/customers/add'),
        backgroundColor: const Color(0xFF00A36C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading) return const Center(child: CircularProgressIndicator());
          
          if (state is CustomerLoaded) {
            if (state.customers.isEmpty) return const Center(child: Text("No customers found."));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.customers.length,
              itemBuilder: (context, index) {
                final customer = state.customers[index];
                final hasBalance = customer.currentBalance > 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    onTap: () => context.push('/customers/${customer.id}'),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF00A36C).withOpacity(0.1),
                      child: Text(customer.name[0].toUpperCase(), 
                        style: const TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold)),
                    ),
                    title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Bal: ₹${customer.currentBalance.toStringAsFixed(0)}", 
                      style: TextStyle(color: hasBalance ? Colors.red : Colors.green, fontWeight: FontWeight.w600)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          context.push('/customers/add', extra: customer);
                        } else if (val == 'delete') {
                          _confirmDelete(context, customer);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text("Edit")),
                        const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text("Error loading data"));
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete ${customer.name}?"),
        content: const Text("This will hide the customer but keep their history in the ledger."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CustomerBloc>().add(DeleteCustomerEvent(customer.id));
              Navigator.pop(ctx);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}