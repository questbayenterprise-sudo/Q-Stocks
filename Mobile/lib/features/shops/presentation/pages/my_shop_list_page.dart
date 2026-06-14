import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/shop_bloc.dart';

class MyShopListPage extends StatefulWidget {
  const MyShopListPage({super.key});

  @override
  State<MyShopListPage> createState() => _MyShopListPageState();
}

class _MyShopListPageState extends State<MyShopListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(LoadShops());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Shops"),
        actions: [
          IconButton(
            onPressed: () => context.push('/add-shop'),
            icon: const Icon(Icons.add_business, color: Color(0xFF00A36C)),
          )
        ],
      ),
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, state) {
          if (state is ShopLoading) return const Center(child: CircularProgressIndicator());
          if (state is ShopLoaded) {
            return ListView.builder(
              itemCount: state.shops.length,
              itemBuilder: (context, index) {
                final shop = state.shops[index];
                return ListTile(
                  leading: const Icon(Icons.storefront, color: Color(0xFF00A36C)),
                  title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(shop.locationName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/add-shop', extra: shop),
                );
              },
            );
          }
          return const Center(child: Text("No shops found"));
        },
      ),
    );
  }
}