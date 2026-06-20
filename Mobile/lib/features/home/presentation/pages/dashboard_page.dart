import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/Session/user_session.dart';
import '../../data/models/home_data.dart';
import '../bloc/home_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
@override
void initState() {
  super.initState();
  // Let the UI breathe before hitting the database
  Future.delayed(const Duration(milliseconds: 400), () {
    if (mounted) {
      context.read<HomeBloc>().add(LoadHomeData());
    }
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00A36C)));
          }

          if (state is HomeError) {
            return _buildErrorView(state.message);
          }

          if (state is HomeLoaded) {
            return RefreshIndicator(
              onRefresh: () async => context.read<HomeBloc>().add(LoadHomeData()),
              child: SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeader(context),
                    _buildQuickActions(context),
                    _buildAnalyticsCards(state.analytics),
                    _buildWeeklyTrend(state.analytics.weeklyTrend),
                    _buildRecentSalesHeader(context),
                    _buildRecentSalesList(state.recentSales),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/sales'),
        backgroundColor: const Color(0xFF00A36C),
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text("NEW SALE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 1. Header showing User Info & Role
  Widget _buildHeader(BuildContext context) {
    final name = UserSession().username ?? "Manager";
    final role = UserSession().userType?.name.toUpperCase() ?? "STAFF";

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF00A36C).withOpacity(0.1),
              child: Text(name[0].toUpperCase(), 
                style: const TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hello, $name!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(role, style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // IconButton(
            //   icon: const Icon(Icons.notifications_none_outlined),
            //   onPressed: () => context.push('/alerts'),
            // )
          ],
        ),
      ),
    );
  }

  // 2. Navigation Shortcuts
  Widget _buildQuickActions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _actionBtn(context, "Products", Icons.inventory_2_outlined, Colors.orange, '/products'),
            _actionBtn(context, "Ledger", Icons.menu_book_outlined, Colors.blue, '/customers'),
            _actionBtn(context, "Stocks", Icons.warehouse_outlined, Colors.teal, '/inventory/stocks'),
            _actionBtn(context, "Reports", Icons.analytics_outlined, Colors.purple, '/inventory/reports'),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(BuildContext context, String label, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // 3. Analytics Section (Sales, Stock weight, Dues)
  Widget _buildAnalyticsCards(ShopAnalytics stats) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _statCard("Today Sales", "₹${stats.totalSales}", Colors.green),
            const SizedBox(width: 12),
            _statCard("Stock (kg)", "${stats.totalStockValue}", Colors.blue),
            const SizedBox(width: 12),
            _statCard("Pending Dues", "₹${stats.customerDues}", Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  // 4. Bar Chart for weekly sales
  Widget _buildWeeklyTrend(List<WeeklyTrend> trends) {
    if (trends.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    int maxCount = trends.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) maxCount = 1;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Weekly Sales Trend", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trends.map((t) {
                  double barHeight = (t.count / maxCount) * 80;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 18,
                        height: barHeight.clamp(4, 80),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF00D28D), Color(0xFF00A36C)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(t.day, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Recent Transaction List
  Widget _buildRecentSalesHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Recent Transactions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
onPressed: () => context.push('/inventory/sales'),
              child: const Text("View All", style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSalesList(List<RecentSale> sales) {
    if (sales.isEmpty) {
      return const SliverToBoxAdapter(child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: Text("No transactions recorded today", style: TextStyle(color: Colors.grey))),
      ));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final sale = sales[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Order #${sale.orderRef}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(sale.customerName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ]),
              ),
              Text("₹${sale.amount}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF00A36C))),
            ],
          ),
        );
      }, childCount: sales.length),
    );
  }

  Widget _buildErrorView(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
            onPressed: () => context.read<HomeBloc>().add(LoadHomeData()), 
            child: const Text("RETRY", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}