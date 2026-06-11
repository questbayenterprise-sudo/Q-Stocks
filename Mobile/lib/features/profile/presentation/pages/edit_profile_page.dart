import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:dropdown_search/dropdown_search.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/Session/user_session.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final String baseUrl = AppConfig.baseUrl;
  String get userId => UserSession().userId ?? "1";

  final _formKey = GlobalKey<FormState>();
  File? _image;
  String? _serverImageUrl; // Store the image path from Go backend
  final _picker = ImagePicker();
  bool _isLoading = false;

  // Change these to empty initially so we can fill them from the API
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  // Location state
  String? _selectedCity;
  List<String> _cities = [];
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final url = Uri.parse('$baseUrl/Get_Cities');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _cities = List<String>.from(data['data']);
          });
        }
      }
    } catch (e) {
      _showSnackBar("Failed to load cities", isError: true);
    }
  }

  Future<void> _autoDetectCity() async {
    setState(() => _isDetectingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isDetectingLocation = false);
          _showLocationServiceDialog();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar("Location permission denied", isError: true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isDetectingLocation = false);
          _showPermissionDeniedDialog();
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? "";
        if (city.isNotEmpty) {
          setState(() => _selectedCity = city);
          _showSnackBar("Location detected: $city");
        }
      }
    } catch (e) {
      _showSnackBar("Could not detect location", isError: true);
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  // --- NEW: FETCH PROFILE DETAILS ---
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('$baseUrl/Get_UserProfile');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final profile = data['data'];
          setState(() {
            _nameController.text = profile['username'] ?? "";
            _emailController.text = profile['email'] ?? "";
            _phoneController.text = profile['phoneno'] ?? "";
            _bioController.text = profile['bio'] ?? "";
            _serverImageUrl = profile['image_url']; // e.g., "uploads/users/1.jpg"
            final city = profile['city'] ?? "";
            _selectedCity = city.isNotEmpty ? city : null;
          });
          // Save image URL to session for use across the app
          if (_serverImageUrl != null && _serverImageUrl!.isNotEmpty) {
            await UserSession().saveImageUrl('$baseUrl/$_serverImageUrl');
          }
        }
      } else {
        _showSnackBar("Failed to load profile", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error connecting to server", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  void _confirmSave() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Update"),
          content: const Text("Do you want to save the changes to your profile?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateProfileToServer();
              },
              child: const Text("SAVE", style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _updateProfileToServer() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('$baseUrl/Update_Cususer'); 

    try {
      var request = http.MultipartRequest('POST', url);
      request.fields['id'] = userId;
      request.fields['username'] = _nameController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['phoneno'] = _phoneController.text.trim();
      request.fields['acccode'] = "CUST_DEFAULT";
      request.fields['bio'] = _bioController.text.trim();
      request.fields['city'] = _selectedCity ?? "";

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image', 
          _image!.path,
          filename: path.basename(_image!.path),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update session with latest values
          final session = UserSession();
          final updatedName = _nameController.text.trim();
          await session.saveSession(
            session.userId ?? userId,
            updatedName,
            session.userType?.name,
          );
          if (_selectedCity != null) {
            await session.saveCity(_selectedCity!);
          }
          // Update image URL in session
          if (_image != null) {
            // New image uploaded — construct the URL
            final ext = _image!.path.split('.').last;
            await session.saveImageUrl('$baseUrl/uploads/users/${session.userId}.$ext');
          }

          _showSuccessTrophyDialog();
        } else {
          _showSnackBar(data['message'] ?? "Update failed", isError: true);
        }
      } else {
        _showSnackBar("Server Error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM3YxeXp6Znd4bmZyZ3RreHpxZ3RreHpxZ3RreHpxZ3RreHpxJmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/l0HlIDU8PZFn8vvDG/giphy.gif",
              height: 120,
            ),
            const SizedBox(height: 15),
            const Text("Champion Updated! 🏆", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00A36C))),
            const Text("Your profile is match-ready.", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: const Text("BACK TO PROFILE", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange, size: 24),
            SizedBox(width: 10),
            Text("Location Disabled"),
          ],
        ),
        content: const Text(
          "Location services are turned off. Please enable location services in your device settings to auto-detect your location.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openLocationSettings();
            },
            child: const Text(
              "OPEN SETTINGS",
              style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text("Permission Denied"),
          ],
        ),
        content: const Text(
          "Location permission is permanently denied. Please enable it from your app settings to use auto-detect.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text(
              "OPEN APP SETTINGS",
              style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic to determine which image to show
    ImageProvider avatarImage;
    if (_image != null) {
      avatarImage = FileImage(_image!); // Locally picked image
    } else if (_serverImageUrl != null && _serverImageUrl!.isNotEmpty) {
      avatarImage = NetworkImage('$baseUrl/$_serverImageUrl'); // Image from Go server
    } else {
      avatarImage = const NetworkImage('https://via.placeholder.com/150'); // Placeholder
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        actions: [
          _isLoading 
            ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ))
            : TextButton(
                onPressed: _confirmSave,
                child: const Text("Save", style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
        ],
      ),
      body: _isLoading && _nameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Initial load spinner
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(context).dividerColor,
                            backgroundImage: avatarImage,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFF00A36C), shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField("Full Name", _nameController, Icons.person_outline),
                    _buildTextField("Email Address", _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    _buildTextField("Phone Number", _phoneController, Icons.phone_android_outlined, keyboardType: TextInputType.phone, isNumberOnly: true),
                    _buildLocationDropdown(),
                    _buildTextField("About / Bio", _bioController, Icons.info_outline, maxLines: 3, isRequired: false),
                    const SizedBox(height: 30),
                    _buildDeleteTile(Icons.delete_outline, "Delete Account", isDestructive: true, isLast: true, onTap: () => context.push('/delete-account')),
                  ],
                ),
              ),
            ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildDeleteTile(IconData icon, String title, {bool isLast = false, bool isDestructive = false, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isDestructive ? Colors.red : Colors.grey[700]),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 16, color: isDestructive ? Colors.red : null)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildLocationDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          DropdownSearch<String>(
            selectedItem: _selectedCity,
            items: (filter, infiniteScrollProps) =>
                _cities.where((c) => c.toLowerCase().contains(filter.toLowerCase())).toList(),
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: "City",
                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00A36C), width: 2),
                ),
              ),
            ),
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Search and select location",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              emptyBuilder: (context, searchEntry) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No results found", style: TextStyle(color: Colors.grey)),
                ),
              ),
            ),
            onChanged: (value) {
              setState(() => _selectedCity = value);
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isDetectingLocation ? null : _autoDetectCity,
              icon: _isDetectingLocation
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A36C)))
                  : const Icon(Icons.my_location, size: 18),
              label: Text(_isDetectingLocation ? "Detecting..." : "Auto-Detect Location"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00A36C),
                side: const BorderSide(color: Color(0xFF00A36C)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1, bool isNumberOnly = false, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: isNumberOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00A36C), width: 2),
          ),
        ),
        validator: isRequired ? (value) => value!.isEmpty ? "This field is required" : null : null,
      ),
    );
  }
}