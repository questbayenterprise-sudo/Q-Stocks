import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../bloc/shop_bloc.dart';
import '../../data/models/shop_model.dart';

class AddShopPage extends StatefulWidget {
  final ShopModel? initialShop; // If null, we are in "Add" mode
  const AddShopPage({super.key, this.initialShop});

  @override
  State<AddShopPage> createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _descController;
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final shop = widget.initialShop;
    _nameController = TextEditingController(text: shop?.name ?? "");
    _locationController = TextEditingController(text: shop?.locationName ?? "");
    _descController = TextEditingController(text: shop?.description ?? "");
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
     final shop = ShopModel(
  id: widget.initialShop?.id ?? "0",
  name: _nameController.text.trim(),
  locationName: _locationController.text.trim(),
  description: _descController.text.trim(), // price removed
  imageUrl: _imageFile?.path ?? widget.initialShop?.imageUrl ?? "",
);

      context.read<ShopBloc>().add(SaveShopEvent(shop));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialShop != null;

    return BlocListener<ShopBloc, ShopState>(
      listener: (context, state) {
        if (state is ShopLoaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEdit ? "Shop Updated" : "Shop Created")),
          );
          context.pop(); // Go back to list
        }
        if (state is ShopError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(isEdit ? "Edit Shop" : "Add New Shop")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Image Picker Box
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      image: _imageFile != null 
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : (widget.initialShop?.imageUrl.isNotEmpty ?? false)
                          ? DecorationImage(image: NetworkImage(widget.initialShop!.imageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: (_imageFile == null && (widget.initialShop?.imageUrl.isEmpty ?? true))
                      ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                      : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Shop Name", prefixIcon: Icon(Icons.store)),
                  validator: (v) => v!.isEmpty ? "Enter name" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: "Location", prefixIcon: Icon(Icons.location_on)),
                  validator: (v) => v!.isEmpty ? "Enter location" : null,
                ),
            
                const SizedBox(height: 15),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description", prefixIcon: Icon(Icons.info)),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _onSave,
                  child: const Text("SAVE SHOP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}