import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  @override
  void initState() {
    super.initState();
    // This triggers the repository call you just wrote!
    context.read<ProductBloc>().add(LoadProducts()); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Catalog"),
        actions: [
          IconButton(
            onPressed: () => context.push('/add-product'), 
            icon: const Icon(Icons.add, color: Color(0xFF00A36C))
          )
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) return const Center(child: CircularProgressIndicator());
          if (state is ProductLoaded) {
            final products = state.products;
            if (products.isEmpty) return const Center(child: Text("No products yet"));
            
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return GestureDetector(
                  onTap: () => context.push('/add-product', extra: p),
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_basket_outlined, size: 40, color: Color(0xFF00A36C)),
                        const SizedBox(height: 10),
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("₹${p.basePrice} / ${p.uom.toLowerCase()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text("Error loading products"));
        },
      ),
    );
  }
}