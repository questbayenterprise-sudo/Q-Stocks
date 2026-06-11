import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../domain/entities/venue_slot.dart';
import '../../domain/entities/venue_game.dart';
import '../bloc/venue_bloc.dart';
import '../../domain/entities/venue.dart';
import '../../../../core/widgets/turf_loader.dart';

class MyAddVenuePage extends StatefulWidget {
  final MyVenueEntity? initialVenue;
  const MyAddVenuePage({super.key, this.initialVenue});

  @override
  State<MyAddVenuePage> createState() => _MyAddVenuePageState();
}

class _MyAddVenuePageState extends State<MyAddVenuePage> {
  List<VenueSlot> _slots = [];
  final _formKey = GlobalKey<FormState>();
  final String baseUrl = AppConfig.baseUrl;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _aboutController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // --- Location Autocomplete ---
  final _locationSearchController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();
  List<String> _allCities = [];
  List<String> _filteredCities = [];
  bool _isLoadingCities = true;
  bool _showCityDropdown = false;
  String? _selectedCity;
  Timer? _cityDebounce;
  bool _isDetectingLocation = false;

  // --- Games Selection ---
  List<VenueGame> _availableGames = [];
  bool _isLoadingSports = true;
  List<VenueGame> _selectedGames = [];
  final _otherGameController = TextEditingController();
  bool _showOtherGameInput = false;
  String? _sportsValidationError;

  @override
  void initState() {
    super.initState();
    _loadMasterData();

    _locationSearchController.addListener(_onCitySearchChanged);
    _locationFocusNode.addListener(() {
      if (_locationFocusNode.hasFocus) {
        setState(() {
          _showCityDropdown = true;
          _filteredCities = _allCities;
        });
      }
    });

    if (widget.initialVenue != null) {
      final venue = widget.initialVenue!;

      _nameController.text = venue.name;
      _addressController.text = venue.locationName;
      _priceController.text = venue.price.toString();
      _aboutController.text = venue.about;
      _selectedCity = venue.locationName;
      _locationSearchController.text = venue.locationName;

      _customSlots = List<VenueSlot>.from(venue.slots);
      _selectedGames = List<VenueGame>.from(venue.games);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _aboutController.dispose();
    _otherGameController.dispose();
    _locationSearchController.dispose();
    _locationFocusNode.dispose();
    _cityDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMasterData() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/GetMasterDetailsForVenueAdd');
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (data['success'] == true && mounted) {
        setState(() {
          // Sports
          if (data['sports'] != null) {
            _availableGames = (data['sports'] as List)
                .map((s) => VenueGame(id: s['id'] as int, game: s['name'] as String))
                .toList();
          }
          _isLoadingSports = false;

          // Cities
          if (data['cities'] != null) {
            _allCities = List<String>.from(data['cities']);
            _filteredCities = _allCities;
          }
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSports = false;
          _isLoadingCities = false;
        });
      }
    }
  }

  void _onCitySearchChanged() {
    if (_cityDebounce?.isActive ?? false) _cityDebounce!.cancel();
    _cityDebounce = Timer(const Duration(milliseconds: 300), () {
      final query = _locationSearchController.text.trim().toLowerCase();
      setState(() {
        _showCityDropdown = true;
        _filteredCities = query.isEmpty
            ? _allCities
            : _allCities
                .where((c) => c.toLowerCase().contains(query))
                .toList();
      });
    });
  }

  void _selectCity(String city) {
    setState(() {
      _selectedCity = city;
      _locationSearchController.text = city;
      _addressController.text = city;
      _showCityDropdown = false;
    });
    _locationFocusNode.unfocus();
  }

