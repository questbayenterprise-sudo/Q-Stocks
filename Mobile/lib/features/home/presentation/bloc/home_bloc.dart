import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../auth/Session/user_session.dart';
import '../../Models/home_data.dart';
import '../../Repository/dashboard.dart';

abstract class HomeEvent {}

class LoadHomeData extends HomeEvent {}

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<HomeCategory> categories;
  final TurfAnalytics analytics;
  final List<RecentBooking> recentBookings;
  HomeLoaded({
    required this.categories,
    required this.analytics,
    required this.recentBookings,
  });
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  // Hardcode the URL here or in a constants file
  final String baseUrl = AppConfig.baseUrl;
  final HomeRepository repository = HomeRepository();

  HomeBloc() : super(HomeInitial()) {
    // No repository in constructor anymore
    on<LoadHomeData>((event, emit) async {
      emit(HomeLoading());
 print("--- Home Loading Started ---");
      try {
        List<HomeCategory> _getStaticCategories() {
          return [
            HomeCategory(
              title: "Bookings",
              description: "Manage slots",
              route: "/admin-bookings-full",
            ),
            HomeCategory(
              title: "Courts",
              description: "Check status",
              route: "/courts",
            ),
            HomeCategory(
              title: "Payments",
              description: "Revenue",
              route: "/revenue",
            ),
            HomeCategory(
              title: "Customers",
              description: "Database",
              route: "/players",
            ),
          ];
        }

        final session = UserSession();
        final userId = session.userId;
        final userType = session.userType?.name ?? 'user';
        if (userId == null) {
                print("Error: UserID is null");

          return;
        }
        // Static Categories

        final results = await Future.wait([
          repository.fetchAnalytics(userId, userType),
          repository.fetchRecentBookings(userId, userType),
        ]);

        final analytics = results[0] as TurfAnalytics;
        final bookings = results[1] as List<RecentBooking>;
  print("Data fetched successfully!"); 
        emit(
          HomeLoaded(
            categories: _getStaticCategories(),
            analytics: analytics,
            recentBookings: bookings,
          ),
        );
      } catch (e, stacktrace) {
    // THIS IS THE MOST IMPORTANT PART
    print("CRITICAL ERROR: $e"); 
    print("STACKTRACE: $stacktrace"); 
    emit(HomeError(e.toString()));
  }
    });
  }
}
