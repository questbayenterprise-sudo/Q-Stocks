import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../domain/entities/venue.dart';
import '../../../booking/data/repositories/booking_repository_impl.dart';
import '../../../booking/domain/entities/booking_request.dart';
import '../../../booking/presentation/pages/booking_summary_page.dart';
import '../../../booking/presentation/widgets/SuccessCountdownDialog.dart';
import '../../../auth/Session/user_session.dart';
import '../../../auth/widgets/guest_registration_sheet.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../../likes/data/likes_repository.dart';

class VenueDetailPage extends StatefulWidget {
  final VenueEntity venue;
  const VenueDetailPage({super.key, required this.venue});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  final String baseUrl = AppConfig.baseUrl;
  final BookingRepositoryImpl _bookingRepo = BookingRepositoryImpl();
  final LikesRepository _likesRepo = LikesRepository();

  // Like state
  bool _isLiked = false;
  int _likeCount = 0;

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

  // Game selection
  int? _selectedSportId;
  String? _selectedSportName;

  // Generate 30-min interval time options from venue slots
  List<TimeOfDay> _timeOptions = [];

  @override
  void initState() {
    super.initState();
    _loadSlots();
    _loadExistingBookings();
    _loadLikeStatus();
    // Auto-select if only one sport
    if (widget.venue.sportsData.length == 1) {
      _selectedSportId = widget.venue.sportsData[0]['id'] as int;
      _selectedSportName = widget.venue.sportsData[0]['name'] as String;
    }
  }

  Future<void> _loadLikeStatus() async {
    final userId = int.tryParse(UserSession().userId ?? '0') ?? 0;
    if (userId == 0) return;
    final venueId = int.tryParse(widget.venue.id) ?? 0;

    final liked = await _likesRepo.checkLike(userId, venueId);
    final count = await _likesRepo.getLikeCount(venueId);
    if (mounted) {
      setState(() {
        _isLiked = liked;
        _likeCount = count;
      });
    }
  }

