import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // REQUIRED for context.read
import 'package:dropdown_search/dropdown_search.dart';
import 'package:go_router/go_router.dart';

// Import our shared models and repositories
import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../../shops/presentation/bloc/shop_bloc.dart';
import '../../data/models/sale_item_line.dart'; // SHARED MODEL
import '../bloc/inventory_bloc.dart';

class AddSalesPage extends StatefulWidget {
  const AddSalesPage({super.key});

  @override
  State<AddSalesPage> createState() => _AddSalesPageState();
}

class _AddSalesPageState extends State<AddSalesPage> {
  final _customerRepo = CustomerRepository();
  final _productRepo = ProductRepository();

  // Variables
  CustomerModel? _selectedCustomer;
  String? _selectedShopId; 
  final List<SaleItemLine> _items = [SaleItemLine()]; // Set to final as list instance doesn't change
  double _advanceAmount = 0;
  final double _discount = 0; // Set to final

  // Totals
  double get _subTotal => _items.fold(0, (sum, item) => sum + item.lineTotal);
  double get _grandTotal => _subTotal - _discount;
  double get _balanceAmount => _grandTotal - _advanceAmount;
  double get _totalQty => _items.fold(0, (sum, item) => sum + item.quantity);

  @override
  void initState() {
    super.initState();
    // Pre-load shops for the dropdown
    context.read<ShopBloc>().add(LoadShops());
  }

  void _addItem() => setState(() => _items.add(SaleItemLine()));

  void _removeItem(int index) {
    if (_items.length > 1) setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return BlocListener<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is SaleSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sale Completed!"), backgroundColor: Colors.green));
          context.pop();
        }
        if (state is InventoryError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(title: const Text("Create New Invoice"), elevation: 0),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildShopAndCustomerCard(),
                    const SizedBox(height: 16),
                    _buildProductTable(),
                    if (!isDesktop) _buildSummaryCard(),
                  ],
                ),
              ),
            ),
            if (isDesktop)
              Container(
                width: 350,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Colors.grey.shade200)),
                ),
                child: _buildSummaryCard(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopAndCustomerCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Branch & Customer", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            BlocBuilder<ShopBloc, ShopState>(
              builder: (context, state) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Select Shop", border: OutlineInputBorder()),
                  items: (state is ShopLoaded) 
                    ? state.shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList() 
                    : [],
                  onChanged: (val) => setState(() => _selectedShopId = val),
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownSearch<CustomerModel>(
              items: (f, p) => _customerRepo.fetchCustomers(),
              itemAsString: (c) => c.name,
              onChanged: (c) => setState(() => _selectedCustomer = c),
              compareFn: (i, s) => i.id == s.id,
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(labelText: "Select Customer", border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTable() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildProductRow(index),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text("ADD PRODUCT"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductRow(int index) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownSearch<ProductModel>(
              items: (f, p) => _productRepo.fetchProducts(),
              itemAsString: (p) => p.name,
              onChanged: (p) {
                setState(() {
                  _items[index].product = p;
                  _items[index].unitPrice = p?.basePrice ?? 0;
                });
              },
              compareFn: (i, s) => i.id == s.id,
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(hintText: "Product", border: OutlineInputBorder()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Qty", border: OutlineInputBorder()),
              onChanged: (v) => setState(() => _items[index].quantity = double.tryParse(v) ?? 0),
            ),
          ),
          const SizedBox(width: 8),
          Text("₹${_items[index].lineTotal.toStringAsFixed(2)}"),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bill Summary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          _summaryRow("Total Items", "${_items.length}"),
          _summaryRow("Total Qty", "${_totalQty.toStringAsFixed(2)} kg"),
          _summaryRow("Subtotal", "₹${_subTotal.toStringAsFixed(2)}"),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(labelText: "Advance Paid (₹)", border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _advanceAmount = double.tryParse(v) ?? 0),
          ),
          const Divider(height: 32),
          const Text("GRAND TOTAL", style: TextStyle(fontSize: 12)),
          Text("₹${_grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF00A36C))),
          const SizedBox(height: 8),
          Text("BALANCE: ₹${_balanceAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C), minimumSize: const Size(double.infinity, 55)),
            onPressed: _submitInvoice,
            child: const Text("COMPLETE SALE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _submitInvoice() {
    if (_selectedCustomer == null || _selectedShopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Shop & Customer")));
      return;
    }

    context.read<InventoryBloc>().add(
      SaveInvoiceEvent(
        customerId: _selectedCustomer!.id,
        shopId: _selectedShopId!, // FIXED: shopId is now passed
        items: _items,
        advance: _advanceAmount,
        status: "COMPLETED",
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }
}

// REMOVED: SaleItemLine local class definition (now imported from data/models)