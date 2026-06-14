import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart'; // SEARCHABLE DROPDOWN
import 'package:go_router/go_router.dart';

import '../../../shops/presentation/bloc/shop_bloc.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../data/models/sale_model.dart';
import '../bloc/inventory_bloc.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerRepo = CustomerRepository();

  String? _selectedShopId;
  CustomerModel? _selectedCustomer;
  
  final _weightController = TextEditingController();
  final _rateController = TextEditingController();
  final _paidController = TextEditingController();

  List<CustomerModel> _allCustomers = [];

  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(LoadShops());
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final list = await _customerRepo.fetchCustomers();
    setState(() => _allCustomers = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Sale Entry")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SHOP DROPDOWN (Loaded from DB)
              const Text("Select Shop branch", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              BlocBuilder<ShopBloc, ShopState>(
                builder: (context, state) {
                  if (state is ShopLoaded) {
                    return DropdownButtonFormField<String>(
                      decoration: _inputStyle("Branch", Icons.storefront),
                      items: state.shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) => setState(() => _selectedShopId = val),
                    );
                  }
                  return const LinearProgressIndicator();
                },
              ),

              const SizedBox(height: 20),

              // 2. CUSTOMER DROPDOWN (Searchable + Typable)
              const Text("Select or Type Customer Name", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownSearch<CustomerModel>(
                items: (filter, loadProps) => _allCustomers,
                itemAsString: (CustomerModel c) => c.name,
                onChanged: (CustomerModel? data) => setState(() => _selectedCustomer = data),
                compareFn: (item, selectedItem) => item.id == selectedItem.id,
                
                // Allow typing and adding new
                suffixProps: const DropdownSuffixProps(
                  clearButtonProps: ClearButtonProps(isVisible: true),
                ),
                decoratorProps: DropDownDecoratorProps(
                  decoration: _inputStyle("Search Customer", Icons.person_search),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  emptyBuilder: (context, search) => Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        // Quick Add New Customer
                        final newCust = await _customerRepo.quickAddCustomer(search);
                        await _loadCustomers(); // Refresh local list
                        setState(() => _selectedCustomer = newCust);
                        if (mounted) Navigator.pop(context); // Close dropdown
                      },
                      icon: const Icon(Icons.add),
                      label: Text('Add "$search" as new customer'),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              
              // 3. TRANSACTION FIELDS (Weight/Rate)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Weight (kg)", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Rate (₹)", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _paidController,
                keyboardType: TextInputType.number,
                decoration: _inputStyle("Paid Amount (Credit)", Icons.payments_outlined),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitSale,
                child: const Text("SUBMIT SALE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitSale() {
    if (_formKey.currentState!.validate() && _selectedShopId != null && _selectedCustomer != null) {
      double weight = double.tryParse(_weightController.text) ?? 0;
      double rate = double.tryParse(_rateController.text) ?? 0;
      double total = weight * rate;
      double paid = double.tryParse(_paidController.text) ?? 0;

      final sale = SaleModel(
        shopId: _selectedShopId!,
        customerId: _selectedCustomer!.id,
        productId: "1", // Default broiler
        weight: weight,
        rate: rate,
        totalAmount: total,
        paidAmount: paid,
        paymodeId: 1, // Cash
      );

      context.read<InventoryBloc>().add(CreateSaleEvent(sale));
      context.pop();
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF00A36C)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}