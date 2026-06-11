import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../bloc/venue_bloc.dart';
import '../widgets/venue_card.dart';

class VenueListPage extends StatefulWidget {
  const VenueListPage({super.key});

  @override
  State<VenueListPage> createState() => _VenueListPageState();
}

class _VenueListPageState extends State<VenueListPage> {
  String _searchQuery = "";
  bool _showFilterPanel = false;
  String? _selectedLocation;
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose(); // Clean up memory
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadVenuesWithLocation();
  }

  Future<void> _loadVenuesWithLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        context.read<VenueBloc>().add(LoadVenues());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        context.read<VenueBloc>().add(LoadVenues());
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (!mounted) return;

      context.read<VenueBloc>().add(LoadVenues(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (_) {
      if (!mounted) return;
      // GPS failed — load all venues without distance
      context.read<VenueBloc>().add(LoadVenues());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            // --- NEW SEARCH & FILTER ROW ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController, // Link the controller
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search by name...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear(); // Clears text UI
                                  setState(() {
                                    _searchQuery = ""; // Resets filter logic
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    onPressed: () =>
                        setState(() => _showFilterPanel = !_showFilterPanel),
                    icon: const Icon(Icons.filter_list),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_showFilterPanel)
              BlocBuilder<VenueBloc, VenueState>(
                builder: (context, state) {
                  if (state is! VenueLoaded) return const SizedBox.shrink();
                  final locations = state.venues
                      .map((e) => e.locationName)
                      .toSet()
                      .toList();
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Location",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<String>(
                          value: _selectedLocation,
                          hint: const Text("All Locations"),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text("All Locations"),
                            ),
                            ...locations.map(
                              (loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedLocation = val),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 12),

            // --- GRID VIEW LIST ---
            Expanded(
              child: BlocListener<VenueBloc, VenueState>(
                listener: (context, state) {
                  if (state is VenueLoaded && state.isSuccess) {
                    if (state.message.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }

                    // If it's an Edit request (from your previous logic)
                    if (state.venues.length == 1 && state.message.isEmpty) {
                      context.push('/add-venue', extra: state.venues.first);
                      context.read<VenueBloc>().add(LoadVenues());
                    }
                  }

                  // --- HANDLE ERRORS ---
                  if (state is VenueError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: BlocBuilder<VenueBloc, VenueState>(
                  builder: (context, state) {
                    if (state is VenueLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00A36C),
                        ),
                      );
                    }
                    if (state is VenueLoaded) {
                      final filteredVenues = state.venues.where((v) {
                        final matchesSearch = v.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                        final matchesLoc =
                            _selectedLocation == null ||
                            v.locationName == _selectedLocation;
                        return matchesSearch && matchesLoc;
                      }).toList();

                      if (filteredVenues.isEmpty)
                        return const Center(child: Text("No venues found."));

                      return RefreshIndicator(
                        onRefresh: () async =>
                            context.read<VenueBloc>().add(LoadVenues()),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isGridView
                              ? GridView.builder(
                                  key: const ValueKey('grid'),
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.8,
                                      ),
                                  itemCount: filteredVenues.length,
                                  itemBuilder: (context, index) => VenueCard(
                                    venue: filteredVenues[index],
                                    isGrid: true,
                                  ),
                                )
                              : ListView.builder(
                                  key: const ValueKey('list'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: filteredVenues.length,
                                  itemBuilder: (context, index) => VenueCard(
                                    venue: filteredVenues[index],
                                    isGrid: false,
                                  ),
                                ),
                        ),
                      );
                    }
                    return const Center(child: Text("Start exploring venues!"));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: Row(
        children: [
          const Text(
            "Explore Venues",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          const Spacer(),
          // TOGGLE BUTTON
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
    );
  }
}
