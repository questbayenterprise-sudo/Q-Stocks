import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/Session/user_session.dart';
import '../bloc/shop_bloc.dart';
import '../../data/models/shop_model.dart';

class MyShopListPage extends StatefulWidget {
  const MyShopListPage({super.key});

  @override
  State<MyShopListPage> createState() => _MyShopListPageState();
}

class _MyShopListPageState extends State<MyShopListPage> {
  @override
  void initState() {
    super.initState();
    // Trigger load when page opens
    _refresh();
  }

  void _refresh() {
    context.read<ShopBloc>().add(LoadShops());
  }

  void _showDeleteDialog(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete $name?"),
        content: const Text(
          "This will deactivate the shop. Historical sales and ledger records will be preserved for reporting.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              context.read<ShopBloc>().add(DeleteShopEvent(id));
              Navigator.pop(ctx);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildShopImage(String path) {
    if (path.isEmpty) {
      return const Icon(Icons.store, color: Color(0xFF00A36C), size: 30);
    }

    // Check if it's a URL or a Local File Path
    if (path.startsWith('http') || path.startsWith('https')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.store),
        );
      }
    }
    return const Icon(Icons.store, color: Color(0xFF00A36C));
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = UserSession().userType == UserType.admin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("My Shops", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          // Show "Add" button for Admin or Owners
          IconButton(
            onPressed: () => context.push('/add-shop'),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF00A36C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, state) {
          if (state is ShopLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00A36C)));
          }

          if (state is ShopError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(state.message),
                  TextButton(onPressed: _refresh, child: const Text("Retry")),
                ],
              ),
            );
          }

          if (state is ShopLoaded) {
            if (state.shops.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text("No shops added yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => context.push('/add-shop'),
                      child: const Text("Add Your First Shop"),
                    )
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView.builder(
                itemCount: state.shops.length,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemBuilder: (context, index) {
                  final shop = state.shops[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: InkWell(
                      onTap: () => context.push('/add-shop', extra: shop),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Shop Image Container
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 70,
                                height: 70,
                                color: const Color(0xFF00A36C).withOpacity(0.05),
                                child: _buildShopImage(shop.imageUrl),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Shop Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        shop.locationName,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                
                                ],
                              ),
                            ),
                            // Actions Menu
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  context.push('/add-shop', extra: shop);
                                } else if (val == 'delete') {
                                  _showDeleteDialog(context, shop.id, shop.name);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text("Edit"),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text("Delete", style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}