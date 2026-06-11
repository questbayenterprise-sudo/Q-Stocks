import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../domain/entities/venue.dart';
import '../../../booking/data/repositories/booking_repository_impl.dart';
import '../../../booking/domain/entities/booking_request.dart';
import '../../../booking/presentation/pages/booking_summary_page.dart';
import '../../../booking/presentation/widgets/SuccessCountdownDialog.dart';
import '../../../auth/Session/user_session.dart';
import '../../../qr_scan/presentation/pages/qr_scanner_page.dart';

class MyVenueDetailPage extends StatefulWidget {
  final MyVenueEntity venue;
  const MyVenueDetailPage({super.key, required this.venue});

  @override
  State<MyVenueDetailPage> createState() => _MyVenueDetailPageState();
}

class _MyVenueDetailPageState extends State<MyVenueDetailPage> {
  final String baseUrl = AppConfig.baseUrl;
  final BookingRepositoryImpl _bookingRepo = BookingRepositoryImpl();

  // Schedule state
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _venueSlots = [];
  List<Map<String, dynamic>> _existingBookings = [];
  bool _isFetchingSlots = true;
  bool _isLoadingBookings = true;
  bool _isBooking = false;

  // Custom time range selection
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _validationError;
  bool _isHolding = false;

  // Generate 30-min interval time options from venue slots
  List<TimeOfDay> _timeOptions = [];

  @override
  void initState() {
    super.initState();
    _loadSlots();
    _loadExistingBookings();
  }

