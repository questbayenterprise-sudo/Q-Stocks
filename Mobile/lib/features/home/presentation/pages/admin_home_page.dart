import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/Session/user_session.dart';
import '../../Models/home_data.dart';
import '../bloc/home_bloc.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  @override
  void initState() {
    super.initState();
    // This triggers the LoadHomeData event in your HomeBloc
    context.read<HomeBloc>().add(LoadHomeData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
           if (state is HomeError) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(state.message, style: TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: () => context.read<HomeBloc>().add(LoadHomeData()),
            child: const Text("Retry"),
          )
        ],
      ),
    );
  }
          if (state is HomeLoaded) {
            return SafeArea(
              child: Column(
                children: [
                  // --- STATIC HEADER (Does not move) ---
                  _buildStaticHeader(context),

                  // --- SCROLLABLE CONTENT ---
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildAnalyticsDashboard(state.analytics),

                        // PASS THE RECENT BOOKINGS DATA HERE
                        _buildRecentBookingsSection(
                          context,
                          state.recentBookings,
                        ),

                        // _buildPromoBanner(),
                        // _buildCategoryGrid(context, state.categories),
                        // _buildPlayoAtWorkSection(),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  // --- 1. FIXED HEADER (Converted from Sliver to regular Widget) ---
  Widget _buildStaticHeader(BuildContext context) {
      final String displayName = UserSession().username ?? "Guest";

    return Container(
      color: Theme.of(context).cardColor, // Background color for the fixed header
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF00A36C).withAlpha(25),
            backgroundImage: UserSession().imageUrl != null && UserSession().imageUrl!.isNotEmpty
                ? NetworkImage(UserSession().imageUrl!)
                : null,
            child: UserSession().imageUrl == null || UserSession().imageUrl!.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : "A",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A36C),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
             Text(
                "Hey $displayName !", // Dynamic Username
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
                Row(
                  children: [
                    Text(
                      "Mannargudi",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // IconButton(
          //   onPressed: () => context.push('/conversations'),
          //   icon: const Icon(Icons.chat_bubble_outline),
          // ),
          IconButton(
            onPressed: () => context.push('/alerts'),
            icon: const Icon(Icons.notifications_none),
          ),
          // IconButton(
          //   onPressed: () => context.push('/games'),
          //   icon: const Icon(Icons.calendar_month_outlined),
          // ),
        ],
      ),
    );
  }

  // --- 2. ANALYTICS DASHBOARD ---
  Widget _buildAnalyticsDashboard(TurfAnalytics stats) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Turf Analytics" /* style... */),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  "Bookings",
                  "${stats.totalBookings}",
                  Icons.sports_soccer,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  "Revenue",
                  "₹${stats.totalRevenue}",
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  "Occupancy",
                  "${stats.occupancy}%",
                  Icons.trending_up,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Pass stats.weeklyTrend to the chart
            _buildWeeklyBarChart(stats.weeklyTrend),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<WeeklyTrend> trends) {
    // 1. Check if data exists
    bool hasNoData = trends.isEmpty || trends.every((t) => t.count == 0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (hasNoData) {
      return Container(
        width: double.infinity,
        height: 150,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            "No records found for this week",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Calculate max for scaling
    int maxCount = trends.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) maxCount = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0, left: 4.0),
          child: Text(
            "Weekly Booking Trend",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // --- CHART CONTAINER ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          ),
          child: Column(
            children: [
              // --- BARS ---
              SizedBox(
                height: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: trends.map((t) {
                    double barHeight = (t.count / maxCount) * 80;

                    return SizedBox(
                      width: 35,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Tooltip-style count (Optional visual addition)
                          if (t.count > 0)
                            Text(
                              "${t.count}",
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            width: 25,
                            height: barHeight > 4 ? barHeight : 4,
                            decoration: BoxDecoration(
                              // MODERN GRADIENT SCHEME
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF00D28D), // Soft Green
                                  Color(0xFF00A36C), // Deep Green
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            t.day.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // --- DIVIDER ---
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, thickness: 0.5),
              ),

              // --- LEGEND ---
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A36C),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Number of Bookings",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return SliverToBoxAdapter(
      child: Container(
        height: 160,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFB33A3A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                left: 20,
                top: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Get ₹175 cashback*",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "when you pay via Jupiter UPI\nusing your RuPay credit card.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 0,
                bottom: 0,
                child: Opacity(
                  opacity: 0.2,
                  child: Icon(Icons.stars, size: 150, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. CATEGORY GRID ---
  Widget _buildCategoryGrid(
    BuildContext context,
    List<HomeCategory> categories,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate((context, i) {
          final cat = categories[i];
          return GestureDetector(
            onTap: () => context.push(cat.route),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: categories.length),
      ),
    );
  }

  // --- 5. CORPORATE SECTION ---
  Widget _buildPlayoAtWorkSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF007BFF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q-Play at\nWork",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 12),
                    Icon(Icons.laptop_mac, color: Colors.white, size: 36),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildMiniCard(
                    "CORPORATE VOUCHER",
                    "Treat employees with vouchers",
                  ),
                  const SizedBox(height: 6),
                  _buildMiniCard("FITNESS IN OFFICE", "Exercise while working"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCard(String title, String desc) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingsSection(
    BuildContext context,
    List<RecentBooking> bookings,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          // ... decoration ...
          child: Column(
            children: [
              // ... Header Row ...
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookings.length, // Use dynamic length
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) => _buildBookingTile(
                  bookings[index],
                ), // Pass the specific booking
              ),
              _buildSeeMoreButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingTile(RecentBooking booking) {
    return ListTile(
      title: Text(booking.courtName),
      subtitle: Text("${booking.bookingRef} • ${booking.userName}"),
      trailing: Column(
        children: [
          Text("₹${booking.price}"),
          _buildStatusBadge(booking.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color color;
    String label;

    switch (status) {
      case BookingStatus.confirmed:
        color = const Color(0xFF00A36C);
        label = "CONFIRMED";
        break;
      case BookingStatus.pending:
        color = Colors.orange;
        label = "PENDING";
        break;
      default:
        color = Colors.grey;
        label = "UNKNOWN";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSeeMoreButton(BuildContext context) {
    return TextButton(
      onPressed: () => context.push('/admin-bookings-full'),
      child: const Text(
        "VIEW ALL BOOKINGS",
        style: TextStyle(
          color: Color(0xFF00A36C),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
