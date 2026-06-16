import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/database_helper.dart';
import '../../../shops/presentation/bloc/shop_bloc.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/data/repositories/customer_repository.dart';
import '../../data/repositories/income_repository.dart';

class IncomeEntryPage extends StatefulWidget {
  const IncomeEntryPage({super.key});

  @override
  State<IncomeEntryPage> createState() => _IncomeEntryPageState();
}

class _IncomeEntryPageState extends State<IncomeEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _incomeRepo = IncomeRepository();
  final _customerRepo = CustomerRepository();

  String? _selectedShopId;
  CustomerModel? _selectedCustomer;
  double _currentOutstanding = 0.0;
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load shops so the dropdown is populated
    context.read<ShopBloc>().add(LoadShops());
  }

  // Fetch specific customer balance when selected
  void _onCustomerChanged(CustomerModel? customer) async {
    if (customer == null) {
      setState(() {
        _selectedCustomer = null;
        _currentOutstanding = 0.0;
      });
      return;
    }
    
    final db = await DatabaseHelper.instance.database;
    final res = await db.query(
      'customers', 
      columns: ['current_balance'], 
      where: 'id = ?', 
      whereArgs: [customer.id]
    );
    
    setState(() {
      _selectedCustomer = customer;
      _currentOutstanding = double.tryParse(res.first['current_balance'].toString()) ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Income / Payment Entry", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Shop Dropdown
              const Text("Shop Branch", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              BlocBuilder<ShopBloc, ShopState>(
                builder: (context, state) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      hintText: "Select Shop",
                      prefixIcon: Icon(Icons.storefront, color: Color(0xFF00A36C)),
                      border: OutlineInputBorder(),
                    ),
                    items: (state is ShopLoaded) 
                      ? state.shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList() 
                      : [],
                    onChanged: (val) => setState(() => _selectedShopId = val),
                    validator: (v) => v == null ? "Please select a shop" : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              // 2. Customer Search
              const Text("Customer Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownSearch<CustomerModel>(
                items: (f, p) => _customerRepo.fetchCustomers(),
                itemAsString: (CustomerModel? c) => c?.name ?? "",
                onChanged: _onCustomerChanged,
                compareFn: (i, s) => i.id == s.id,
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(
                    hintText: "Search Customer", 
                    prefixIcon: Icon(Icons.person, color: Color(0xFF00A36C)), 
                    border: OutlineInputBorder()
                  ),
                ),
                popupProps: const PopupProps.menu(showSearchBox: true),
              ),
              const SizedBox(height: 20),

              // 3. Outstanding Display
              if (_selectedCustomer != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50, 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: Colors.red.shade100)
                  ),
                  child: Column(
                    children: [
                      const Text("CURRENT OUTSTANDING", 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 4),
                      Text("₹${_currentOutstanding.toStringAsFixed(2)}", 
                        // FIXED: Changed FontWeight.black to FontWeight.w900
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.red)),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // 4. Amount Paid Input
              const Text("Payment Received", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: "Amount Received (₹)",
                  prefixIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF00A36C)),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) => (v == null || v.isEmpty) ? "Enter amount received" : null,
              ),

              const SizedBox(height: 40),

              // 5. Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: _isLoading ? null : _submitPayment,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("RECORD PAYMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitPayment() async {
    if (_formKey.currentState!.validate() && _selectedShopId != null && _selectedCustomer != null) {
      setState(() => _isLoading = true);
      try {
        await _incomeRepo.recordPayment(
          customerId: _selectedCustomer!.id,
          shopId: _selectedShopId!,
          amountPaid: double.parse(_amountController.text),
          paymodeId: 1, // Default to Cash
          remarks: "Customer Payment Received",
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Payment recorded & Balance updated"), backgroundColor: Colors.green)
          );
          context.pop(); // Return to dashboard
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a customer first"))
      );
    }
  }
}