  Future<void> _toggleLike() async {
    final userId = int.tryParse(UserSession().userId ?? '0') ?? 0;
    if (userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sign in to like venues"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final venueId = int.tryParse(widget.venue.id) ?? 0;
    final liked = await _likesRepo.toggleLike(userId, venueId);
    if (mounted) {
      setState(() {
        _isLiked = liked;
        _likeCount += liked ? 1 : -1;
      });
    }
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

    // Validate sport selection
    if (widget.venue.sportsData.isNotEmpty && _selectedSportId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a game"),
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
            if (_selectedSportName != null) ...[
              _buildConfirmRow(
                _getSportIcon(_selectedSportName!), "Sport", _selectedSportName!),
              const SizedBox(height: 12),
            ],
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
        sports_id: _selectedSportId?.toString() ?? '0',
      );

      final result = await _bookingRepo.initiateBooking(request);

      if (!mounted) return;

      if (result == null || result['success'] != true) {
        _showBookingError(result?['message'] ?? 'Booking failed');
        return;
      }

      final isPayment = result['is_payment_enabled'] == true;
      final bookingId = result['booking_id'] as int;
      final bookingRef = result['booking_ref']?.toString();

      if (isPayment) {
        // --- Payment flow: redirect to payment, then callback ---
        final paymentUrl = result['payment_url'] ?? '';
        // TODO: Open payment gateway URL
        // On payment success, call:
        // await _bookingRepo.paymentCallback(
        //   bookingId: bookingId,
        //   transactionId: "TXN_...",
        //   status: "Success",
        // );
        _showPaymentPendingDialog(bookingId, paymentUrl);
      } else {
        // --- Direct confirmation: show success ---
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
      }
    } catch (e) {
      if (!mounted) return;
      _showBookingError(e.toString());
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showBookingError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text("Booking Failed"),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPaymentPendingDialog(int bookingId, String paymentUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Color(0xFF00A36C)),
            SizedBox(width: 10),
            Text("Proceed to Payment"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Booking #$bookingId created. Complete payment to confirm."),
            const SizedBox(height: 12),
            Text(
              "Amount: INR ${_calculatePrice().toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00A36C)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("PAY LATER", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Open payment gateway URL
              // After payment success, call _bookingRepo.paymentCallback(...)
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A36C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("PAY NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =====================
  //  SHARE
  // =====================

  void _showShareSheet(BuildContext context) {
    final v = widget.venue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve image URL
    String? imageUrl;
    if (v.imageUrl.isNotEmpty) {
      if (v.imageUrl.startsWith('http')) {
        imageUrl = v.imageUrl;
      } else if (v.imageUrl.contains('uploads')) {
        imageUrl = "$baseUrl/${v.imageUrl.replaceAll('\\', '/')}";
      }
    }

    final shareText = '''Check out "${v.name}" on Q-Sports!

Location: ${v.fullAddress.isNotEmpty ? v.fullAddress : v.locationName}
Price: INR ${v.price.toInt()}/hr
${v.amenities.isNotEmpty ? 'Amenities: ${v.amenities.join(', ')}' : ''}
Book now on Q-Sports!''';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              "Share Venue",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Preview card
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.sports_soccer, size: 48, color: Color(0xFF00A36C)),
                              ),
                            ),
                          )
                        : Container(
                            height: 160,
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.sports_soccer, size: 48, color: Color(0xFF00A36C)),
                            ),
                          ),
                  ),

                  // Venue info
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                v.fullAddress.isNotEmpty ? v.fullAddress : v.locationName,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A36C).withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "INR ${v.price.toInt()}/hr",
                                style: const TextStyle(
                                  color: Color(0xFF00A36C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (v.amenities.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  v.amenities.join(' · '),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Share button — defaults to sharing with image
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _shareWithImage(v, shareText, imageUrl);
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text("Share", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Future<void> _shareWithImage(VenueEntity venue, String text, String? imageUrl) async {
    if (imageUrl == null) {
      Share.share(text);
      return;
    }

    try {
      // Download the image to a temp file
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/qsports_venue_${venue.id}.jpg');
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: text,
        );
      } else {
        Share.share(text);
      }
    } catch (e) {
      // Fallback to text-only share
      Share.share(text);
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
          IconButton(
            onPressed: () => _showShareSheet(context),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: _toggleLike,
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : null,
            ),
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
                        style: TextStyle(
                          height: 1.5,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
                                backgroundColor: Theme.of(context).cardColor,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                      // ── Select Sport / Game ──
                      if (venue.sportsData.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          venue.sportsData.length == 1 ? "Sport" : "Select Sport *",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: venue.sportsData.map((sport) {
                            final sportId = sport['id'] as int;
                            final sportName = sport['name'] as String;
                            final isSelected = _selectedSportId == sportId;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSportId = sportId;
                                  _selectedSportName = sportName;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF00A36C)
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00A36C)
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getSportIcon(sportName),
                                      size: 18,
                                      color: isSelected ? Colors.white : const Color(0xFF00A36C),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      sportName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : null,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.check_circle, size: 16, color: Colors.white),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else if (venue.sports.isEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange, size: 20),
                              SizedBox(width: 10),
                              Text("No games available for this venue",
                                  style: TextStyle(color: Colors.orange, fontSize: 13)),
                            ],
                          ),
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
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A36C),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isBooking
                          ? null
                          : () {
                              if (UserSession().userType == UserType.guest) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      GuestRegistrationSheet(
                                    onRegistrationSuccess: () {},
                                  ),
                                );
                              } else {
                                _showBookingConfirmation();
                              }
                            },
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

  Widget _buildVenueImage(VenueEntity venue) {
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
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: isSelected ? null : Border.all(
                  color: Theme.of(context).dividerColor,
                ),
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

  Widget _buildExistingBookings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
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

                    final Color barColor = isHeld
                        ? Colors.amber.shade600
                        : Colors.orangeAccent;
                    final String badgeText = isHeld ? "UNAVAILABLE" : "OCCUPIED";
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
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
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
                                      isHeld ? "Reserved by venue" : userDisplay,
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
      final isDarkSlots = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkSlots ? Colors.grey.shade900 : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDarkSlots ? Colors.grey.shade800 : Colors.grey.shade200),
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
            _buildLegendDot(Colors.amber.shade400, "Unavailable"),
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

    final isDarkCard = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: hasValue ? color.withAlpha(15) : (isDarkCard ? Colors.grey.shade900 : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue ? color.withAlpha(80) : (isDarkCard ? Colors.grey.shade700 : Colors.grey.shade200),
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
                    ? (isDarkCard ? Colors.white : Colors.black87)
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
        final isDarkPicker = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDarkPicker
                ? const ColorScheme.dark(
                    primary: Color(0xFF00A36C),
                    onPrimary: Colors.white,
                    surface: Color(0xFF2C2C2C),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF00A36C),
                    onPrimary: Colors.white,
                    onSurface: Colors.black87,
                  ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDarkPicker ? const Color(0xFF2C2C2C) : Colors.white,
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
        final isHeld = _isTimeHeld(snapped);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isHeld
                ? "This time slot is reserved by the venue"
                : "This time slot is already booked"),
            backgroundColor:
                isHeld ? Colors.amber.shade700 : Colors.redAccent,
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
