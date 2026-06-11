import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/Session/user_session.dart';
import '../../My_Bookings/Models/Booking_History.dart';
import '../../My_Bookings/Repository/Booking_repository.dart';
import '../../My_Bookings/Repository/IBooking_repository.dart';
import 'booking_detail_page.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  bool _isGridView = false;
  bool _isLoading = true;
  List<Booking> _bookings = [];
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final IBookingRepository repository = BookingRepositoryImpl();
  String? currentId = UserSession().userId;

  // ── Filter state ──
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedVenue;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _maxPrice = 10000;

  // ── Pagination ──
  int _currentPage = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _fetchBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// All bookings filtered by current filter state
  List<Booking> get _filteredBookings {
    var results = _bookings.where((b) {
      // Search query — match venue name, booking ref, or user name
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!b.venueName.toLowerCase().contains(q) &&
            !b.bookingRef.toLowerCase().contains(q) &&
            !b.userName.toLowerCase().contains(q)) {
          return false;
        }
      }

      // Status filter
      if (_selectedStatus != null) {
        if (b.status.toLowerCase() != _selectedStatus!.toLowerCase()) {
          return false;
        }
      }

      // Venue filter
      if (_selectedVenue != null) {
        if (b.venueName != _selectedVenue) return false;
      }

      // Date range filter
      if (_dateFrom != null || _dateTo != null) {
        try {
          final bookingDate = DateTime.parse(b.startTime);
          if (_dateFrom != null && bookingDate.isBefore(_dateFrom!)) {
            return false;
          }
          if (_dateTo != null &&
              bookingDate.isAfter(_dateTo!.add(const Duration(days: 1)))) {
            return false;
          }
        } catch (_) {
          // Can't parse date — include it
        }
      }

      // Price range filter
      if (b.price < _priceRange.start || b.price > _priceRange.end) {
        return false;
      }

      return true;
    }).toList();

    return results;
  }

  /// Paginated slice of filtered bookings
  List<Booking> get _paginatedBookings {
    final filtered = _filteredBookings;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages => (_filteredBookings.length / _pageSize).ceil().clamp(1, 9999);

  /// Unique statuses from loaded bookings
  List<String> get _availableStatuses =>
      _bookings.map((b) => b.status).toSet().toList()..sort();

  /// Unique venue names from loaded bookings
  List<String> get _availableVenues =>
      _bookings.map((b) => b.venueName).toSet().toList()..sort();

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedStatus = null;
      _selectedVenue = null;
      _dateFrom = null;
      _dateTo = null;
      _priceRange = RangeValues(0, _maxPrice);
      _currentPage = 1;
    });
  }

  bool get _isAdminOrOwner =>
      UserSession().userType == UserType.admin ||
      UserSession().userType == UserType.owner ||
      UserSession().userType == UserType.vendor ||
      UserSession().userType == UserType.manager;

  String get _userTypeString {
    switch (UserSession().userType) {
      case UserType.admin:
        return 'admin';
      case UserType.owner:
        return 'owner';
      case UserType.vendor:
        return 'vendor';
      case UserType.manager:
        return 'manager';
      default:
        return 'user';
    }
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);

    try {
      final List<dynamic>? data = await repository.fetchBookingHistory(
        currentId,
        userType: _userTypeString,
      );

      if (data != null) {
        setState(() {
          _bookings = data.map((json) => Booking.fromJson(json)).toList();
          // Calculate max price for slider
          if (_bookings.isNotEmpty) {
            _maxPrice = _bookings
                .map((b) => b.price)
                .reduce((a, b) => a > b ? a : b);
            if (_maxPrice < 100) _maxPrice = 100;
            _priceRange = RangeValues(0, _maxPrice);
          }
        });
      } else {
        // Handle empty or error state
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load bookings")),
          );
        }
      }
    } catch (e) {
      debugPrint("UI Error fetching bookings: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper to format Date/Time (handles both "2026-03-21T06:00:00" and "06:00:00")
  String formatBookingDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  String formatBookingTime(String startStr, String endStr) {
    try {
      // Try full datetime format first
      DateTime start = DateTime.parse(startStr);
      DateTime end = DateTime.parse(endStr);
      return "${DateFormat('hh:mm a').format(start)} - ${DateFormat('hh:mm a').format(end)}";
    } catch (e) {
      // Fallback: already a time string like "06:00:00" or "6:00 AM"
      String formatTime(String t) {
        try {
          final parts = t.trim().split(':');
          if (parts.length >= 2) {
            int hour = int.parse(parts[0]);
            int minute = int.parse(parts[1]);
            final period = hour >= 12 ? 'PM' : 'AM';
            if (hour > 12) hour -= 12;
            if (hour == 0) hour = 12;
            return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
          }
        } catch (_) {}
        return t;
      }
      return "${formatTime(startStr)} - ${formatTime(endStr)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guest user — show create account prompt
    if (UserSession().userType == UserType.guest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Bookings"),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A36C).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 64,
                    color: Color(0xFF00A36C),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Create an Account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Sign up to book venues, track your bookings, and get personalized recommendations.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A36C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => context.go('/signup'),
                    child: const Text(
                      "CREATE ACCOUNT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => context.go('/auth'),
                  child: RichText(
                    text: const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Sign In",
                          style: TextStyle(
                            color: Color(0xFF00A36C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Determine if we are on a mobile-sized screen
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildFilterDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                // Adaptive padding based on screen size
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 40,
                  vertical: isMobile ? 20 : 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(isMobile),
                    const SizedBox(height: 24),
                    _buildActionBar(isMobile),
                    const SizedBox(height: 24),
                    _buildContentArea(isMobile),
                    const SizedBox(height: 40),
                    _buildPagination(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. ADAPTIVE HEADER ---
  Widget _buildTopHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAdminOrOwner ? "All Bookings" : "My Bookings",
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(height: 4),
                Text(
                  _isAdminOrOwner
                      ? "Monitor and manage all venue bookings"
                      : "Monitor and manage all your court reservations",
                  style: const TextStyle(
                      color: Color(0xFF6B7280), fontSize: 16),
                ),
              ],
            ],
          ),
        ),
        // Toggle (Hidden on very small screens to save space if needed)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildViewIcon(
                Icons.view_headline_rounded,
                !_isGridView,
                () => setState(() => _isGridView = false),
              ),
              _buildViewIcon(
                Icons.grid_view_rounded,
                _isGridView,
                () => setState(() => _isGridView = true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. ADAPTIVE ACTION BAR ---
  Widget _buildActionBar(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search bookings...",
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // On mobile, show only icon to prevent overflow
        IconButton.filled(
          onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
          icon: const Icon(Icons.filter_list_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF111827),
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. CONTENT AREA (Switch between Table and Mobile Cards) ---
  Widget _buildContentArea(bool isMobile) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A36C)),
      );
    }
    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              "No bookings found",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredBookings;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              "No bookings match your filters",
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Clear Filters"),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00A36C),
              ),
            ),
          ],
        ),
      );
    }

    // Active filter count indicator
    final activeFilters = [
      if (_selectedStatus != null) 'status',
      if (_selectedVenue != null) 'venue',
      if (_dateFrom != null || _dateTo != null) 'date',
      if (_priceRange.start > 0 || _priceRange.end < _maxPrice) 'price',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active filter chips
        if (activeFilters.isNotEmpty || _searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (_searchQuery.isNotEmpty)
                  _filterChip('Search: "$_searchQuery"', () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  }),
                if (_selectedStatus != null)
                  _filterChip('Status: $_selectedStatus', () {
                    setState(() => _selectedStatus = null);
                  }),
                if (_selectedVenue != null)
                  _filterChip('Venue: $_selectedVenue', () {
                    setState(() => _selectedVenue = null);
                  }),
                if (_dateFrom != null || _dateTo != null)
                  _filterChip('Date filtered', () {
                    setState(() {
                      _dateFrom = null;
                      _dateTo = null;
                    });
                  }),
                if (_priceRange.start > 0 || _priceRange.end < _maxPrice)
                  _filterChip(
                    '₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()}',
                    () => setState(
                        () => _priceRange = RangeValues(0, _maxPrice)),
                  ),
              ],
            ),
          ),

        // Results count
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            "${filtered.length} booking${filtered.length == 1 ? '' : 's'} found",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),

        if (_isGridView)
          _buildGridView(isMobile)
        else
          isMobile ? _buildMobileList() : _buildWebTable(),
      ],
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF00A36C).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00A36C).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF00A36C),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF00A36C)),
          ),
        ],
      ),
    );
  }

  // DESKTOP/WEB VERSION (Tabular)
  Widget _buildWebTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _headerCol("SERVICE & ID", flex: 3),
                _headerCol("DATE & TIME", flex: 2),
                _headerCol("STATUS", flex: 1),
                _headerCol("PRICE", flex: 1),
                _headerCol("ACTIONS", flex: 2, align: TextAlign.right),
              ],
            ),
          ),
          const Divider(height: 1),
          ...List.generate(5, (index) => _buildBookingWebRow()),
        ],
      ),
    );
  }

  // MOBILE VERSION (Stacked Card)
  Widget _buildMobileList() {
    return Column(
      children: _paginatedBookings
          .map((booking) => _buildBookingMobileCard(booking))
          .toList(),
    );
  }

  // --- MOBILE CARD DESIGN ---
  Widget _buildBookingMobileCard(Booking booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailPage(bookingId: booking.id),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _resolveImageUrl(booking.venueImage).isNotEmpty
                    ? Image.network(
                        _resolveImageUrl(booking.venueImage),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: Icon(Icons.sports_soccer,
                              size: 24, color: Colors.grey[400]),
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: Icon(Icons.sports_soccer,
                            size: 24, color: Colors.grey[400]),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.venueName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      booking.bookingRef,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    if (_isAdminOrOwner && booking.userName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 13, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            booking.userName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _statusBadge(booking.status),
            ],
          ),
          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatBookingDate(booking.startTime),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    formatBookingTime(booking.startTime, booking.endTime),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              Text(
                "₹${booking.price}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF00A36C),
                ),
              ),
            ],
          ),
          // Cancel button hidden
        ],
      ),
    ),
    );
  }

  // --- HELPERS ---

  Widget _buildBookingWebRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _serviceCell()),
          Expanded(flex: 2, child: _dateCell()),
          Expanded(flex: 1, child: _statusBadge("Upcoming")),
          const Expanded(
            flex: 1,
            child: Text(
              "₹1,200",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 2, child: _actionCell()),
        ],
      ),
    );
  }

  Widget _serviceCell() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            "https://picsum.photos/100",
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          // CRITICAL: Allows text to shrink
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Premier Soccer League",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "#BK-882910",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateCell() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Oct 24, 2023",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          "06:00 - 07:00 PM",
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _actionCell() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _quickAction(Icons.edit_calendar_rounded, Colors.blue),
      ],
    );
  }

  // --- EXISTING LOGIC CARRIED OVER & FIXED ---

  Widget _headerCol(
    String label, {
    required int flex,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return UnconstrainedBox(
      // Prevents badge from stretching horizontally
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  // (Filter Drawer, Pagination, View Icons remain same as your logic but contained within mobile bounds)
  // ...
  Widget _buildViewIcon(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? const Color(0xFF00A36C) : Colors.grey,
        ),
      ),
    );
  }

  // Section label for the filter drawer
  Widget _filterLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF374151), // Dark grey
          fontSize: 14,
        ),
      ),
    );
  }


  Widget _buildFilterDrawer() {
    return StatefulBuilder(
      builder: (context, setDrawerState) {
        return Drawer(
          width: 350,
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Advanced Filters",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Status ──
                          _filterLabel("Status"),
                          _buildDropdown(
                            value: _selectedStatus,
                            hint: "All Statuses",
                            items: _availableStatuses,
                            onChanged: (val) {
                              setDrawerState(() {});
                              setState(() {
                                _selectedStatus = val;
                                _currentPage = 1;
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // ── Venue ──
                          _filterLabel("Venue"),
                          _buildDropdown(
                            value: _selectedVenue,
                            hint: "All Venues",
                            items: _availableVenues,
                            onChanged: (val) {
                              setDrawerState(() {});
                              setState(() {
                                _selectedVenue = val;
                                _currentPage = 1;
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // ── Date Range ──
                          _filterLabel("Date Range"),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateButton(
                                  label: _dateFrom != null
                                      ? DateFormat('dd MMM yyyy')
                                          .format(_dateFrom!)
                                      : "From",
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _dateFrom ?? DateTime.now(),
                                      firstDate: DateTime(2024),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setDrawerState(() {});
                                      setState(() {
                                        _dateFrom = picked;
                                        _currentPage = 1;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 8),
                                child: Text("–",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                              Expanded(
                                child: _buildDateButton(
                                  label: _dateTo != null
                                      ? DateFormat('dd MMM yyyy')
                                          .format(_dateTo!)
                                      : "To",
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _dateTo ?? DateTime.now(),
                                      firstDate: DateTime(2024),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setDrawerState(() {});
                                      setState(() {
                                        _dateTo = picked;
                                        _currentPage = 1;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── Price Range ──
                          _filterLabel("Price Range"),
                          Text(
                            "₹${_priceRange.start.toInt()} — ₹${_priceRange.end.toInt()}",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: _maxPrice,
                            divisions: (_maxPrice / 100).ceil().clamp(1, 100),
                            activeColor: const Color(0xFF00A36C),
                            labels: RangeLabels(
                              "₹${_priceRange.start.toInt()}",
                              "₹${_priceRange.end.toInt()}",
                            ),
                            onChanged: (val) {
                              setDrawerState(() {});
                              setState(() {
                                _priceRange = val;
                                _currentPage = 1;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _resetFilters();
                            setDrawerState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Reset All"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A36C),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Apply",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(hint,
                  style: TextStyle(color: Colors.grey[500])),
            ),
            ...items.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final isSet = label != "From" && label != "To";
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSet
                ? const Color(0xFF00A36C).withValues(alpha: 0.5)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSet ? const Color(0xFF111827) : Colors.grey,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.calendar_today,
                size: 14,
                color: isSet ? const Color(0xFF00A36C) : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_filteredBookings.length <= _pageSize) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 1
              ? () => setState(() => _currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left),
          color: const Color(0xFF00A36C),
          disabledColor: Colors.grey[300],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF00A36C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "Page $_currentPage of $_totalPages",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF00A36C),
              fontSize: 13,
            ),
          ),
        ),
        IconButton(
          onPressed: _currentPage < _totalPages
              ? () => setState(() => _currentPage++)
              : null,
          icon: const Icon(Icons.chevron_right),
          color: const Color(0xFF00A36C),
          disabledColor: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildGridView(bool isMobile) {
    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              "No bookings found",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    final paginated = _paginatedBookings;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paginated.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isMobile ? 0.68 : 0.85,
      ),
      itemBuilder: (context, index) =>
          _buildBookingGridCard(paginated[index], index),
    );
  }

  // Light gradient pairs per card index for visual variety
  List<List<Color>> get _cardGradients => [
    [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)],
    [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
    [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
    [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
    [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
    [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
  ];

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF00E676);
      case 'pending':
        return const Color(0xFFFFAB40);
      case 'cancelled':
        return const Color(0xFFFF5252);
      case 'completed':
        return const Color(0xFF448AFF);
      case 'hold':
      case 'on_hold':
        return const Color(0xFFFFD740);
      default:
        return const Color(0xFF448AFF);
    }
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.contains('uploads')) {
      return "${AppConfig.baseUrl}/${path.replaceAll('\\', '/')}";
    }
    return path;
  }

  Widget _buildBookingGridCard(Booking booking, int index) {
    final gradient = _cardGradients[index % _cardGradients.length];
    final sColor = _statusColor(booking.status);
    final imageUrl = _resolveImageUrl(booking.venueImage);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailPage(bookingId: booking.id),
          ),
        );
      },
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: gradient[1].withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Venue Image with gradient overlay ──
          SizedBox(
            height: 90,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.sports_soccer,
                                size: 32, color: Colors.white70),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.sports_soccer,
                              size: 32, color: Colors.white70),
                        ),
                      ),

                // Bottom gradient fade
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),

                // Status pill on image
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Price badge on image
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A36C), Color(0xFF00C853)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A36C)
                              .withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "₹${booking.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),

                // Venue name on image bottom
                Positioned(
                  bottom: 6,
                  left: 8,
                  right: 8,
                  child: Text(
                    booking.venueName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom details with gradient background ──
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradient[0].withValues(alpha: 0.3),
                    gradient[1].withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking ref
                  Text(
                    booking.bookingRef,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          formatBookingDate(booking.startTime),
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Time
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          formatBookingTime(
                              booking.startTime, booking.endTime),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
