import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/sales_repository.dart';

class SalesListPage extends StatefulWidget {
  const SalesListPage({super.key});

  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  final SalesRepository _salesRepo = SalesRepository();
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealSales();
  }

  Future<void> _loadRealSales() async {
    setState(() => _isLoading = true);
    try {
      final data = await _salesRepo.fetchSales();
      setState(() {
        _sales = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- NEW: FUNCTION TO SHOW DETAILS ---
  void _showOrderDetails(BuildContext context, Map<String, dynamic> sale) async {
    final int orderId = sale['id'];
    
    // Show a loading dialog immediately
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _salesRepo.fetchOrderItems(orderId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }

            final items = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Invoice ${sale['order_ref']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  ...items.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${item['weight']} ${item['uom']} @ ₹${item['rate']}"),
                    trailing: Text("₹${item['sub_total']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Grand Total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("₹${sale['total_amount']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF00A36C))),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Sales", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/inventory/sales/add').then((_) => _loadRealSales()),
            icon: const Icon(Icons.add_circle, color: Color(0xFF00A36C), size: 32),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                    ? const Center(child: Text("No records found"))
                    : ListView.builder(
                        itemCount: _sales.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final sale = _sales[index];
                          return _buildSaleCard(sale);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    double total = double.tryParse(sale['total_amount'].toString()) ?? 0;
    double balance = double.tryParse(sale['balance_due'].toString()) ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(sale['customer_name'] ?? "Walk-in", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${sale['order_ref']} • ${sale['created_at'].toString().split('T')[0]}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("₹$total", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (balance > 0)
                  Text("Due: ₹$balance", style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 10),
            // FIXED: Eye icon now calls the details function
            IconButton(
              icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
              onPressed: () => _showOrderDetails(context, sale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search Invoice or Customer...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}