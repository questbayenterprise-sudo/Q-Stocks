import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';
import '../../data/models/product_model.dart';

class AddProductPage extends StatefulWidget {
  final ProductModel? initialProduct;
  const AddProductPage({super.key, this.initialProduct});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  String _selectedUom = "KG";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProduct?.name ?? "");
    _priceController = TextEditingController(text: widget.initialProduct?.basePrice.toString() ?? "");
    _selectedUom = widget.initialProduct?.uom ?? "KG";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialProduct == null ? "Add Product" : "Edit Product")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Product Name (e.g. Broiler)"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedUom,
                decoration: const InputDecoration(labelText: "Unit of Measure"),
                items: ["KG", "Piece", "Tray"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedUom = v!),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Default Rate (₹)"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C), minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final product = ProductModel(
                      id: widget.initialProduct?.id ?? "0",
                      name: _nameController.text,
                      categoryId: "1",
                      uom: _selectedUom,
                      basePrice: double.parse(_priceController.text),
                      imageUrl: "",
                    );
                    context.read<ProductBloc>().add(SaveProductEvent(product));
                    context.pop();
                  }
                },
                child: const Text("SAVE PRODUCT", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}