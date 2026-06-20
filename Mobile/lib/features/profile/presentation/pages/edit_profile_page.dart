import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/database/database_helper.dart';
import '../../../auth/Session/user_session.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final String baseUrl = AppConfig.baseUrl;
  String get userId => UserSession().userId ?? "0";

  final _formKey = GlobalKey<FormState>();
  
  // FIXED: Added back the missing _picker declaration
  final ImagePicker _picker = ImagePicker(); 
  
  File? _pickedImage;
  String? _currentImageUrl; 
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedCity;
  List<String> _cities = [];
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadCities(),
      _loadUserProfile(),
    ]);
    setState(() => _isLoading = false);
  }

  // ============================================================
  // 1. DATA LOADING (CLOUD + LOCAL)
  // ============================================================

  Future<void> _loadCities() async {
    try {
      if (AppConfig.isCloudDb) {
        final response = await http.get(Uri.parse('$baseUrl/Get_Cities'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            setState(() => _cities = List<String>.from(data['data']));
          }
        }
      } else {
        final db = await DatabaseHelper.instance.database;
        final List<Map<String, dynamic>> res = await db.query('cities', where: 'is_active = 1');
        setState(() => _cities = res.map((e) => e['name'].toString()).toList());
      }
    } catch (e) {
      debugPrint("City load error: $e");
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      if (AppConfig.isCloudDb) {
        final response = await http.post(
          Uri.parse('$baseUrl/Get_UserProfile'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"user_id": userId}),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final profile = data['data'];
            _populateFields(profile);
            if (profile['image_url'] != null) {
              _currentImageUrl = '$baseUrl/${profile['image_url']}';
            }
          }
        }
      } else {
        final db = await DatabaseHelper.instance.database;
        final List<Map<String, dynamic>> res = await db.query('users', where: 'id = ?', whereArgs: [userId]);
        if (res.isNotEmpty) {
          final profile = res.first;
          _populateFields(profile);
          
          // FIXED: Added .toString() to cast Object? to String?
          _currentImageUrl = profile['image_url']?.toString(); 
        }
      }
    } catch (e) {
      _showSnackBar("Failed to sync profile", isError: true);
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    _nameController.text = data['username']?.toString() ?? "";
    _emailController.text = data['email']?.toString() ?? "";
    _phoneController.text = data['phoneno']?.toString() ?? "";
    _bioController.text = data['bio']?.toString() ?? "";
    _selectedCity = (data['city']?.toString().isNotEmpty ?? false) ? data['city'].toString() : null;
  }

  // ============================================================
  // 2. DATA SAVING (CLOUD + LOCAL)
  // ============================================================

  void _confirmSave() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Confirm Changes"),
          content: const Text("Would you like to update your manager profile details?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
              onPressed: () {
                Navigator.pop(ctx);
                _performUpdate();
              },
              child: const Text("UPDATE", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _performUpdate() async {
    setState(() => _isLoading = true);

    try {
      if (AppConfig.isCloudDb) {
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/Update_Cususer'));
        request.fields['id'] = userId;
        request.fields['username'] = _nameController.text.trim();
        request.fields['email'] = _emailController.text.trim();
        request.fields['phoneno'] = _phoneController.text.trim();
        request.fields['bio'] = _bioController.text.trim();
        request.fields['city'] = _selectedCity ?? "";

        if (_pickedImage != null) {
          request.files.add(await http.MultipartFile.fromPath('image', _pickedImage!.path));
        }

        final response = await http.Response.fromStream(await request.send());
        if (response.statusCode != 200) throw Exception("Cloud error");
        
      } else {
        final db = await DatabaseHelper.instance.database;
        final data = {
          'username': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneno': _phoneController.text.trim(),
          'bio': _bioController.text.trim(),
          'city': _selectedCity ?? "",
        };

        if (_pickedImage != null) {
          data['image_url'] = _pickedImage!.path;
        }

        await db.update('users', data, where: 'id = ?', whereArgs: [userId]);
      }

      // SYNC SESSION
      final session = UserSession();
      await session.saveSession(userId, _nameController.text.trim(), session.userType?.name);
      if (_selectedCity != null) await session.saveCity(_selectedCity!);
      if (_pickedImage != null) await session.saveImageUrl(_pickedImage!.path);

      _showSuccessTrophyDialog();

    } catch (e) {
      _showSnackBar("Update failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // 3. UI COMPONENTS & DIALOGS
  // ============================================================

  void _showSuccessTrophyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM3YxeXp6Znd4bmZyZ3RreHpxZ3RreHpxZ3RreHpxJmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/l0HlIDU8PZFn8vvDG/giphy.gif",
              height: 120,
              errorBuilder: (c,e,s) => const Icon(Icons.check_circle, size: 80, color: Color(0xFF00A36C)),
            ),
            const SizedBox(height: 15),
            const Text("Profile Updated! 🏆", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00A36C))),
            const Text("Your info is now up to date.", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: const Text("BACK TO DASHBOARD", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _autoDetectCity() async {
    setState(() => _isDetectingLocation = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final city = placemarks.first.locality ?? "";
        if (city.isNotEmpty) setState(() => _selectedCity = city);
      }
    } catch (_) {}
    setState(() => _isDetectingLocation = false);
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (file != null) setState(() => _pickedImage = File(file.path));
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider avatar;
    if (_pickedImage != null) {
      avatar = FileImage(_pickedImage!);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      avatar = _currentImageUrl!.startsWith('http') 
          ? NetworkImage(_currentImageUrl!) 
          : FileImage(File(_currentImageUrl!)) as ImageProvider;
    } else {
      avatar = const AssetImage('assets/images/logo.png'); 
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Manager Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _confirmSave,
              child: const Text("SAVE", style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading && _nameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A36C)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImageHeader(avatar),
                    const SizedBox(height: 32),
                    _buildTextField("Full Name", _nameController, Icons.person_outline),
                    _buildTextField("Email", _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    _buildTextField("Contact", _phoneController, Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                    _buildLocationUI(),
                    _buildTextField("Bio / Notes", _bioController, Icons.notes, maxLines: 3, isRequired: false),
                    const SizedBox(height: 30),
                    _buildDangerZone(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageHeader(ImageProvider provider) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(radius: 65, backgroundColor: Colors.grey[100], backgroundImage: provider),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFF00A36C), shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationUI() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          DropdownSearch<String>(
            selectedItem: _selectedCity,
            items: (f, __) => _cities.where((c) => c.toLowerCase().contains(f.toLowerCase())).toList(),
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: "Manager Branch City",
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            onChanged: (v) => setState(() => _selectedCity = v),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isDetectingLocation ? null : _autoDetectCity,
              icon: _isDetectingLocation 
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.my_location, size: 14),
              label: Text(_isDetectingLocation ? "Detecting..." : "Auto-detect City", style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00A36C), width: 2)),
        ),
        validator: isRequired ? (v) => v!.isEmpty ? "Required" : null : null,
      ),
    );
  }

  Widget _buildDangerZone() {
    return ListTile(
      onTap: () => context.push('/delete-account'),
      leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
      title: const Text("Deactivate Manager Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      tileColor: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}