  Future<void> _loadSlots() async {
    try {
      final slots = await _bookingRepo.fetchVenueSlots(widget.venue.id);
      if (mounted) {
        setState(() {
          _venueSlots = slots;
          _isFetchingSlots = false;
          _generateTimeOptions();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingSlots = false);
    }
  }

  void _generateTimeOptions() {
    // Parse venue slot boundaries to determine min/max time range
    TimeOfDay earliest = const TimeOfDay(hour: 6, minute: 0);
    TimeOfDay latest = const TimeOfDay(hour: 23, minute: 0);

    if (_venueSlots.isNotEmpty) {
      for (final slot in _venueSlots) {
        final range = slot['range'] as String;
        final parts = range.split(' - ');
        if (parts.length == 2) {
          final start = _parseTimeString(parts[0].trim());
          final end = _parseTimeString(parts[1].trim());
          if (start != null && _timeToMinutes(start) < _timeToMinutes(earliest)) {
            earliest = start;
          }
          if (end != null && _timeToMinutes(end) > _timeToMinutes(latest)) {
            latest = end;
          }
        }
      }
    }

    // Generate 30-min intervals between earliest and latest
    final options = <TimeOfDay>[];
    int current = _timeToMinutes(earliest);
    final end = _timeToMinutes(latest);
    while (current <= end) {
      options.add(TimeOfDay(hour: current ~/ 60, minute: current % 60));
      current += 30;
    }
    _timeOptions = options;
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      // Handle formats like "6:00AM", "10:00 PM", "06:00AM"
      final cleaned = timeStr.trim().toUpperCase().replaceAll(' ', '');
      final format = DateFormat("h:mma");
      final dt = format.parse(cleaned);
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (e) {
      return null;
    }
  }

  int _timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _loadExistingBookings() async {
    setState(() => _isLoadingBookings = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final bookings = await _bookingRepo.fetchExistingBookings(
        widget.venue.id,
        dateStr,
      );
      if (mounted) {
        setState(() {
          _existingBookings = bookings;
          _isLoadingBookings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBookings = false);
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _startTime = null;
      _endTime = null;
      _validationError = null;
    });
    _loadExistingBookings();
  }

  // --- Validation Logic ---

  /// Check if a custom time range overlaps with any existing booking
  bool _overlapsWithBooking(TimeOfDay start, TimeOfDay end) {
    final selStart = _timeToMinutes(start);
    final selEnd = _timeToMinutes(end);

    for (final booking in _existingBookings) {
      final rangeStr =
          booking['time_range'] ??
          "${booking['start_time'] ?? ''} - ${booking['end_time'] ?? ''}";
      final parts = rangeStr.toString().split(' - ');
      if (parts.length != 2) continue;

      final bStart = _parseTimeString(parts[0].trim());
      final bEnd = _parseTimeString(parts[1].trim());
      if (bStart == null || bEnd == null) continue;

      final bStartMin = _timeToMinutes(bStart);
      final bEndMin = _timeToMinutes(bEnd);

      // Overlap: selStart < bEnd AND selEnd > bStart
      if (selStart < bEndMin && selEnd > bStartMin) return true;
    }
    return false;
  }

  /// Check if the selected time range is in the past (for today)
  bool _isInPast(TimeOfDay start) {
    if (!DateUtils.isSameDay(_selectedDate, DateTime.now())) return false;
    final now = TimeOfDay.now();
    return _timeToMinutes(start) < _timeToMinutes(now);
  }

  /// Validate the full selection and set error message
  String? _validateSelection() {
    if (_startTime == null || _endTime == null) return null;

    final startMin = _timeToMinutes(_startTime!);
    final endMin = _timeToMinutes(_endTime!);

    if (endMin <= startMin) {
      return "End time must be after start time";
    }
    if (_isInPast(_startTime!)) {
      return "Cannot book a time slot in the past";
    }
    if (_overlapsWithBooking(_startTime!, _endTime!)) {
      return "Selected time overlaps with an existing booking";
    }
    return null;
  }

  /// Calculate price based on duration and venue hourly rate
  double _calculatePrice() {
    if (_startTime == null || _endTime == null) return 0;
    final durationMin = _timeToMinutes(_endTime!) - _timeToMinutes(_startTime!);
    if (durationMin <= 0) return 0;
    final hours = durationMin / 60.0;
    return hours * widget.venue.price;
  }

  bool get _canBook =>
      _startTime != null &&
      _endTime != null &&
      _validationError == null &&
      _timeToMinutes(_endTime!) > _timeToMinutes(_startTime!);

  // --- Booking Flow ---

  void _showBookingConfirmation() {
    if (!_canBook) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_validationError ?? "Please select a valid time range"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
    final timeStr =
        "${_formatTimeOfDay(_startTime!)} - ${_formatTimeOfDay(_endTime!)}";
    final price = _calculatePrice();

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
            _buildConfirmRow(Icons.sports_soccer, "Venue", widget.venue.name),
            const SizedBox(height: 12),
            _buildConfirmRow(Icons.calendar_today, "Date", dateStr),
            const SizedBox(height: 12),
            _buildConfirmRow(Icons.access_time, "Time", timeStr),
            const SizedBox(height: 12),
            _buildConfirmRow(
              Icons.currency_rupee,
              "Price",
              "₹${price.toStringAsFixed(0)}",
            ),
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
              _processBooking();
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
        Expanded(
          child: Column(
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
        ),
      ],
    );
  }

  Future<void> _processBooking() async {
    setState(() => _isBooking = true);

    try {
      final session = UserSession();
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeSlot =
          "${_formatTimeOfDay(_startTime!)} - ${_formatTimeOfDay(_endTime!)}";
      final price = _calculatePrice();

      final request = BookingRequest(
        userName: session.username ?? '',
        email: '',
        phone: '',
        bookingDate: dateStr,
        timeSlot: timeSlot,
        venue_id: widget.venue.id,
        court_id: '0',
        slot_id: '0',
        priceperslot: price.toStringAsFixed(0),
        CusUserId: session.userId ?? '',
      );

      final result = await _bookingRepo.createBooking(request);
      final bookingRef = result?['booking_ref']?.toString();
      final bookingId = result?['booking_id'] as int?;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SuccessCountdownDialog(
          onFinished: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingSummaryPage(
                  date: _selectedDate,
                  time: timeSlot,
                  venue: widget.venue.name,
                  bookingRef: bookingRef,
                  bookingId: bookingId,
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  // --- Hold Slot Flow ---

  Future<void> _holdSlot() async {
    if (!_canBook) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_validationError ?? "Please select a valid time range"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dateStr = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
    final timeStr =
        "${_formatTimeOfDay(_startTime!)} - ${_formatTimeOfDay(_endTime!)}";

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hold This Slot?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "This will block the slot from public bookings.",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildConfirmRow(Icons.calendar_today, "Date", dateStr),
            const SizedBox(height: 10),
            _buildConfirmRow(Icons.access_time, "Time", timeStr),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("CANCEL",
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("HOLD",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isHolding = true);
    try {
      final session = UserSession();
      final apiDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeSlot =
          "${_formatTimeOfDay(_startTime!)} - ${_formatTimeOfDay(_endTime!)}";

      await _bookingRepo.holdSlot(
        venueId: widget.venue.id,
        date: apiDate,
        timeSlot: timeSlot,
        userId: session.userId ?? '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Slot held successfully"),
          backgroundColor: Color(0xFF00A36C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _startTime = null;
        _endTime = null;
      });
      _loadExistingBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isHolding = false);
    }
  }

  Future<void> _releaseHold(Map<String, dynamic> booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Release Hold?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            "This slot will become available for public booking again."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("CANCEL",
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("RELEASE",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final session = UserSession();
      final apiDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeSlot = booking['time_range'] ??
          "${booking['start_time'] ?? ''} - ${booking['end_time'] ?? ''}";

      await _bookingRepo.releaseHold(
        venueId: widget.venue.id,
        date: apiDate,
        timeSlot: timeSlot,
        userId: session.userId ?? '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hold released"),
          backgroundColor: Color(0xFF00A36C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadExistingBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _convertHoldToBooking(Map<String, dynamic> booking) async {
    final timeSlot = booking['time_range'] ??
        "${booking['start_time'] ?? ''} - ${booking['end_time'] ?? ''}";

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Booking",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Convert this held slot ($timeSlot) to a confirmed booking?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("CANCEL",
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A36C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("CONFIRM BOOKING",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBooking = true);
    try {
      final session = UserSession();
      final apiDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final request = BookingRequest(
        userName: session.username ?? '',
        email: '',
        phone: '',
        bookingDate: apiDate,
        timeSlot: timeSlot,
        venue_id: widget.venue.id,
        court_id: '0',
        slot_id: '0',
        priceperslot: '0',
        CusUserId: session.userId ?? '',
      );

      await _bookingRepo.createBooking(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking confirmed from hold"),
          backgroundColor: Color(0xFF00A36C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadExistingBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  // =====================
  //  BUILD
  // =====================

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: BackButton(color: context.textColor),
        actions: [
          // QR Scan button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScannerPage()),
              );
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: "Scan Booking QR",
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
          ),
          PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  context.push('/my-add-venue', extra: venue);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, venue);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20, color: Color(0xFF00A36C)),
                      SizedBox(width: 10),
                      Text("Edit Venue"),
                    ],
                  ),
                ),
                if (UserSession().userType == UserType.admin)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 10),
                        Text("Delete Venue", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVenueImage(venue),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Venue name & address
                      Text(
                        venue.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        venue.fullAddress,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),

                      const Divider(height: 40),

                      // About
                      const Text(
                        "About Venue",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        venue.about,
                        style: const TextStyle(
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Amenities
                      const Text(
                        "Amenities",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        children: venue.amenities
                            .map(
                              (item) => Chip(
                                label: Text(item),
                                backgroundColor: Colors.grey[100],
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                      // ── Sports Available ──
                      if (venue.sports.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          "Sports Available",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: venue.sports
                              .map(
                                (sport) => Chip(
                                  avatar: Icon(
                                    _getSportIcon(sport),
                                    size: 18,
                                    color: const Color(0xFF00A36C),
                                  ),
                                  label: Text(sport),
                                  backgroundColor: Theme.of(context).cardColor,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      const Divider(height: 40),

                      // ── Date selector ──
                      const Text(
                        "Select Date",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildHorizontalCalendar(),

                      const SizedBox(height: 24),

                      // ── Existing bookings ──
                      const Text(
                        "Existing Bookings",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExistingBookings(),

                      const SizedBox(height: 24),

                      // ── Custom time range selector ──
                      const Text(
                        "Select Time Slot",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Choose a start and end time (30-min intervals)",
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      _buildTimeRangeSelector(),

                      // Validation error
                      if (_validationError != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _validationError!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Duration & price summary
                      if (_canBook) ...[
                        const SizedBox(height: 14),
                        _buildPriceSummary(),
                      ],

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom bar ──
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Price",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        _canBook
                            ? "₹${_calculatePrice().toStringAsFixed(0)}"
                            : "INR ${venue.price.toInt()}/hr",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Hold button
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 55),
                        side: BorderSide(color: Colors.amber.shade700, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: (_isHolding || _isBooking)
                          ? null
                          : _holdSlot,
                      child: _isHolding
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.amber.shade700,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              "HOLD",
                              style: TextStyle(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Book button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A36C),
                        minimumSize: const Size(0, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: (_isBooking || _isHolding)
                          ? null
                          : _showBookingConfirmation,
                      child: _isBooking
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "BOOK NOW",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================
  //  WIDGET BUILDERS
  // =====================

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return Icons.sports_cricket;
      case 'football':
        return Icons.sports_soccer;
      case 'badminton':
      case 'tennis':
      case 'table tennis':
        return Icons.sports_tennis;
      case 'basketball':
        return Icons.sports_basketball;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'hockey':
        return Icons.sports_hockey;
      case 'swimming':
        return Icons.pool;
      default:
        return Icons.sports;
    }
  }

  void _showDeleteConfirmation(BuildContext context, MyVenueEntity venue) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text("Delete Venue"),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${venue.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteVenue(venue);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVenue(MyVenueEntity venue) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/DeleteVenue');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"venue_id": venue.id}),
      );

      final data = jsonDecode(response.body);
      if (mounted) {
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Venue deleted successfully"), backgroundColor: Color(0xFF00A36C)),
          );
          context.pop(); // Go back to venue list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Delete failed"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildVenueImage(MyVenueEntity venue) {
    String path = venue.imageUrl;
    const double imageHeight = 250;
    const BoxFit imageFit = BoxFit.cover;

    if (path.isEmpty) {
      return Image.asset(
        'assets/images/no-turf-image.png',
        height: imageHeight,
        width: double.infinity,
        fit: imageFit,
      );
    } else if (path.startsWith('http')) {
      return Image.network(
        path,
        height: imageHeight,
        width: double.infinity,
        fit: imageFit,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/no-turf-image.png',
          height: imageHeight,
          fit: imageFit,
        ),
      );
    } else if (path.contains('uploads')) {
      String fullUrl = "$baseUrl/${path.replaceAll('\\', '/')}";
      return Image.network(
        fullUrl,
        height: imageHeight,
        width: double.infinity,
        fit: imageFit,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/no-turf-image.png',
          height: imageHeight,
          fit: imageFit,
        ),
      );
    } else {
      File file = File(path);
      return file.existsSync()
          ? Image.file(file,
              height: imageHeight, width: double.infinity, fit: imageFit)
          : Image.asset(
              'assets/images/no-turf-image.png',
              height: imageHeight,
              width: double.infinity,
              fit: imageFit,
            );
    }
  }

  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: () => _onDateSelected(date),
            child: Container(
              width: 65,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00A36C)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
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
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
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

  Widget _buildExistingBookings() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _isLoadingBookings
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _existingBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available,
                          size: 36, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        "No bookings for ${DateFormat('dd MMM').format(_selectedDate)}",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _existingBookings.length,
                  itemBuilder: (context, index) {
                    final b = _existingBookings[index];
                    final timeDisplay = b['time_range'] ??
                        "${b['start_time'] ?? ''} - ${b['end_time'] ?? ''}";
                    final userDisplay =
                        b['user'] ?? b['user_name'] ?? "Reserved";
                    final status = (b['status'] ?? '').toString().toLowerCase();
                    final isHeld = status == 'hold' || status == 'on_hold';

                    // Colors based on status
                    final Color barColor = isHeld
                        ? Colors.amber.shade600
                        : Colors.orangeAccent;
                    final String badgeText = isHeld ? "ON HOLD" : "OCCUPIED";
                    final Color badgeBg = isHeld
                        ? Colors.amber.shade50
                        : Colors.orange.shade50;
                    final Color badgeColor = isHeld
                        ? Colors.amber.shade700
                        : Colors.orange;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isHeld
                            ? Colors.amber.shade50.withAlpha(80)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isHeld
                              ? Colors.amber.shade200
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 36,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeDisplay,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      isHeld
                                          ? Icons.lock_outline
                                          : Icons.person_outline,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isHeld ? "Owner Hold" : userDisplay,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          // Actions for held slots (owner only)
                          if (isHeld) ...[
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.more_vert,
                                    size: 18, color: Colors.grey[500]),
                                onSelected: (val) {
                                  if (val == 'release') {
                                    _releaseHold(b);
                                  } else if (val == 'convert') {
                                    _convertHoldToBooking(b);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'convert',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline,
                                            size: 18, color: Color(0xFF00A36C)),
                                        SizedBox(width: 8),
                                        Text("Confirm Booking"),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'release',
                                    child: Row(
                                      children: [
                                        Icon(Icons.lock_open,
                                            size: 18, color: Colors.redAccent),
                                        SizedBox(width: 8),
                                        Text("Release Hold"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  // ── Helpers for time status ──

  bool _isTimeBooked(TimeOfDay t) {
    final tMin = _timeToMinutes(t);
    for (final booking in _existingBookings) {
      final rangeStr = booking['time_range'] ??
          "${booking['start_time'] ?? ''} - ${booking['end_time'] ?? ''}";
      final parts = rangeStr.toString().split(' - ');
      if (parts.length != 2) continue;
      final bStart = _parseTimeString(parts[0].trim());
      final bEnd = _parseTimeString(parts[1].trim());
      if (bStart == null || bEnd == null) continue;
      if (tMin >= _timeToMinutes(bStart) && tMin < _timeToMinutes(bEnd)) {
        return true;
      }
    }
    return false;
  }

  bool _isTimeHeld(TimeOfDay t) {
    final tMin = _timeToMinutes(t);
    for (final booking in _existingBookings) {
      final status = (booking['status'] ?? '').toString().toLowerCase();
      if (status != 'hold' && status != 'on_hold') continue;
      final rangeStr = booking['time_range'] ??
          "${booking['start_time'] ?? ''} - ${booking['end_time'] ?? ''}";
      final parts = rangeStr.toString().split(' - ');
      if (parts.length != 2) continue;
      final bStart = _parseTimeString(parts[0].trim());
      final bEnd = _parseTimeString(parts[1].trim());
      if (bStart == null || bEnd == null) continue;
      if (tMin >= _timeToMinutes(bStart) && tMin < _timeToMinutes(bEnd)) {
        return true;
      }
    }
    return false;
  }

  bool _isTimePast(TimeOfDay t) {
    if (!DateUtils.isSameDay(_selectedDate, DateTime.now())) return false;
    return _timeToMinutes(t) <= _timeToMinutes(TimeOfDay.now());
  }

  // ── Visual timeline + card selector ──

  Widget _buildTimeRangeSelector() {
    if (_isFetchingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF00A36C)),
        ),
      );
    }

    if (_timeOptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text("No slots available for this venue",
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Visual timeline bar ──
        _buildVisualTimeline(),

        const SizedBox(height: 20),

        // ── Selected time display cards ──
        Row(
          children: [
            Expanded(
              child: _buildTimeCard(
                label: "FROM",
                time: _startTime,
                icon: Icons.login_rounded,
                color: const Color(0xFF00A36C),
                onTap: () => _showTimePickerSheet(isStart: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Icon(Icons.arrow_forward_rounded,
                      color: _canBook
                          ? const Color(0xFF00A36C)
                          : Colors.grey[300],
                      size: 22),
                  if (_canBook)
                    Text(
                      _getDurationStr(),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _buildTimeCard(
                label: "TO",
                time: _endTime,
                icon: Icons.logout_rounded,
                color: const Color(0xFF1B8A5A),
                onTap: _startTime != null
                    ? () => _showTimePickerSheet(isStart: false)
                    : null,
              ),
            ),
          ],
        ),

        // ── Legend ──
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendDot(Colors.grey.shade300, "Past"),
            const SizedBox(width: 12),
            _buildLegendDot(Colors.red.shade300, "Booked"),
            const SizedBox(width: 12),
            _buildLegendDot(Colors.amber.shade400, "On Hold"),
            const SizedBox(width: 12),
            _buildLegendDot(const Color(0xFF00A36C), "Available"),
            if (_canBook) ...[
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFF00A36C).withAlpha(120),
                  "Selected"),
            ],
          ],
        ),
      ],
    );
  }

  String _getDurationStr() {
    if (_startTime == null || _endTime == null) return "";
    final durationMin =
        _timeToMinutes(_endTime!) - _timeToMinutes(_startTime!);
    if (durationMin <= 0) return "";
    final hours = durationMin ~/ 60;
    final mins = durationMin % 60;
    return hours > 0
        ? (mins > 0 ? "${hours}h ${mins}m" : "${hours}h")
        : "${mins}m";
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  // ── Scrollable visual timeline showing slot status ──

  Widget _buildVisualTimeline() {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeOptions.length,
        itemBuilder: (context, index) {
          final t = _timeOptions[index];
          final tMin = _timeToMinutes(t);
          final booked = _isTimeBooked(t);
          final held = _isTimeHeld(t);
          final past = _isTimePast(t);

          // Selection range highlighting
          final bool isStart = _startTime != null &&
              _timeToMinutes(_startTime!) == tMin;
          final bool isEnd = _endTime != null &&
              _timeToMinutes(_endTime!) == tMin;
          final bool inRange = _startTime != null &&
              _endTime != null &&
              tMin > _timeToMinutes(_startTime!) &&
              tMin < _timeToMinutes(_endTime!);

          // Bar color
          Color barColor;
          if (isStart || isEnd) {
            barColor = const Color(0xFF00A36C);
          } else if (inRange) {
            barColor = const Color(0xFF00A36C).withAlpha(100);
          } else if (held) {
            barColor = Colors.amber.shade400;
          } else if (booked) {
            barColor = Colors.red.shade300;
          } else if (past) {
            barColor = Colors.grey.shade300;
          } else {
            barColor = const Color(0xFF00A36C).withAlpha(40);
          }

          final bool isLast = index == _timeOptions.length - 1;

          return Column(
            children: [
              // Time label (show every other for readability)
              SizedBox(
                height: 16,
                child: (index % 2 == 0)
                    ? Text(
                        _formatTimeOfDay(t),
                        style: TextStyle(
                          fontSize: 9,
                          color: (isStart || isEnd)
                              ? const Color(0xFF00A36C)
                              : Colors.grey[500],
                          fontWeight: (isStart || isEnd)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 4),
              // Bar segment
              GestureDetector(
                onTap: (booked || past)
                    ? null
                    : () {
                        setState(() {
                          if (_startTime == null ||
                              (_startTime != null && _endTime != null)) {
                            _startTime = t;
                            _endTime = null;
                            _validationError = null;
                          } else {
                            if (tMin <= _timeToMinutes(_startTime!)) {
                              _startTime = t;
                              _endTime = null;
                              _validationError = null;
                            } else {
                              _endTime = t;
                              _validationError = _validateSelection();
                            }
                          }
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 28,
                  margin: EdgeInsets.only(right: isLast ? 0 : 2),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.horizontal(
                      left: (isStart || index == 0)
                          ? const Radius.circular(6)
                          : Radius.zero,
                      right: (isEnd || isLast)
                          ? const Radius.circular(6)
                          : Radius.zero,
                    ),
                  ),
                  child: (isStart || isEnd)
                      ? Center(
                          child: Icon(
                            isStart
                                ? Icons.chevron_right
                                : Icons.chevron_left,
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              // Tick mark
              Container(
                width: 1,
                height: (index % 2 == 0) ? 6 : 3,
                color: Colors.grey.shade300,
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Tappable time card (FROM / TO) ──

  Widget _buildTimeCard({
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final bool hasValue = time != null;
    final bool isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: hasValue ? color.withAlpha(15) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue ? color.withAlpha(80) : Colors.grey.shade200,
            width: hasValue ? 1.5 : 1,
          ),
          boxShadow: hasValue
              ? [
                  BoxShadow(
                    color: color.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14,
                    color: hasValue ? color : Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: hasValue ? color : Colors.grey[400],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasValue
                  ? _formatTimeOfDay(time)
                  : (isDisabled ? "- - -" : "Select"),
              style: TextStyle(
                fontSize: hasValue ? 20 : 16,
                fontWeight: hasValue ? FontWeight.bold : FontWeight.w400,
                color: hasValue
                    ? Colors.black87
                    : (isDisabled ? Colors.grey[300] : Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Native clock time picker ──

  Future<void> _showTimePickerSheet({required bool isStart}) async {
    final initialTime = isStart
        ? (_startTime ?? TimeOfDay.now())
        : (_endTime ?? _startTime ?? TimeOfDay.now());

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isStart ? "SELECT START TIME" : "SELECT END TIME",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A36C),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    // Snap to nearest 30-min interval
    final snappedMinute = (picked.minute / 30).round() * 30;
    final snapped = TimeOfDay(
      hour: snappedMinute == 60 ? picked.hour + 1 : picked.hour,
      minute: snappedMinute == 60 ? 0 : snappedMinute,
    );

    // Validate the picked time
    if (_isTimePast(snapped)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot select a time in the past"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_isTimeBooked(snapped)) {
      if (mounted) {
        final heldMsg = _isTimeHeld(snapped)
            ? "This time slot is on hold"
            : "This time slot is already booked";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(heldMsg),
            backgroundColor: _isTimeHeld(snapped)
                ? Colors.amber.shade700
                : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      if (isStart) {
        _startTime = snapped;
        if (_endTime != null &&
            _timeToMinutes(_endTime!) <= _timeToMinutes(snapped)) {
          _endTime = null;
        }
        _validationError = null;
      } else {
        if (_startTime != null &&
            _timeToMinutes(snapped) <= _timeToMinutes(_startTime!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("End time must be after start time"),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _endTime = snapped;
        _validationError = _validateSelection();
      }
    });
  }

  Widget _buildPriceSummary() {
    final durationMin =
        _timeToMinutes(_endTime!) - _timeToMinutes(_startTime!);
    final hours = durationMin ~/ 60;
    final mins = durationMin % 60;
    final durationStr = hours > 0
        ? (mins > 0 ? "${hours}h ${mins}m" : "${hours}h")
        : "${mins}m";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00A36C).withAlpha(20),
            const Color(0xFF00A36C).withAlpha(8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00A36C).withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00A36C).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF00A36C), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_formatTimeOfDay(_startTime!)} - ${_formatTimeOfDay(_endTime!)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Duration: $durationStr",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${_calculatePrice().toStringAsFixed(0)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Color(0xFF00A36C),
                ),
              ),
              Text(
                "total",
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
