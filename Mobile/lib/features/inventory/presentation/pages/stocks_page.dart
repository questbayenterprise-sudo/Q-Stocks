import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shops/presentation/bloc/shop_bloc.dart';
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

  void _loadStocks(String shopId) async {
    final data = await _repo.getShopStocks(shopId);
    setState(() => _stocks = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stock Inventory")),
      body: Column(
        children: [
          // Shop Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<ShopBloc, ShopState>(
              builder: (context, state) {
                if (state is ShopLoaded) {
                  return DropdownButtonFormField<String>(
                    value: _selectedShopId,
                    decoration: const InputDecoration(labelText: "Select Shop", border: OutlineInputBorder()),
                    items: state.shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedShopId = val);
                      _loadStocks(val!);
                    },
                  );
                }
                return const LinearProgressIndicator();
              },
            ),
          ),
          
          Expanded(
            child: _selectedShopId == null 
              ? const Center(child: Text("Please select a shop branch"))
              : ListView.builder(
                  itemCount: _stocks.length,
                  itemBuilder: (context, index) {
                    final item = _stocks[index];
                    double qty = double.tryParse(item['current_qty']?.toString() ?? '0') ?? 0;
                    bool isLow = qty <= (item['min_stock_lvl'] ?? 5);

                    return ListTile(
                      leading: Icon(Icons.inventory, color: isLow ? Colors.red : Colors.teal),
                      title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Available: $qty ${item['uom']}"),
                      trailing: isLow ? const Text("LOW STOCK", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)) : null,
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}