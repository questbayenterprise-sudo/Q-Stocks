import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/customer_bloc.dart';
import '../../data/models/customer_model.dart';

class AddCustomerPage extends StatefulWidget {
  final CustomerModel? initialCustomer;
  const AddCustomerPage({super.key, this.initialCustomer});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCustomer?.name ?? "");
    _phoneController = TextEditingController(text: widget.initialCustomer?.phone ?? "");
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialCustomer != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Customer" : "New Customer")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                  minimumSize: const Size(double.infinity, 55)
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final customer = CustomerModel(
                      id: widget.initialCustomer?.id ?? "0",
                      name: _nameController.text.trim(),
                      phone: _phoneController.text.trim(),
                    );
                    context.read<CustomerBloc>().add(SaveCustomerEvent(customer));
                    context.pop();
                  }
                },
                child: Text("SAVE CUSTOMER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}