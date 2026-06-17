import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart'; // Ensure geolocator is in pubspec.yaml
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
  String _searchQuery = "";
  bool _showFilterPanel = false;
  String? _selectedLocation;
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadShopsWithLocation();
  }

  // Same logic as your Venue example: Try to get GPS first
  Future<void> _loadShopsWithLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        context.read<ShopBloc>().add(LoadShops());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (!mounted) return;
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        context.read<ShopBloc>().add(LoadShops());
        return;
      }

      // If GPS is okay, trigger load (You can pass lat/lng to your Bloc if your repository supports it)
      context.read<ShopBloc>().add(LoadShops());
    } catch (_) {
      if (!mounted) return;
      context.read<ShopBloc>().add(LoadShops());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = UserSession().userType == UserType.admin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isAdmin),
            
            // --- SEARCH & FILTER ROW ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search branch name...",
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF00A36C)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = "");
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    onPressed: () => setState(() => _showFilterPanel = !_showFilterPanel),
                    icon: Icon(Icons.filter_list, color: _showFilterPanel ? Colors.white : Colors.black),
                    style: IconButton.styleFrom(
                      backgroundColor: _showFilterPanel ? const Color(0xFF00A36C) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
            ),

            if (_showFilterPanel) _buildFilterPanel(),

            const SizedBox(height: 12),

            // --- SHOP LIST / GRID ---
            Expanded(
              child: BlocListener<ShopBloc, ShopState>(
                listener: (context, state) {
                  if (state is ShopError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                child: BlocBuilder<ShopBloc, ShopState>(
                  builder: (context, state) {
                    if (state is ShopLoading) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF00A36C)));
                    }
                    if (state is ShopLoaded) {
                      final filtered = state.shops.where((s) {
                        final matchesSearch = s.name.toLowerCase().contains(_searchQuery.toLowerCase());
                        final matchesLoc = _selectedLocation == null || s.locationName == _selectedLocation;
                        return matchesSearch && matchesLoc;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text("No branches found."));
                      }

                      return RefreshIndicator(
                        onRefresh: () async => context.read<ShopBloc>().add(LoadShops()),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isGridView ? _buildGrid(filtered) : _buildList(filtered),
                        ),
                      );
                    }
                    return const Center(child: Text("Start exploring shops!"));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () => context.push('/add-shop'),
        backgroundColor: const Color(0xFF00A36C),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildHeader(BuildContext context, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: Row(
        children: [
          Text(
            isAdmin ? "Shop Network" : "Explore Shops",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: -0.5),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) {
        if (state is! ShopLoaded) return const SizedBox.shrink();
        final locations = state.shops.map((e) => e.locationName).toSet().toList();
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00A36C).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00A36C).withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Location / Area", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedLocation,
                hint: const Text("Show All Locations"),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text("All Locations")),
                  ...locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))),
                ],
                onChanged: (val) => setState(() => _selectedLocation = val),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(List<ShopModel> shops) {
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: shops.length,
      itemBuilder: (context, index) => _ModernShopCard(shop: shops[index], isGrid: false),
    );
  }

  Widget _buildGrid(List<ShopModel> shops) {
    return GridView.builder(
      key: const ValueKey('grid'),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: shops.length,
      itemBuilder: (context, index) => _ModernShopCard(shop: shops[index], isGrid: true),
    );
  }
}

// --- SUB-WIDGET: ADAPTIVE CARD ---
class _ModernShopCard extends StatelessWidget {
  final ShopModel shop;
  final bool isGrid;

  const _ModernShopCard({required this.shop, required this.isGrid});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/add-shop', extra: shop),
      child: Container(
        margin: EdgeInsets.only(bottom: isGrid ? 0 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: isGrid ? 3 : 0,
              child: ClipRRect(
                borderRadius: isGrid 
                    ? const BorderRadius.vertical(top: Radius.circular(20))
                    : BorderRadius.circular(20),
                child: Container(
                  height: isGrid ? double.infinity : 100,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: shop.imageUrl.isNotEmpty
                      ? (shop.imageUrl.startsWith('http') 
                          ? Image.network(shop.imageUrl, fit: BoxFit.cover) 
                          : Image.file(File(shop.imageUrl), fit: BoxFit.cover))
                      : const Icon(Icons.storefront, color: Color(0xFF00A36C), size: 40),
                ),
              ),
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shop.locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}