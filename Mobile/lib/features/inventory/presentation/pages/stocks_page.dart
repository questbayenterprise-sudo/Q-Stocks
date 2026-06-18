import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shops/presentation/bloc/shop_bloc.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../products/data/models/product_model.dart';
import '../../data/repositories/stocks_repository.dart';

class StocksPage extends StatefulWidget {
  const StocksPage({super.key});

  @override
  State<StocksPage> createState() => _StocksPageState();
}

class _StocksPageState extends State<StocksPage> {
  String? _selectedShopId;
  List<Map<String, dynamic>> _stocks = [];
  final _repo = StocksRepository();
  final _prodRepo = ProductRepository();

  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(LoadShops());
  }

  void _loadStocks() async {
    if (_selectedShopId == null) return;
    final data = await _repo.getShopStocks(_selectedShopId!);
    setState(() => _stocks = data);
  }

  // --- ACTIONS ---

  void _showStockDialog({Map<String, dynamic>? existingStock}) async {
    if (_selectedShopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a shop first")));
      return;
    }

    final isEdit = existingStock != null;
    final products = await _prodRepo.fetchProducts();
    
    String? selProdId = existingStock?['product_id']?.toString();
    final qtyCtrl = TextEditingController(text: existingStock?['current_qty']?.toString() ?? "0");
    final minCtrl = TextEditingController(text: existingStock?['min_stock_lvl']?.toString() ?? "5");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(isEdit ? "Edit Stock" : "Add Product to Stock"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEdit)
                DropdownButtonFormField<String>(
                  value: selProdId,
                  decoration: const InputDecoration(labelText: "Select Product"),
                  items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (v) => setModalState(() => selProdId = v),
                ),
              TextFormField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Current Quantity (KG/Pcs)"),
              ),
              TextFormField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Low Stock Alert Level"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () async {
                if (selProdId != null) {
                  await _repo.saveStock(
                    shopId: _selectedShopId!,
                    productId: selProdId!,
                    quantity: double.tryParse(qtyCtrl.text) ?? 0,
                    minLevel: double.tryParse(minCtrl.text) ?? 5,
                  );
                  Navigator.pop(ctx);
                  _loadStocks();
                }
              },
              child: const Text("SAVE"),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int stockId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Remove $name?"),
        content: const Text("This will remove this product from this shop's inventory view."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await _repo.deleteStock(stockId);
              Navigator.pop(ctx);
              _loadStocks();
            },
            child: const Text("REMOVE", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stock Management")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStockDialog(),
        backgroundColor: const Color(0xFF00A36C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<ShopBloc, ShopState>(
              builder: (context, state) {
                if (state is ShopLoaded) {
                  return DropdownButtonFormField<String>(
                    value: _selectedShopId,
                    decoration: const InputDecoration(labelText: "Select Shop Branch", border: OutlineInputBorder()),
                    items: state.shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedShopId = val);
                      _loadStocks();
                    },
                  );
                }
                return const LinearProgressIndicator();
              },
            ),
          ),
          Expanded(
            child: _selectedShopId == null
                ? const Center(child: Text("Select a branch to manage stock"))
                : _stocks.isEmpty 
                  ? const Center(child: Text("No items in stock for this branch."))
                  : ListView.builder(
                      itemCount: _stocks.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final item = _stocks[index];
                        double qty = double.tryParse(item['current_qty'].toString()) ?? 0;
                        double min = double.tryParse(item['min_stock_lvl'].toString()) ?? 5;
                        bool isLow = qty <= min;

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isLow ? Colors.red.shade50 : Colors.teal.shade50,
                              child: Icon(Icons.inventory_2, color: isLow ? Colors.red : Colors.teal),
                            ),
                            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Available: $qty ${item['uom']} (Limit: $min)"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showStockDialog(existingStock: item)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(item['stock_id'], item['name'])),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}