import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/Session/user_session.dart';
import '../../../profile/My_Bookings/Models/Booking_History.dart';
import '../../../profile/My_Bookings/Repository/Booking_repository.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final BookingRepositoryImpl _bookingRepo = BookingRepositoryImpl();
  List<Booking> _recentBookings = [];
  bool _isLoadingBookings = true;

  @override
  void initState() {
    super.initState();
    _fetchRecentBookings();
  }

  Future<void> _fetchRecentBookings() async {
    try {
      final userType = UserSession().userType?.name ?? 'user';
      final data = await _bookingRepo.fetchBookingHistory(
        UserSession().userId,
        userType: userType,
      );
      if (data != null && mounted) {
        setState(() {
          // Take only the latest 3 bookings
          final all = data.map((json) => Booking.fromJson(json)).toList();
          _recentBookings = all.take(3).toList();
          _isLoadingBookings = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingBookings = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBookings = false);
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

  @override
  Widget build(BuildContext context) {
    final String displayName = UserSession().username ?? "User";

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header
            _buildHeader(context, displayName),

            // Scrollable content
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Quick actions
                  SliverToBoxAdapter(child: _buildQuickActions(context)),

                  // Browse venues banner
                  SliverToBoxAdapter(child: _buildVenueBanner(context)),

                  // My bookings section
                  SliverToBoxAdapter(child: _buildMyBookingsSection(context)),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String displayName) {
    final cachedCity = UserSession().city;

    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/edit-profile'),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF00A36C).withAlpha(25),
              backgroundImage: UserSession().imageUrl != null && UserSession().imageUrl!.isNotEmpty
                  ? NetworkImage(UserSession().imageUrl!)
                  : null,
              child: UserSession().imageUrl == null || UserSession().imageUrl!.isEmpty
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A36C),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.push('/edit-profile'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back,",
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    await context.push('/select-location');
                    if (mounted) setState(() {}); // Refresh to show updated city
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF00A36C), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        cachedCity ?? "Set your location",
                        style: TextStyle(
                          color: cachedCity != null ? Colors.grey[600] : const Color(0xFF00A36C),
                          fontSize: 13,
                          fontWeight: cachedCity != null ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, color: Colors.grey[500], size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/alerts'),
            icon: const Icon(Icons.notifications_none, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildActionCard(
                context,
                icon: Icons.location_on_outlined,
                label: "Browse\nVenues",
                color: const Color(0xFF00A36C),
                onTap: () => context.go('/venues'),
              ),
              const SizedBox(width: 12),
              _buildActionCard(
                context,
                icon: Icons.calendar_today_outlined,
                label: "My\nBookings",
                color: Colors.blue,
                onTap: () => context.push('/my-bookings'),
              ),
              const SizedBox(width: 12),
              _buildActionCard(
                context,
                icon: Icons.person_outline,
                label: "Edit\nProfile",
                color: Colors.orange,
                onTap: () => context.push('/edit-profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenueBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/venues'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00A36C), Color(0xFF00C781)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Find & Book\nYour Turf",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Browse available venues near you",
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "EXPLORE",
                      style: TextStyle(
                        color: Color(0xFF00A36C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.sports_soccer,
              size: 70,
              color: Colors.white.withAlpha(60),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF00A36C);
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'hold':
      case 'on_hold':
        return Colors.amber.shade700;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String start, String end) {
    try {
      String extract(String s) {
        if (s.contains(' ')) {
          final parts = s.split(' ');
          return parts.length >= 2 ? '${parts[1]} ${parts.length > 2 ? parts[2] : ''}' : s;
        }
        return s;
      }
      return '${extract(start)} - ${extract(end)}';
    } catch (_) {
      return '$start - $end';
    }
  }

  Widget _buildMyBookingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Recent Activity",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/my-bookings'),
                child: const Text(
                  "View All",
                  style: TextStyle(
                    color: Color(0xFF00A36C),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Loading state
          if (_isLoadingBookings)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF00A36C)),
              ),
            )

          // Empty state
          else if (_recentBookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_note_outlined,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    "Your bookings will appear here",
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A36C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.go('/venues'),
                      child: const Text(
                        "BOOK A VENUE",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )

          // Bookings list
          else
            ...List.generate(_recentBookings.length, (index) {
              final booking = _recentBookings[index];
              final sColor = _statusColor(booking.status);
              final imageUrl = _resolveImageUrl(booking.venueImage);

              return Container(
                margin: EdgeInsets.only(
                    bottom: index < _recentBookings.length - 1 ? 12 : 0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Left color bar
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: sColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),

                      // Venue image
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: sColor.withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.sports_soccer,
                                        size: 24, color: sColor),
                                  ),
                                )
                              : Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: sColor.withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.sports_soccer,
                                      size: 24, color: sColor),
                                ),
                        ),
                      ),

                      // Details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                booking.venueName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 11, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(booking.startTime),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.schedule_rounded,
                                      size: 11, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _formatTime(booking.startTime,
                                          booking.endTime),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
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

                      // Status + Price
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: sColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                booking.status,
                                style: TextStyle(
                                  color: sColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${booking.price.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF00A36C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