  Future<void> _addNewCity(String cityName) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/Insert_City');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": cityName}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final name = data['data']['name'] as String;
        await _loadMasterData(); // Refresh list
        _selectCity(name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add city: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<VenueSlot> _customSlots = [];

  bool _isOverlap(TimeOfDay start, TimeOfDay end, {int? excludeIndex}) {
    double newStart = start.hour + start.minute / 60.0;
    double newEnd = end.hour + end.minute / 60.0;

    for (int i = 0; i < _customSlots.length; i++) {
      if (i == excludeIndex) continue;
      double existingStart =
          _customSlots[i].startTime.hour +
          _customSlots[i].startTime.minute / 60.0;
      double existingEnd =
          _customSlots[i].endTime.hour + _customSlots[i].endTime.minute / 60.0;

      if (newStart < existingEnd && newEnd > existingStart) return true;
    }
    return false;
  }

  void _showSlotModal({VenueSlot? existingSlot, int? index}) {
    TimeOfDay start =
        existingSlot?.startTime ?? const TimeOfDay(hour: 6, minute: 0);
    TimeOfDay end =
        existingSlot?.endTime ?? const TimeOfDay(hour: 7, minute: 0);
    final priceCtrl = TextEditingController(
      text: existingSlot?.price.toString() ?? "",
    );
    final labelCtrl = TextEditingController(text: existingSlot?.label ?? "");
    final isEdit = existingSlot != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A36C).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_calendar : Icons.add_alarm,
                            color: const Color(0xFF00A36C),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEdit ? "Edit Slot" : "Add New Slot",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Time pickers row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: ctx,
                                initialTime: start,
                                helpText: "START TIME",
                                builder: (c, child) => Theme(
                                  data: Theme.of(c).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF00A36C),
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (t != null) setModalState(() => start = t);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A36C).withAlpha(12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF00A36C).withAlpha(60)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login_rounded, size: 14, color: const Color(0xFF00A36C)),
                                      const SizedBox(width: 4),
                                      Text("START", style: TextStyle(
                                        color: const Color(0xFF00A36C), fontSize: 11,
                                        fontWeight: FontWeight.bold, letterSpacing: 1,
                                      )),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    start.format(ctx),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.arrow_forward_rounded, color: Colors.grey[400], size: 20),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: ctx,
                                initialTime: end,
                                helpText: "END TIME",
                                builder: (c, child) => Theme(
                                  data: Theme.of(c).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF00A36C),
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (t != null) setModalState(() => end = t);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.orange.withAlpha(60)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.logout_rounded, size: 14, color: Colors.orange.shade700),
                                      const SizedBox(width: 4),
                                      Text("END", style: TextStyle(
                                        color: Colors.orange.shade700, fontSize: 11,
                                        fontWeight: FontWeight.bold, letterSpacing: 1,
                                      )),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    end.format(ctx),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Price & Label
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Price (₹)",
                              prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF00A36C), size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF00A36C), width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: labelCtrl,
                            decoration: InputDecoration(
                              labelText: "Label (optional)",
                              prefixIcon: const Icon(Icons.label_outline, color: Colors.grey, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF00A36C), width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A36C),
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              double startVal = start.hour + start.minute / 60.0;
                              double endVal = end.hour + end.minute / 60.0;

                              if (endVal <= startVal) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text("End time must be after start time"), backgroundColor: Colors.orange),
                                );
                                return;
                              }
                              if (_isOverlap(start, end, excludeIndex: index)) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text("Time slot overlaps with an existing slot"), backgroundColor: Colors.orange),
                                );
                                return;
                              }

                              final newSlot = VenueSlot(
                                startTime: start,
                                endTime: end,
                                price: double.tryParse(priceCtrl.text) ?? 0,
                                label: labelCtrl.text,
                              );
                              setState(() {
                                if (index != null) {
                                  _customSlots[index] = newSlot;
                                } else {
                                  _customSlots.add(newSlot);
                                }
                              });
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              isEdit ? "UPDATE SLOT" : "ADD SLOT",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  bool _isGameSelected(VenueGame game) {
    return _selectedGames.any((s) =>
        s.id != null && game.id != null ? s.id == game.id : s.game == game.game);
  }

  void _toggleGame(VenueGame game) {
    setState(() {
      if (_isGameSelected(game)) {
        _selectedGames.removeWhere((s) =>
            s.id != null && game.id != null ? s.id == game.id : s.game == game.game);
      } else {
        _selectedGames.add(game);
      }
      _sportsValidationError = null;
    });
  }

  void _addOtherGame() {
    final text = _otherGameController.text.trim();
    if (text.isEmpty) return;
    final alreadyExists = _selectedGames.any(
      (g) => g.game.toLowerCase() == text.toLowerCase(),
    ) || _availableGames.any(
      (g) => g.game.toLowerCase() == text.toLowerCase(),
    );
    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Game already exists")),
      );
      return;
    }
    setState(() {
      _selectedGames.add(VenueGame(game: text));
      _otherGameController.clear();
      _showOtherGameInput = false;
    });
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, _, __) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHJueXN6Znd4bmZyZ3RreHpxZ3RreHpxZ3RreHpxZ3RreHpxJmVwPXYxX2ludGVybmFsX2dpZl9ieV9pZCZjdD1n/3o7TKDkDbIDJieKbVm/giphy.gif",
              height: 120,
            ),
            const SizedBox(height: 10),
            const Text(
              "GOAAALLL! ⚽",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A36C),
              ),
            ),
            const Text("Your Turf is now Live!", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A36C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: const Text(
                "Turf created Successfully",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _autoDetectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange),
                  SizedBox(width: 10),
                  Text("Location Disabled"),
                ],
              ),
              content: const Text("Please turn on location services to auto-detect your venue location."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Geolocator.openLocationSettings();
                  },
                  child: const Text("OPEN SETTINGS", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
        setState(() => _isDetectingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permission denied"), backgroundColor: Colors.orange),
            );
          }
          setState(() => _isDetectingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission permanently denied. Enable in app settings."), backgroundColor: Colors.red),
          );
        }
        setState(() => _isDetectingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? '';
        if (city.isNotEmpty) {
          // Check if city exists in list
          final match = _allCities.firstWhere(
            (c) => c.toLowerCase() == city.toLowerCase(),
            orElse: () => '',
          );
          if (match.isNotEmpty) {
            _selectCity(match);
          } else {
            // Add the new city
            await _addNewCity(city);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Detected: $city"),
                backgroundColor: const Color(0xFF00A36C),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to detect location: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Widget _buildCityList() {
    final query = _locationSearchController.text.trim();
    final bool hasExactMatch = _allCities.any(
      (c) => c.toLowerCase() == query.toLowerCase(),
    );

    if (_filteredCities.isEmpty && query.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text("No cities available", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        // Filtered city results
        ..._filteredCities.map((city) {
          final isSelected = _selectedCity == city;
          return ListTile(
            dense: true,
            leading: Icon(
              isSelected ? Icons.check_circle : Icons.location_city,
              color: isSelected ? const Color(0xFF00A36C) : Colors.grey[400],
              size: 20,
            ),
            title: _buildHighlightedText(city, query),
            onTap: () => _selectCity(city),
          );
        }),

        // "Add new" option when no exact match
        if (query.isNotEmpty && !hasExactMatch)
          ListTile(
            dense: true,
            leading: const Icon(Icons.add_circle_outline, color: Color(0xFF00A36C), size: 20),
            title: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  const TextSpan(text: 'Add "'),
                  TextSpan(
                    text: query,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A36C),
                    ),
                  ),
                  const TextSpan(text: '"'),
                ],
              ),
            ),
            onTap: () => _addNewCity(query),
          ),

        // No results message
        if (_filteredCities.isEmpty && query.isNotEmpty && hasExactMatch)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text("No results found", style: TextStyle(color: Colors.grey)),
            ),
          ),
      ],
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 14));
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);

    if (startIndex == -1) {
      return Text(text, style: const TextStyle(fontSize: 14));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, startIndex + query.length),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A36C),
            ),
          ),
          TextSpan(text: text.substring(startIndex + query.length)),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF00A36C)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00A36C), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Add New Turf"), elevation: 0),
      body: BlocListener<MyVenueBloc, MyVenueState>(
        listener: (context, state) {
          if (state is MyVenueLoaded && state.isSuccess) {
            _showSuccessDialog();
          }

          if (state is MyVenueError) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Turf Image",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[300]!),
                          image: () {
                            if (_imageFile != null) {
                              return DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              );
                            }
                            if (widget.initialVenue != null &&
                                widget.initialVenue!.imageUrl.isNotEmpty) {
                              String path = widget.initialVenue!.imageUrl;
                              if (path.startsWith('http')) {
                                return DecorationImage(
                                  image: NetworkImage(path),
                                  fit: BoxFit.cover,
                                );
                              } else if (path.contains('uploads')) {
                                String fullUrl =
                                    "$baseUrl/${path.replaceAll('\\', '/')}";
                                return DecorationImage(
                                  image: NetworkImage(fullUrl),
                                  fit: BoxFit.cover,
                                );
                              } else {
                                File localFile = File(path);
                                if (localFile.existsSync()) {
                                  return DecorationImage(
                                    image: FileImage(localFile),
                                    fit: BoxFit.cover,
                                  );
                                }
                              }
                            }
                            return null;
                          }(),
                        ),
                        child: (_imageFile == null &&
                                (widget.initialVenue == null ||
                                    widget.initialVenue!.imageUrl.isEmpty))
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                  Text("Upload Turf Photo",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputStyle("Turf Name", Icons.sports_soccer),
                      validator: (v) => v!.isEmpty ? "Enter turf name" : null,
                    ),
                    const SizedBox(height: 20),
                    // --- Location Autocomplete ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Auto-detect button
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Location / Area",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _isDetectingLocation ? null : _autoDetectLocation,
                              icon: _isDetectingLocation
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A36C)),
                                    )
                                  : const Icon(Icons.my_location, size: 18, color: Color(0xFF00A36C)),
                              label: Text(
                                _isDetectingLocation ? "Detecting..." : "Auto Detect",
                                style: const TextStyle(color: Color(0xFF00A36C), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationSearchController,
                          focusNode: _locationFocusNode,
                          decoration: InputDecoration(
                            labelText: "Location / Area",
                            hintText: "Search and select location",
                            prefixIcon: const Icon(Icons.location_on, color: Color(0xFF00A36C)),
                            suffixIcon: _locationSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _locationSearchController.clear();
                                        _addressController.clear();
                                        _selectedCity = null;
                                        _filteredCities = _allCities;
                                        _showCityDropdown = true;
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF00A36C), width: 2),
                            ),
                          ),
                          validator: (_) => (_selectedCity == null || _selectedCity!.isEmpty)
                              ? "Select a location"
                              : null,
                          onTap: () {
                            setState(() {
                              _showCityDropdown = true;
                              if (_locationSearchController.text.isEmpty) {
                                _filteredCities = _allCities;
                              }
                            });
                          },
                        ),
                        if (_showCityDropdown) ...[
                          const SizedBox(height: 4),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isLoadingCities
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF00A36C),
                                        ),
                                      ),
                                    ),
                                  )
                                : _buildCityList(),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Games Selector (Pill/Capsule Chips) ---
                    Row(
                      children: [
                        const Text(
                          "Sports Available *",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_isLoadingSports) ...[
                          const SizedBox(width: 10),
                          const SizedBox(
                            height: 16, width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A36C)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_sportsValidationError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _sportsValidationError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),

                    // Predefined game capsules + "+ Other" pill
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._availableGames.map((game) {
                          final selected = _isGameSelected(game);
                          return GestureDetector(
                            onTap: () => _toggleGame(game),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF00A36C)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF00A36C)
                                      : Colors.grey[350]!,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    game.game,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : Colors.grey[800],
                                    ),
                                  ),
                                  if (selected) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.close,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),

                        // Custom games added via "Other" — shown as selected pills
                        ..._selectedGames
                            .where((g) => g.id == null)
                            .map((game) {
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedGames.remove(game));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A36C),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFF00A36C),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    game.game,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.close,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // "+ Other" pill
                        GestureDetector(
                          onTap: () {
                            setState(() => _showOtherGameInput = true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.grey[350]!,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16, color: Colors.grey[700]),
                                const SizedBox(width: 4),
                                Text(
                                  "Other",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Other Game Input Field
                    if (_showOtherGameInput) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _otherGameController,
                              autofocus: true,
                              onSubmitted: (_) => _addOtherGame(),
                              decoration: InputDecoration(
                                hintText: "Enter custom game name",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A36C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onPressed: _addOtherGame,
                            child: const Text("Add",
                                style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _otherGameController.clear();
                                _showOtherGameInput = false;
                              });
                            },
                            icon: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 10),
                    const Divider(height: 40),

                    // --- Slots Header ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Slots & Pricing",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showSlotModal(),
                          icon: const Icon(Icons.add, size: 18, color: Colors.white),
                          label: const Text("Add Slot", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A36C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- Empty state ---
                    if (_customSlots.isEmpty && _slots.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.schedule, size: 40, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text("No slots added yet", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("Tap 'Add Slot' to create time slots", style: TextStyle(color: Colors.grey[350], fontSize: 12)),
                          ],
                        ),
                      ),

                    // --- Slot cards ---
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customSlots.length,
                      itemBuilder: (context, i) {
                        final s = _customSlots[i];
                        final durationMin = (s.endTime.hour * 60 + s.endTime.minute) -
                            (s.startTime.hour * 60 + s.startTime.minute);
                        final hours = durationMin ~/ 60;
                        final mins = durationMin % 60;
                        final durationStr = hours > 0
                            ? (mins > 0 ? "${hours}h ${mins}m" : "${hours}h")
                            : "${mins}m";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(8),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Time indicator bar
                                Container(
                                  width: 4,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A36C),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Time & details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF00A36C)),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${s.startTime.format(context)} - ${s.endTime.format(context)}",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          // Duration chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withAlpha(15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              durationStr,
                                              style: TextStyle(color: Colors.blue[700], fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Label chip
                                          if (s.label.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withAlpha(15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                s.label,
                                                style: TextStyle(color: Colors.purple[700], fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Price badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00A36C).withAlpha(15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "₹${s.price.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      color: Color(0xFF00A36C),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Actions
                                SizedBox(
                                  width: 32,
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[400]),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _showSlotModal(existingSlot: s, index: i);
                                      } else if (val == 'delete') {
                                        setState(() => _customSlots.removeAt(i));
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18, color: Color(0xFF00A36C)),
                                            SizedBox(width: 8),
                                            Text("Edit"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text("Delete", style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    ..._slots
                        .map(
                          (slot) => ListTile(
                            title: Text("${slot.startTime} - ${slot.endTime}"),
                            subtitle: Text("Price: ₹${slot.price}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => setState(() => _slots.remove(slot)),
                            ),
                          ),
                        )
                        .toList(),

                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _aboutController,
                      maxLines: 4,
                      decoration: _inputStyle("About Venue", Icons.info_outline),
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A36C),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Validate sports selection
                        setState(() {
                          _sportsValidationError = _selectedGames.isEmpty
                              ? "Please select at least one sport"
                              : null;
                        });

                        if (_formKey.currentState!.validate() && _selectedGames.isNotEmpty) {
                          String finalImagePath = "";
                          if (_imageFile != null) {
                            finalImagePath = _imageFile!.path;
                          } else if (widget.initialVenue != null) {
                            finalImagePath = widget.initialVenue!.imageUrl;
                          }

                          if (finalImagePath.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please upload a turf image"),
                              ),
                            );
                            return;
                          }

                          final venue = MyVenueEntity(
                            id: widget.initialVenue?.id ?? "",
                            name: _nameController.text,
                            imageUrl: finalImagePath,
                            locationName: _selectedCity ?? _addressController.text,
                            distance: 0,
                            price: double.tryParse(_priceController.text) ?? 1200.0,
                            rating: 5.0,
                            reviewsCount: 0,
                            isBookable: true,
                            sportsIcons: ['cricket'],
                            about: _aboutController.text,
                            amenities: ['Parking', 'Water', 'Washroom'],
                            slots: _customSlots,
                            games: _selectedGames,
                          );

                          context.read<MyVenueBloc>().add(AddMyVenue(venue));
                        }
                      },
                      child: const Text(
                        "SAVE TURF",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            BlocBuilder<MyVenueBloc, MyVenueState>(
              builder: (context, state) {
                if (state is MyVenueSaving) {
                  return const TurfLoader(message: "Publishing to Q-Sports...");
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
