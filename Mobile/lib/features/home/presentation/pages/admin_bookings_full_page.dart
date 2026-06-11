import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Models/home_data.dart';
import '../bloc/home_bloc.dart';

class AdminBookingsFullPage extends StatefulWidget {
  const AdminBookingsFullPage({super.key});

  @override
  State<AdminBookingsFullPage> createState() => _AdminBookingsFullPageState();
}

class _AdminBookingsFullPageState extends State<AdminBookingsFullPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Booking History"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download, color: Color(0xFF00A36C)),
          ), // Excel Export
        ],
      ),
      endDrawer: _buildAdvancedFilterPanel(), // Side Panel
       body: BlocBuilder<HomeBloc, HomeState>( // 1. Use BlocBuilder
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HomeLoaded) {
            return Column(
              children: [
                _buildSearchBar(),
                // 2. Pass the data to your list builder
                Expanded(child: _buildPaginatedList(state.recentBookings)), 
                _buildPaginationFooter(),
              ],
            );
          }

          return const Center(child: Text("No bookings found."));
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search ID, User, or Turf...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilterPanel() {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Advanced Filters",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text("Status"),
              DropdownButton(
                items: const [],
                onChanged: (v) {},
                isExpanded: true,
              ),
              const SizedBox(height: 16),
              const Text("Payment Type"),
              DropdownButton(
                items: const [],
                onChanged: (v) {},
                isExpanded: true,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "APPLY FILTERS",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Rows per page: 10", style: TextStyle(fontSize: 12)),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chevron_left),
              ),
              const Text("Page 1 of 12"),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildPaginatedList(List<RecentBooking> bookings) {
    if (bookings.isEmpty) {
      return const Center(child: Text("No records found"));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF00A36C).withOpacity(0.1),
              child: const Icon(Icons.receipt_long, color: Color(0xFF00A36C)),
            ),
            title: Text(
              booking.courtName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${booking.bookingRef} • ${booking.userName}"),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${booking.price}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusBadge(booking.status), // Reuse your existing badge method
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildStatusBadge(BookingStatus status) {
    Color color = status == BookingStatus.confirmed ? const Color(0xFF00A36C) : Colors.orange;
    String label = status == BookingStatus.confirmed ? "CONFIRMED" : "PENDING";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
