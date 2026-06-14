import 'package:flutter/material.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Catalog"),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.8
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          final titles = ["Broiler", "Nattu Kozhi", "Eggs", "Masala"];
          return Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag, size: 50, color: Color(0xFF00A36C)),
                Text(titles[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text("₹120 / kg", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}