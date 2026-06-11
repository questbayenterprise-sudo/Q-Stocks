import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../auth/Session/user_session.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  final String baseUrl = AppConfig.baseUrl;
  String get userId => UserSession().userId ?? "1";

  List<String> _cities = [];
  List<String> _filteredCities = [];
  final _searchController = TextEditingController();
  Timer? _debounce;

  String? _detectedCity;
  double? _latitude;
  double? _longitude;
  bool _isDetecting = false;
  bool _isSaving = false;
  bool _citiesLoading = true;
  String? _selectedCity;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _autoDetectLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredCities = query.isEmpty
            ? _cities
            : _cities.where((c) => c.toLowerCase().contains(query)).toList();
      });
    });
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
            _filteredCities = _cities;
          });
        }
      }
    } catch (e) {
      // Cities will remain empty, user can retry
    } finally {
      if (mounted) setState(() => _citiesLoading = false);
    }
  }

  Future<void> _autoDetectLocation() async {
    setState(() {
      _isDetecting = true;
      _errorMessage = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isDetecting = false);
          _showLocationServiceDialog();
        }
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = "Location permission denied. Please select manually.";
            _isDetecting = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isDetecting = false);
          _showPermissionDeniedDialog();
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Reverse geocode to get city name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? "";

        if (city.isNotEmpty) {
          setState(() {
            _detectedCity = city;
            _selectedCity = city;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Could not detect location. Please select manually.";
      });
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  Future<void> _saveLocation(String city) async {
    setState(() => _isSaving = true);

    try {
      final url = Uri.parse('$baseUrl/Update_UserLocation');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "city": city,
          "latitude": _latitude ?? 0.0,
          "longitude": _longitude ?? 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Cache in session
          await UserSession().saveCity(city);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Location set to $city"),
                backgroundColor: const Color(0xFF00A36C),
              ),
            );
            context.pop(city); // Return selected city
          }
        } else {
          _showError(data['message'] ?? "Failed to update location");
        }
      } else {
        _showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Connection error. Please try again.");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
            child: const Text("SELECT MANUALLY", style: TextStyle(color: Colors.grey)),
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
            child: const Text("SELECT MANUALLY", style: TextStyle(color: Colors.grey)),
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

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- Auto-Detect Card ---
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00A36C).withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00A36C).withAlpha(50)),
            ),
            child: Column(
              children: [
                if (_isDetecting)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A36C)),
                      ),
                      SizedBox(width: 12),
                      Text("Detecting your location...", style: TextStyle(fontSize: 14)),
                    ],
                  )
                else if (_detectedCity != null)
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Color(0xFF00A36C), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Detected Location",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _detectedCity!,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveLocation(_detectedCity!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A36C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("USE THIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(fontSize: 13, color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _autoDetectLocation,
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text("Auto-Detect Location"),
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
              ],
            ),
          ),

          // --- Divider ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("or select manually", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- Search Box ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search and select location",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filteredCities = _cities);
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00A36C), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // --- City List ---
          Expanded(
            child: _citiesLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text("No results found", style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredCities.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final city = _filteredCities[index];
                          final isSelected = city == _selectedCity;

                          return ListTile(
                            onTap: () => _saveLocation(city),
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: isSelected ? const Color(0xFF00A36C) : Colors.grey.shade400,
                              size: 22,
                            ),
                            title: Text(
                              city,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFF00A36C) : null,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Color(0xFF00A36C), size: 20)
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
