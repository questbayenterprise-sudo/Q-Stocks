import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerListPage extends StatelessWidget {
  const CustomerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Directory")),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text("Customer Name"),
            subtitle: const Text("Balance: ₹1,200"),
            onTap: () => context.push('/customers/${index + 1}'),
          );
        },
      ),
    );
  }
}