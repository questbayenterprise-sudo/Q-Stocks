import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shops/presentation/bloc/shop_bloc.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../data/repositories/stocks_repository.dart';

class StocksPage extends StatefulWidget {
  const StocksPage({super.key});

  @override
  State<StocksPage> createState() => _StocksPageState();
}

class _StocksPageState extends State<StocksPage> {
  String? _selectedShopId; // NULL means "All Shops"
  List<Map<String, dynamic>> _stocks = [];
  final _repo = StocksRepository();
  final _prodRepo = ProductRepository();

  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(LoadShops());
    _refreshData(); // Load everything on start
  }

  void _refreshData() async {
    List<Map<String, dynamic>> data;
    if (_selectedShopId == null || _selectedShopId == "0") {
      data = await _repo.getAllShopsStocks();
    } else {
      data = await _repo.getShopStocks(_selectedShopId!);
    }
    setState(() => _stocks = data);
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Inventory Status", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStockDialog(),
        backgroundColor: const Color(0xFF00A36C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("ADD STOCK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<ShopBloc, ShopState>(
              builder: (context, state) {
                return DropdownButtonFormField<String>(
                  value: _selectedShopId ?? "0",
                  decoration: InputDecoration(
                    labelText: "Filter by Shop",
                    prefixIcon: const Icon(Icons.filter_list, color: Color(0xFF00A36C)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    const DropdownMenuItem(value: "0", child: Text("All Shop Branches")),
                    if (state is ShopLoaded)
                      ...state.shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedShopId = val == "0" ? null : val);
                    _refreshData();
                  },
                );
              },
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: _stocks.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _stocks.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final item = _stocks[index];
                      double qty = double.tryParse(item['current_qty'].toString()) ?? 0;
                      double min = double.tryParse(item['min_stock_lvl'].toString()) ?? 5;
                      bool isLow = qty <= min;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: isLow ? Colors.red.shade200 : Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isLow ? Colors.red.shade50 : const Color(0xFF00A36C).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined, 
                              color: isLow ? Colors.red : const Color(0xFF00A36C)
                            ),
                          ),
                          title: Text(
                            item['product_name'] ?? item['name'], 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              // SHOW SHOP NAME HERE
                              Row(
                                children: [
                                  const Icon(Icons.storefront, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(item['shop_name'] ?? "Main Branch", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Available: $qty ${item['uom']}",
                                style: TextStyle(
                                  color: isLow ? Colors.red : Colors.black87,
                                  fontWeight: isLow ? FontWeight.bold : FontWeight.normal
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'edit') _showStockDialog(existingStock: item);
                              if (val == 'delete') _confirmDelete(item['stock_id'], item['product_name']);
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Text("Adjust Quantity")),
                              const PopupMenuItem(value: 'delete', child: Text("Remove from View", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No inventory records found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // (The _showStockDialog and _confirmDelete methods remain similar but call _refreshData() at the end)
  void _showStockDialog({Map<String, dynamic>? existingStock}) async {
    // Note: If adding new stock, and filter is "All Shops", 
    // you must prompt the user to pick a shop inside the dialog.
    // ... existing dialog logic ...
    // After await _repo.saveStock(...):
    _refreshData();
  }

  void _confirmDelete(int stockId, String name) {
    // ... existing delete logic ...
    // After await _repo.deleteStock(stockId):
    _refreshData();
  }
}