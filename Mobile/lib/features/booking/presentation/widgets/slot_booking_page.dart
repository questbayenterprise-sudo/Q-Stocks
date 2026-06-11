// lib/features/booking/presentation/widgets/slot_booking_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/booking_request.dart';
import '../pages/booking_summary_page.dart';
import 'SuccessCountdownDialog.dart';

// ... other imports
class SlotBookingPage extends StatefulWidget {
  final String? firstName;
  final String? email;
  final String? mobile;
  final String venueId; // Added
  final String price; // Added

  const SlotBookingPage({
    super.key,
    this.firstName,
    this.email,
    this.mobile,
    required this.venueId, // Added
    required this.price, // Added
  });

  @override
  State<SlotBookingPage> createState() => _SlotBookingPageState();
}

class _SlotBookingPageState extends State<SlotBookingPage> {
  List<Map<String, dynamic>> _dynamicSlots = []; // Load from DB
  bool _isFetchingSlots = true;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  double _calculatedPrice = 0.0;
  bool _isChecking = false;
  List<Map<String, dynamic>> _existingBookings = [];
  String? _selectedSlot;
  String? formattedDate = "";
  bool _isLoadingHistory = true;
  final mock = [
    {"time_range": "09:00 AM - 10:00 AM", "user": "Rahul"},
  ];
  @override
  void initState() {
    super.initState();
    _loadSlotsFromDB();

    _fetchExistingBookings();
  }

  // void _loadAllData() {
  //   _loadSlotsFromDB();
  //   _loadHistory();
  // }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);

