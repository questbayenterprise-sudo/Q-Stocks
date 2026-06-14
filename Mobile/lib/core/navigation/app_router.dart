import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// --- Auth Imports ---
import '../../features/auth/Session/user_session.dart';
import '../../features/auth/pages/Login/auth_entry_page.dart';
import '../../features/auth/pages/Login/otp_page.dart';
import '../../features/auth/pages/Login/signup_page.dart';
import '../../features/auth/pages/Login/Owner_Onboarding_Page.dart';

// --- Home / Dashboard ---
import '../../../features/home/presentation/pages/dashboard_page.dart';
import '../../../features/home/presentation/bloc/home_bloc.dart';

// --- Shop & Product Management ---
import '../../features/shops/presentation/pages/my_shop_list_page.dart'; // Your refactored MyVenueListPage
import '../../features/shops/presentation/pages/add_shop_page.dart';    // Your refactored MyAddVenuePage
import '../../features/shops/presentation/bloc/shop_bloc.dart';
import '../../../features/products/presentation/pages/product_list_page.dart';

// --- Customer & Ledger ---
import '../../../features/customers/presentation/pages/customer_list_page.dart';
import '../../../features/customers/presentation/pages/customer_ledger_page.dart';

// --- Inventory Dropdown Routes ---
import '../../../features/inventory/presentation/pages/sales_page.dart';
import '../../../features/inventory/presentation/pages/stocks_page.dart';
import '../../../features/inventory/presentation/pages/reports_page.dart';

// --- Profile & Settings ---
import '../../../features/profile/presentation/pages/more_page.dart';
import '../../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/admin_users_page.dart';
import '../../features/profile/presentation/pages/admin_settings_page.dart';

// --- Widgets ---
import '../../../core/widgets/custom_bottom_nav.dart';
import '../../../features/products/presentation/bloc/product_bloc.dart';
import '../../../features/customers/presentation/bloc/customer_bloc.dart';
// --- Guards ---
const _adminOnlyRoutes = {'/admin-settings', '/admin-users', '/shop-mapping'};

bool _isManagement(UserType? type) =>
    type == UserType.admin ||
    type == UserType.owner ||
    type == UserType.vendor ||
    type == UserType.manager;

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = UserSession();
    final isLoggedIn = session.userId != null && session.userId!.isNotEmpty;
    final isAuthRoute = state.matchedLocation == '/';
    final path = state.matchedLocation;

    if (isLoggedIn && isAuthRoute) return '/home';

    if (_adminOnlyRoutes.contains(path) && session.userType != UserType.admin) {
      return '/home';
    }
    return null;
  },
  routes: [
    // 1. Auth Routes
    GoRoute(path: '/', builder: (context, state) => const AuthEntryPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return OtpPage(
          email: data?['email'] ?? '',
          phoneNumber: data?['phone'] ?? '',
        );
      },
    ),

    // 2. Main App Shell
    ShellRoute(
      builder: (context, state, child) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => HomeBloc()),
          BlocProvider(create: (context) => ShopBloc()),
          // FIXED: Added these so the Product and Customer pages work!
          BlocProvider(create: (context) => ProductBloc()), 
          BlocProvider(create: (context) => CustomerBloc()),
        ],
        child: Scaffold(
          body: child, 
          bottomNavigationBar: const CustomBottomNav()
        ),
      ),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardPage(),
        ),

        // Product Catalog (General view)
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductListPage(),
        ),

        // FIXED: Changed /shops to MyShopListPage (The management list)
        GoRoute(
          path: '/my-shops', // Use the path your Bottom Nav calls
          builder: (context, state) => const MyShopListPage(), 
        ),
        
        // This handles the generic '/shops' if your Nav is still calling that
        GoRoute(
          path: '/shops',
          builder: (context, state) => const MyShopListPage(),
        ),

        GoRoute(
          path: '/add-shop',
          builder: (context, state) => const AddShopPage(),
        ),

        // Customer Ledger
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomerListPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => CustomerLedgerPage(
                customerId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),

        // Inventory
        GoRoute(path: '/inventory/sales', builder: (context, state) => const SalesPage()),
        GoRoute(path: '/inventory/stocks', builder: (context, state) => const StocksPage()),
        GoRoute(path: '/inventory/reports', builder: (context, state) => const ReportsPage()),

        // Settings
        GoRoute(path: '/more', builder: (context, state) => const MorePage()),
        GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfilePage()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
        
        GoRoute(path: '/admin-settings', builder: (context, state) => const AdminSettingsPage()),
        GoRoute(path: '/admin-users', builder: (context, state) => const AdminUsersPage()),
      ],
    ),
  ],
);