import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/pages/Login/signup_page.dart';

// --- Auth Imports ---
import '../../features/auth/Session/user_session.dart';
import '../../features/auth/pages/Login/auth_entry_page.dart';
import '../../features/auth/pages/Login/otp_page.dart';
import '../../features/auth/pages/Login/signup_page.dart';
import '../../features/auth/pages/Login/Owner_Onboarding_Page.dart';

// --- Home Imports ---
import '../../../features/home/presentation/pages/home_page.dart';
import '../../../features/home/presentation/pages/admin_bookings_full_page.dart';

// --- Venue Imports ---
import '../../../features/venues/domain/entities/venue.dart';
import '../../../features/venues/presentation/pages/venue_list_page.dart';
import '../../../features/venues/presentation/pages/venue_detail_page.dart';
import '../../../features/venues/presentation/pages/add_venue_page.dart';

// --- Other Feature Imports ---
import '../../../features/games/presentation/pages/calendar_page.dart';
import '../../../features/trainers/presentation/pages/trainers_page.dart';
import '../../../features/chat/presentation/pages/conversations_page.dart';
import '../../../features/notifications/presentation/pages/alerts_page.dart';
import '../../../features/profile/presentation/pages/more_page.dart';
import '../../features/profile/presentation/pages/about_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/delete_account_page.dart';
import '../../features/profile/presentation/pages/help_center_page.dart';
import '../../../features/profile/presentation/pages/Language_Page.dart';
import '../../features/profile/presentation/pages/privacy_policy_page.dart';
import '../../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/select_location_page.dart';
import '../../features/likes/presentation/pages/liked_venues_page.dart';
import '../../../features/profile/presentation/pages/my_bookings_page.dart';
import '../../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/admin_settings_page.dart';
import '../../features/profile/presentation/pages/admin_users_page.dart';
import '../../features/profile/presentation/pages/venue_mapping_page.dart';

// --- My Venues Imports ---
import '../../features/My Venues/presentation/pages/venue_list_page.dart';
import '../../features/My Venues/presentation/pages/add_venue_page.dart';
import '../../features/My Venues/presentation/pages/venue_detail_page.dart';
import '../../features/My Venues/domain/entities/venue.dart';

// --- Widgets ---
import '../../../core/widgets/custom_bottom_nav.dart';
import '../../features/venues/data/repositories/venue_repository.dart';
import '../../features/venues/presentation/bloc/venue_bloc.dart';

// --- Role-based route sets ---
const _adminOnlyRoutes = {'/admin-settings', '/admin-bookings-full', '/admin-users', '/venue-mapping'};
const _managementRoutes = {'/Myvenues', '/my-add-venue', '/my-venue-detail'};

bool _isAdminOrOwner(UserType? type) =>
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

    if (isLoggedIn && isAuthRoute) {
      return '/home';
    }

    // Admin-only route guard
    if (_adminOnlyRoutes.contains(path) && session.userType != UserType.admin) {
      return '/home';
    }

    // Management route guard (admin + owner/vendor/manager)
    if (_managementRoutes.contains(path) && !_isAdminOrOwner(session.userType)) {
      return '/venues';
    }

    return null;
  },
  routes: [
    // Routes WITHOUT Bottom Navigation Bar
    GoRoute(path: '/', builder: (context, state) => const AuthEntryPage()),

    // GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        // Cast to Map<String, dynamic> to handle the data safely
        final data = state.extra as Map<String, dynamic>?;

        return OtpPage(
          email: data?['email'] ?? '',
          // Change 'phone:' to 'phoneNumber:' to match your OtpPage constructor
          phoneNumber: data?['phone'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/conversations',
      builder: (context, state) => const ConversationsPage(),
    ),
    GoRoute(path: '/alerts', builder: (context, state) => const AlertsPage()),
    GoRoute(path: '/liked-venues', builder: (context, state) => const LikedVenuesPage()),
     GoRoute(
      path: '/venue-detail',
      builder: (context, state) {
        final venue = state.extra as VenueEntity;
        return VenueDetailPage(venue: venue);
      },
    ),
    GoRoute(
      path: '/my-venue-detail',
      builder: (context, state) {
        final venue = state.extra as MyVenueEntity;
        return MyVenueDetailPage(venue: venue);
      },
    ),

    // Routes WITH Bottom Navigation Bar
    ShellRoute(
      builder: (context, state, child) =>
          Scaffold(body: child, bottomNavigationBar: const CustomBottomNav()),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/games',
          builder: (context, state) => const CalendarPage(),
        ),
        GoRoute(
          path: '/trainers',
          builder: (context, state) => const TrainersPage(),
        ),
        GoRoute(
  path: '/venues',
  builder: (context, state) => BlocProvider(
    create: (context) => VenueBloc(VenueRepository()), // Bloc exists ONLY for this route
    child: const VenueListPage(),
  ),
),
           GoRoute(
          path: '/Myvenues',
          builder: (context, state) => const MyVenueListPage(),
        ),
        GoRoute(path: '/more', builder: (context, state) => const MorePage()),
        GoRoute(
          path: '/add-venue',
          builder: (context, state) {
            final venue = state.extra as VenueEntity?;
            return AddVenuePage(initialVenue: venue);
          },
        ),
        GoRoute(
          path: '/my-add-venue',
          builder: (context, state) {
            final venue = state.extra as MyVenueEntity?;
            return MyAddVenuePage(initialVenue: venue);
          },
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfilePage(),
        ),
        GoRoute(
          path: '/my-bookings',
          builder: (context, state) => const MyBookingsPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordPage(),
        ),
        GoRoute(
          path: '/language',
          builder: (context, state) => const LanguagePage(),
        ),
        GoRoute(
          path: '/privacy-policy',
          builder: (context, state) => const PrivacyPolicyPage(),
        ),
        GoRoute(
          path: '/delete-account',
          builder: (context, state) => const DeleteAccountPage(),
        ),
        GoRoute(
          path: '/help-center',
          builder: (context, state) => const HelpCenterPage(),
        ),
        GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
        GoRoute(
          path: '/admin-settings',
          builder: (context, state) => const AdminSettingsPage(),
        ),
        GoRoute(
          path: '/admin-users',
          builder: (context, state) => const AdminUsersPage(),
        ),
        GoRoute(
          path: '/venue-mapping',
          builder: (context, state) => const VenueMappingPage(),
        ),
        GoRoute(
          path: '/select-location',
          builder: (context, state) => const SelectLocationPage(),
        ),
        GoRoute(
          path: '/admin-bookings-full',
          builder: (context, state) => const AdminBookingsFullPage(),
        ),
        GoRoute(
          path: '/owner-onboarding',
          builder: (context, state) => const OwnerOnboardingPage(),
        ),
      ],
    ),
  ],
);
