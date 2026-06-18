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
  final _remarksController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(LoadShops());
  }

  void _onCustomerChanged(CustomerModel? customer) async {
    if (customer == null) {
      setState(() { _selectedCustomer = null; _currentOutstanding = 0.0; });
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('customers', columns: ['current_balance'], where: 'id = ?', whereArgs: [customer.id]);
    setState(() {
      _selectedCustomer = customer;
      _currentOutstanding = double.tryParse(res.first['current_balance'].toString()) ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Receive Payment", style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select Shop", border: OutlineInputBorder()),
                items: context.watch<ShopBloc>().state is ShopLoaded 
                  ? (context.read<ShopBloc>().state as ShopLoaded).shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList() 
                  : [],
                onChanged: (val) => setState(() => _selectedShopId = val),
                validator: (v) => v == null ? "Required" : null,
              ),
              const SizedBox(height: 20),
              DropdownSearch<CustomerModel>(
                items: (f, p) => _customerRepo.fetchCustomers(),
                itemAsString: (c) => c.name,
                onChanged: _onCustomerChanged,
                compareFn: (i, s) => i.id == s.id,
                decoratorProps: const DropDownDecoratorProps(
                  decoration: InputDecoration(labelText: "Search Customer", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                ),
                popupProps: const PopupProps.menu(showSearchBox: true),
              ),
              const SizedBox(height: 20),
              if (_selectedCustomer != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
                  child: Column(
                    children: [
                      const Text("CURRENT OUTSTANDING", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                      Text("₹${_currentOutstanding.toStringAsFixed(2)}", 
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.red)),
                    ],
                  ),
                ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: "Amount Received (₹)", prefixIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF00A36C)), border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Enter amount" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: "Remarks (Optional)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: _isLoading ? null : _submitPayment,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("RECORD PAYMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          paymodeId: 1,
          remarks: _remarksController.text.isEmpty ? "Payment Received" : _remarksController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment recorded successfully"), backgroundColor: Colors.green));
          context.pop(true); // Return 'true' to signal a refresh is needed
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}