    try {
      // Standardize date format for Go backend
      String formattedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final history = await BookingRepositoryImpl().fetchExistingBookings(
        widget.venueId,
        formattedDateStr,
      );

      if (mounted) {
        setState(() {
          _existingBookings = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadSlotsFromDB() async {
    try {
      // Make sure you are using the Implementation class
      final slots = await BookingRepositoryImpl().fetchVenueSlots(
        widget.venueId,
      );
      setState(() {
        _dynamicSlots = slots;
        _isFetchingSlots = false;
      });
    } catch (e) {
      setState(() => _isFetchingSlots = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading slots: $e")));
    }
  }

  void _fetchExistingBookings() async {
    final List<Map<String, dynamic>> history = await BookingRepositoryImpl()
        .fetchExistingBookings(widget.venueId, formattedDate!);

    setState(() {
      _existingBookings = history;
      _isLoadingHistory = false;
    });
  }

  void _calculateDynamicPrice() {
    if (_startTime != null && _endTime != null) {
      final start = _startTime!.hour + (_startTime!.minute / 60);
      final end = _endTime!.hour + (_endTime!.minute / 60);
      final duration = end - start;
      if (duration > 0) {
        setState(() {
          _calculatedPrice = duration * double.parse(widget.price);
        });
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
      _calculateDynamicPrice();
    }
  }

  Future<void> _processBookingFlow() async {
    setState(() => _isChecking = true);

    // 1. Create booking request with selected times and date
    final currentRequest = BookingRequest(
      userName: "John Doe",
      email: "john.doe@example.com",
      phone: "+1234567890",
      bookingDate: "2026-02-14", // or DateTime if your model uses DateTime
      timeSlot: "10:00 AM - 11:00 AM",
      venue_id: "1",
      court_id: "3",
      slot_id: "15",
      priceperslot: "50.0",
      CusUserId: "1",
    );

    // 2. Initiate Booking V2 (Additive logic)
    final result = await BookingRepositoryImpl().initiateBooking(
      currentRequest,
    );
    if (result != null && result['success'] == true) {
      int bookingId = result['booking_id'];
      String? bookingRef = result['booking_ref']?.toString();

      // 3. Dynamic Payment Provider (Simulation)
      // In production, this would fetch from config: getPaymentConfig()
      bool paymentSuccess = await _simulateThirdPartyPayment(bookingId);

      if (paymentSuccess) {
        _showSuccessOverlay(bookingId, bookingRef: bookingRef);
      }
    }
    setState(() => _isChecking = false);
    await _handleBooking();
  }

  void _showSuccessOverlay(int bookingId, {String? bookingRef}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessCountdownDialog(
        onFinished: () {
          Navigator.pop(context); // Close Dialog
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingSummaryPage(
                date: _selectedDate,
                time:
                    "${_startTime!.format(context)} - ${_endTime!.format(context)}",
                venue: "Turf Name",
                bookingRef: bookingRef,
                bookingId: bookingId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExistingBookingsBox() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : _existingBookings.isEmpty
          ? const Center(child: Text("No bookings for this date"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _existingBookings.length,
              itemBuilder: (context, index) {
                final b = _existingBookings[index];
                final String timeDisplay = b['time_range'] ?? "00:00 - 00:00";
                final String userDisplay = b['user'] ?? "Guest";

                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12), // Slightly rounded
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ), // Subtle border
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.05,
                        ), // Soft box shadow
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Visual Status Indicator
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeDisplay,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  userDisplay,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Visual Hierarchy: Status Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "OCCUPIED",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Turf")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHorizontalCalendar(), // Your existing calendar
            // 2. QUICK SLOTS WITH PRICE (NEW)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Slots Timings & Price",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildQuickSlotsWithPrice(),

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Existing Bookings",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // 2-Inch (approx 190px) Scrollable Rectangle
            Container(
              height: 190,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300,
                ),
              ),
              child: _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _existingBookings.length,
                      itemBuilder: (context, index) {
                        final b = _existingBookings[index];

                        // Logic: Support both 'time_range' combined field OR separate start/end fields
                        final String timeDisplay =
                            b['time_range'] ??
                            "${b['start_time'] ?? ''} - ${b['end_time'] ?? ''}";
                        final String userDisplay =
                            b['user'] ?? b['user_name'] ?? "Guest";

                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.history,
                            color: Colors.orange,
                          ),
                          title: Text(
                            timeDisplay,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Booked by $userDisplay"),
                        );
                      },
                    ),
            ),

            const Divider(height: 40),

            // Custom Range Selector
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Custom Duration",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _selectTime(context, true),
                          child: Text(
                            _startTime?.format(context) ?? "Start Time",
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _selectTime(context, false),
                          child: Text(_endTime?.format(context) ?? "End Time"),
                        ),
                      ),
                    ],
                  ),
                  if (_calculatedPrice > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Total Price: ₹${_calculatedPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildConfirmSection(),
    );
  }

  Widget _buildQuickSlotsWithPrice() {
    if (_isFetchingSlots)
      return const Center(child: CircularProgressIndicator());

    return SizedBox(
      height: 100, // Adjusted height for better proportions
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 20),
        itemCount: _dynamicSlots.length,
        itemBuilder: (context, index) {
          final slot = _dynamicSlots[index];
          bool isBooked = slot['is_booked'] == true;
          bool isSelected = _selectedSlot == slot['range'];

          return GestureDetector(
            onTap: isBooked
                ? null
                : () {
                    /* Existing logic */
                  },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12, bottom: 4),
              decoration: BoxDecoration(
                // Flat background / light tint
                color: isSelected
                    ? const Color(0xFF00A36C).withOpacity(0.1)
                    : (isBooked ? Colors.grey[100] : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                // Dashed or lighter border (using thin light solid as CSS-dashed equivalent)
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00A36C)
                      : Colors.grey.shade300,
                  width: 1,
                ),
                // No shadow for available slots
                boxShadow: null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slot['range'],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isBooked ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${slot['price']}",
                    style: TextStyle(
                      color: isBooked ? Colors.grey : const Color(0xFF00A36C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        padding: const EdgeInsets.only(left: 20),
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));
          bool isSelected = DateUtils.isSameDay(date, _selectedDate);
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _selectedSlot = null; // Reset selection on date change
              });
              _loadHistory(); // Re-fetch data for the new date
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12, bottom: 10, top: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00A36C) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBookingConfirmation() {
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
    final timeStr =
        "${_startTime!.format(context)} - ${_endTime!.format(context)}";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Confirm Booking",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConfirmRow(Icons.calendar_today, "Date", dateStr),
            const SizedBox(height: 12),
            _buildConfirmRow(Icons.access_time, "Time", timeStr),
            const SizedBox(height: 12),
            if (_calculatedPrice > 0)
              _buildConfirmRow(
                Icons.currency_rupee,
                "Price",
                "₹${_calculatedPrice.toStringAsFixed(2)}",
              ),
            if (_selectedSlot != null) ...[
              const SizedBox(height: 12),
              _buildConfirmRow(Icons.event_seat, "Slot", _selectedSlot!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "EDIT",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A36C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _processBookingFlow();
            },
            child: const Text(
              "CONFIRM",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00A36C)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A36C),
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: (_startTime != null && _endTime != null)
            ? _showBookingConfirmation
            : null,
        child: _isChecking
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                "PROCEED TO PAYMENT",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Future<void> _processBookingFlow() async {
  //   setState(() => _isChecking = true);

  //   // 1. Availability Check
  //   bool available = await BookingRepositoryImpl().CheckAvailability(
  //     DateFormat('yyyy-MM-dd').format(_selectedDate),
  //     _startTime!.format(context),
  //     _endTime!.format(context),
  //     widget.venueId,
  //   );

  //   if (available) {
  //     setState(() => _isChecking = false);
  //     _showError("Slot already booked. Please pick another time.");
  //     return;
  //   }
  //   // if (!available) {
  //   //   setState(() => _isChecking = false);
  //   //   _showError("Slot already booked. Please pick another time.");
  //   //   return;
  //   // }

  //   // 2. Navigate to Payment (Conceptual)
  //   // For now, simulating payment success and creating booking
  //   await _handleBooking();
  // }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Updated handleBooking to pass custom times
  Future<void> _handleBooking() async {
    // ... (Existing logic for BookingRequest)
    // On Success:
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSummaryPage(
          date: _selectedDate,
          time: "${_startTime!.format(context)} - ${_endTime!.format(context)}",
          venue: "Turf Name",
          bookingRef: null,
          bookingId: null,
        ),
      ),
    );
  }

  Future<bool> _simulateThirdPartyPayment(int bookingId) async {
    // TODO: Implement actual payment simulation or third-party payment logic
    return true;
  }
}
