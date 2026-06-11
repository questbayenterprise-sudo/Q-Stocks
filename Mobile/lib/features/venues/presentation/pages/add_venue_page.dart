import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/venue_slot.dart';
import '../bloc/venue_bloc.dart';
import '../../domain/entities/venue.dart';
import '../../../../core/widgets/turf_loader.dart';

class AddVenuePage extends StatefulWidget {
  final VenueEntity? initialVenue;
  const AddVenuePage({super.key, this.initialVenue});

  @override
  State<AddVenuePage> createState() => _AddVenuePageState();
}

class _AddVenuePageState extends State<AddVenuePage> {
  final List<VenueSlot> _slots = [];
  final _formKey = GlobalKey<FormState>();
  final String baseUrl = AppConfig.baseUrl;

  // Controllers for the input fields
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _aboutController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();

    // Check if we are in Edit Mode
    if (widget.initialVenue != null) {
      final venue = widget.initialVenue!;

      // Bind Text Fields
      _nameController.text = venue.name;
      _addressController.text = venue.locationName;
      _priceController.text = venue.price.toString();
      _aboutController.text = venue.about;

      // Bind Slots
      _customSlots = List<VenueSlot>.from(venue.slots);

      // Note: _imageFile remains null until a NEW image is picked.
      // We handle the display logic in the build method.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _aboutController.dispose();
    super.dispose();
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingSlot == null ? "Add Custom Slot" : "Edit Slot"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("Start: ${start.format(context)}"),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                var t = await showTimePicker(
                  context: context,
                  initialTime: start,
                );
                if (t != null) start = t;
              },
            ),
            ListTile(
              title: Text("End: ${end.format(context)}"),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                var t = await showTimePicker(
                  context: context,
                  initialTime: end,
                );
                if (t != null) end = t;
              },
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: "₹"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              double startVal = start.hour + start.minute / 60.0;
              double endVal = end.hour + end.minute / 60.0;

              if (endVal <= startVal) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("End time must be after start time"),
                  ),
                );
                return;
              }
              if (_isOverlap(start, end, excludeIndex: index)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Time slot overlaps with an existing slot"),
                  ),
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
                if (index != null)
                  _customSlots[index] = newSlot;
                else
                  _customSlots.add(newSlot);
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
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
                Navigator.pop(context); // Close Dialog
                context.pop(); // Go back to List Page
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
      appBar: AppBar(title: const Text("Add New Turf"), elevation: 0),
      body: BlocListener<VenueBloc, VenueState>(
        listener: (context, state) {
          // 1. Handle Success
          if (state is VenueLoaded && state.isSuccess) {
            _showSuccessDialog();
          }

          // 2. Handle Error with a professional SnackBar
          if (state is VenueError) {
            ScaffoldMessenger.of(
              context,
            ).hideCurrentSnackBar(); // Clear existing bars
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
                            // 1. Priority: Newly picked local file
                            if (_imageFile != null) {
                              return DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              );
                            }

                            // 2. Secondary: Initial venue data (Edit Mode)
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
                            return null; // Show placeholder child instead
                          }(),
                        ),
                        child:
                            (_imageFile == null &&
                                (widget.initialVenue == null ||
                                    widget.initialVenue!.imageUrl.isEmpty))
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    "Upload Turf Photo",
                                    style: TextStyle(color: Colors.grey),
                                  ),
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
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputStyle(
                        "Location / Area",
                        Icons.location_on,
                      ),
                      validator: (v) => v!.isEmpty ? "Enter location" : null,
                    ),
                    const SizedBox(height: 20),
                    // Inside the Column in build()
                    const SizedBox(height: 10),

                    const Divider(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Slots & Pricing",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showSlotModal(),
                          icon: const Icon(Icons.add),
                          label: const Text("Add Slot"),
                        ),
                      ],
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customSlots.length,
                      itemBuilder: (context, i) {
                        final s = _customSlots[i];
                        return Card(
                          child: ListTile(
                            title: Text(
                              "${s.startTime.format(context)} - ${s.endTime.format(context)}",
                            ),
                            subtitle: Text(
                              "₹${s.price} ${s.label.isNotEmpty ? '(${s.label})' : ''}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _showSlotModal(existingSlot: s, index: i),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      setState(() => _customSlots.removeAt(i)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Dynamic List of Slots
                    ..._slots
                        .map(
                          (slot) => ListTile(
                            title: Text("${slot.startTime} - ${slot.endTime}"),
                            subtitle: Text("Price: ₹${slot.price}"),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  setState(() => _slots.remove(slot)),
                            ),
                          ),
                        )
                        .toList(),
                    // TextFormField(
                    //   controller: _priceController,
                    //   keyboardType: TextInputType.number,
                    //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    //   decoration: _inputStyle("Price per Hour (INR)", Icons.currency_rupee),
                    //   validator: (v) => v!.isEmpty ? "Enter price" : null,
                    // ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _aboutController,
                      maxLines: 4,
                      decoration: _inputStyle(
                        "About Venue",
                        Icons.info_outline,
                      ),
                      validator: (v) =>
                          v!.isEmpty ? "Enter some details" : null,
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
                        if (_formKey.currentState!.validate()) {
                          // Determine the image path to send
                          String finalImagePath = "";
                          if (_imageFile != null) {
                            finalImagePath = _imageFile!.path; // New local file
                          } else if (widget.initialVenue != null) {
                            finalImagePath = widget
                                .initialVenue!
                                .imageUrl; // Keep old image (URL or path)
                          }

                          if (finalImagePath.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please upload a turf image"),
                              ),
                            );
                            return;
                          }

                          // Create entity and trigger event
                          final venue = VenueEntity(
                            id: widget.initialVenue?.id ?? "",
                            name: _nameController.text,
                            imageUrl: finalImagePath, // Pass the resolved path
                            locationName: _addressController.text,
                            distance: 0,
                            price:
                                double.tryParse(_priceController.text) ??
                                1200.0,
                            rating: 5.0,
                            reviewsCount: 0,
                            isBookable: true,
                            sportsIcons: ['cricket'],
                            about: _aboutController.text,
                            amenities: ['Parking', 'Water', 'Washroom'],
                            slots: _customSlots,
                          );

                          context.read<VenueBloc>().add(AddVenue(venue));
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

            // --- Full Screen Loader Overlay ---
            // This displays when the Bloc is in 'VenueSaving' state
            BlocBuilder<VenueBloc, VenueState>(
              builder: (context, state) {
                if (state is VenueSaving) {
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
