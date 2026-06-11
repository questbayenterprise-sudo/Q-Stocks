import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/Session/user_session.dart';
import '../bloc/venue_bloc.dart';
import '../widgets/venue_card.dart';

class MyVenueListPage extends StatefulWidget {
  const MyVenueListPage({super.key});

  @override
  State<MyVenueListPage> createState() => _MyVenueListPageState();
}

class _MyVenueListPageState extends State<MyVenueListPage> {
  String _searchQuery = "";
  bool _showFilterPanel = false;
  String? _selectedLocation;
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<MyVenueBloc>().add(LoadMyVenues());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search by name...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = "";
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
              BlocBuilder<MyVenueBloc, MyVenueState>(
                builder: (context, state) {
                  if (state is! MyVenueLoaded) return const SizedBox.shrink();
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
           Expanded(
  child: BlocListener<MyVenueBloc, MyVenueState>(
  listener: (context, state) {
    if (state is MyVenueLoaded && state.isSuccess) {
      if (state.message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (state.venues.length == 1 && state.message.isEmpty) {
         context.push('/my-add-venue', extra: state.venues.first);
         context.read<MyVenueBloc>().add(LoadMyVenues());
      }
    }

    if (state is MyVenueError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  },
    child: BlocBuilder<MyVenueBloc, MyVenueState>(
      builder: (context, state) {
        if (state is MyVenueLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00A36C),
            ),
          );
        }
        if (state is MyVenueLoaded) {
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
                context.read<MyVenueBloc>().add(LoadMyVenues()),
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
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
          Text(
            UserSession().userType == UserType.admin
                ? "All Venues"
                : "My Turfs",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          if (UserSession().userType == UserType.admin)
            IconButton(
              onPressed: () => context.push('/my-add-venue'),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A36C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
