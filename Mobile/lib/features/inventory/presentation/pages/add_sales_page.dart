import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:go_router/go_router.dart';

import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../../shops/presentation/bloc/shop_bloc.dart';
import '../../data/models/sale_item_line.dart';
import '../bloc/inventory_bloc.dart';

class AddSalesPage extends StatefulWidget {
  const AddSalesPage({super.key});

  @override
  State<AddSalesPage> createState() => _AddSalesPageState();
}

class _AddSalesPageState extends State<AddSalesPage> {
  final _customerRepo = CustomerRepository();
  final _productRepo = ProductRepository();

  CustomerModel? _selectedCustomer;
  String? _selectedShopId;
  final List<SaleItemLine> _items = [SaleItemLine()];
  double _advanceAmount = 0;
  final double _discount = 0;

  double get _subTotal => _items.fold(0, (sum, item) => sum + item.lineTotal);
  double get _grandTotal => _subTotal - _discount;
  double get _balanceAmount => _grandTotal - _advanceAmount;
  double get _totalQty => _items.fold(0, (sum, item) => sum + item.quantity);

  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(LoadShops());
  }

  // --- SHARED DECORATION HELPER ---
  InputDecoration _getInputDecoration(String label, IconData icon, {bool isCompact = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF00A36C), size: 20),
      isDense: true,
      contentPadding: isCompact ? const EdgeInsets.all(12) : const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00A36C), width: 1.5)),
    );
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
        backgroundColor: const Color(0xFFF8F9FA), // Professional light grey background
        appBar: AppBar(
          title: const Text("New Invoice", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
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
                    _buildProductTableHeader(), // Added Header
                    _buildProductTable(),
                    if (!isDesktop) _buildSummaryCard(),
                  ],
                ),
              ),
            ),
            if (isDesktop)
              Container(
                width: 380,
                height: double.infinity,
                decoration: const BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Color(0xFFEEEEEE)))),
                child: _buildSummaryCard(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopAndCustomerCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Standard Dropdown - Shop
            BlocBuilder<ShopBloc, ShopState>(
              builder: (context, state) {
                return DropdownButtonFormField<String>(
                  decoration: _getInputDecoration("Select Branch", Icons.storefront),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: (state is ShopLoaded) ? state.shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList() : [],
                  onChanged: (val) => setState(() => _selectedShopId = val),
                );
              },
            ),
            const SizedBox(height: 16),
            // Searchable Dropdown - Customer
            DropdownSearch<CustomerModel>(
              items: (f, p) => _customerRepo.fetchCustomers(),
              itemAsString: (c) => c.name,
              onChanged: (c) => setState(() => _selectedCustomer = c),
              compareFn: (i, s) => i.id == s.id,
              decoratorProps: DropDownDecoratorProps(
                decoration: _getInputDecoration("Select Customer", Icons.person_outline),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: _getInputDecoration("Search by name", Icons.search, isCompact: true),
                ),
                menuProps: const MenuProps(elevation: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text("PRODUCT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text("QTY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
          SizedBox(width: 80, child: Center(child: Text("TOTAL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)))),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProductTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) => _buildProductRow(index),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _items.add(SaleItemLine())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("ADD ANOTHER ITEM"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00A36C),
                side: const BorderSide(color: Color(0xFF00A36C)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Searchable Product Dropdown
          Expanded(
            flex: 3,
            child: DropdownSearch<ProductModel>(
              items: (f, p) => _productRepo.fetchProducts(),
              itemAsString: (p) => p.name,
              compareFn: (i, s) => i.id == s.id,
              onChanged: (p) {
                setState(() {
                  _items[index].product = p;
                  _items[index].unitPrice = p?.basePrice ?? 0;
                });
              },
              decoratorProps: DropDownDecoratorProps(
                decoration: _getInputDecoration("Product", Icons.shopping_bag_outlined, isCompact: true),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(decoration: _getInputDecoration("Search product", Icons.search, isCompact: true)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Quantity Input
          Expanded(
            child: TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "0.0",
                isDense: true,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _items[index].quantity = double.tryParse(v) ?? 0),
            ),
          ),
          const SizedBox(width: 8),
          // Row Total
          SizedBox(
            width: 80,
            child: Text(
              "₹${_items[index].lineTotal.toStringAsFixed(2)}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Remove Button
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
            onPressed: () {
              if (_items.length > 1) setState(() => _items.removeAt(index));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bill Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          _summaryRow("Total Items", "${_items.length}"),
          _summaryRow("Total Qty", "${_totalQty.toStringAsFixed(2)} kg"),
          _summaryRow("Subtotal", "₹${_subTotal.toStringAsFixed(2)}"),
          const SizedBox(height: 16),
          TextFormField(
            decoration: _getInputDecoration("Advance Paid (₹)", Icons.money),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _advanceAmount = double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 24),
          const Text("GRAND TOTAL", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text("₹${_grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF00A36C))),
          const SizedBox(height: 4),
          Text("BALANCE: ₹${_balanceAmount.toStringAsFixed(2)}", 
            style: TextStyle(color: _balanceAmount > 0 ? Colors.red : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A36C),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _submitInvoice,
            child: const Text("COMPLETE SALE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _submitInvoice() {
    if (_selectedCustomer == null || _selectedShopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Branch & Customer")));
      return;
    }
    context.read<InventoryBloc>().add(
      SaveInvoiceEvent(
        customerId: _selectedCustomer!.id,
        shopId: _selectedShopId!,
        items: _items,
        advance: _advanceAmount,
        status: "COMPLETED",
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}