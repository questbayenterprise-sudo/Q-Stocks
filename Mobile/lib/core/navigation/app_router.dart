import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// --- Auth Imports ---
import '../../features/auth/Session/user_session.dart';
import '../../features/auth/pages/Login/auth_entry_page.dart';
import '../../features/auth/pages/Login/otp_page.dart';
import '../../features/auth/pages/Login/signup_page.dart';

// --- Home / Dashboard ---
import '../../../features/home/presentation/pages/dashboard_page.dart';
import '../../../features/home/presentation/bloc/home_bloc.dart';

// --- Shop Management ---
import '../../features/customers/data/models/customer_model.dart';
import '../../features/customers/presentation/pages/add_customer_page.dart';
import '../../features/inventory/presentation/pages/add_sales_page.dart';
import '../../features/inventory/presentation/pages/income_entry_page.dart';
import '../../features/inventory/presentation/pages/income_list_page.dart';
import '../../features/inventory/presentation/pages/pending_payments_page.dart';
import '../../features/inventory/presentation/pages/sales_list_page.dart';
import '../../features/shops/data/models/shop_model.dart';
import '../../features/shops/presentation/pages/my_shop_list_page.dart';
import '../../features/shops/presentation/pages/add_shop_page.dart';
import '../../features/shops/presentation/bloc/shop_bloc.dart';

// --- Product Management ---
import '../../features/products/data/models/product_model.dart';
import '../../features/products/presentation/pages/product_list_page.dart';
import '../../features/products/presentation/pages/add_product_page.dart';
import '../../../features/products/presentation/bloc/product_bloc.dart';

// --- Customer & Ledger Management ---
import '../../../features/customers/presentation/pages/customer_list_page.dart';
import '../../../features/customers/presentation/pages/customer_ledger_page.dart';
import '../../../features/customers/presentation/bloc/customer_bloc.dart';

// --- Inventory (Sales, Stocks, Reports) ---
import '../../../features/inventory/presentation/pages/stocks_page.dart';
import '../../../features/inventory/presentation/pages/reports_page.dart';
import '../../../features/inventory/presentation/bloc/inventory_bloc.dart';

// --- Profile & Settings ---
import '../../../features/profile/presentation/pages/more_page.dart';
import '../../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/admin_users_page.dart';
import '../../features/profile/presentation/pages/admin_settings_page.dart';

// --- Widgets ---
import '../../../core/widgets/custom_bottom_nav.dart';

// --- Guards Configuration ---
const _adminOnlyRoutes = {'/admin-settings', '/admin-users', '/shop-mapping'};

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = UserSession();
    final isLoggedIn = session.userId != null && session.userId!.isNotEmpty;
    final isAuthRoute = state.matchedLocation == '/';
    final path = state.matchedLocation;

    // If logged in and on login page, go to dashboard
    if (isLoggedIn && isAuthRoute) return '/home';

    // Restrict Admin-only routes
    if (_adminOnlyRoutes.contains(path) && session.userType != UserType.admin) {
      return '/home';
    }
    return null;
  },
  routes: [
    // 1. AUTH FLOW (No Bottom Nav)
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

    // 2. MAIN APP FLOW (With Bottom Nav & Scoped Blocs)
    ShellRoute(
      builder: (context, state, child) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => HomeBloc()),
          BlocProvider(create: (context) => ShopBloc()),
          BlocProvider(create: (context) => ProductBloc()), 
          BlocProvider(create: (context) => CustomerBloc()),
          BlocProvider(create: (context) => InventoryBloc()), 
        ],
        child: Scaffold(
          body: child, 
          bottomNavigationBar: const CustomBottomNav()
        ),
      ),
      routes: [
        // Dashboard / Home
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardPage(),
        ),

        // Products Tab
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductListPage(),
        ),
        GoRoute(
          path: '/add-product',
          builder: (context, state) => AddProductPage(
            initialProduct: state.extra as ProductModel?,
          ),
        ),

        // Shop Management Tab
        GoRoute(
          path: '/my-shops',
          builder: (context, state) => const MyShopListPage(),
        ),
        GoRoute(
          path: '/shops', // Alias for /my-shops
          builder: (context, state) => const MyShopListPage(),
        ),
        GoRoute(
          path: '/add-shop',
          builder: (context, state) => AddShopPage(
            initialShop: state.extra as ShopModel?,
          ),
        ),

        // Customers & Ledger Tab
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomerListPage(),
          routes: [
            GoRoute(
              path: ':id', // Deep link to specific ledger: /customers/101
              builder: (context, state) => CustomerLedgerPage(
                customerId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
// 1. Income List Page
GoRoute(
  path: '/inventory/income',
  builder: (context, state) => const IncomeListPage(),
),

// 2. Income Entry Form (Reuse your existing page)
GoRoute(
  path: '/inventory/income/add',
  builder: (context, state) => const IncomeEntryPage(),
),
        // Inventory Sub-Routes (Dropdown logic)
GoRoute(
  path: '/inventory/sales',
  builder: (context, state) => const SalesListPage(),
),
GoRoute(
  path: '/customers/add',
  builder: (context, state) => AddCustomerPage(
    initialCustomer: state.extra as CustomerModel?,
  ),
),
GoRoute(
  path: '/inventory/pending',
  builder: (context, state) => const PendingPaymentsPage(),
),
// 2. Add Sales Page (The Invoice Form)
GoRoute(
  path: '/inventory/sales/add',
  builder: (context, state) => const AddSalesPage(),
),        GoRoute(path: '/inventory/stocks', builder: (context, state) => const StocksPage()),
        GoRoute(path: '/inventory/reports', builder: (context, state) => const ReportsPage()),

        // Settings / More Tab
        GoRoute(path: '/more', builder: (context, state) => const MorePage()),
        GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfilePage()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
        
        // Admin Protected Routes
        GoRoute(path: '/admin-settings', builder: (context, state) => const AdminSettingsPage()),
        GoRoute(path: '/admin-users', builder: (context, state) => const AdminUsersPage()),
      ],
    ),
  ],
);