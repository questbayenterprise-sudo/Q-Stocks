import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/Session/user_session.dart';
import '../../data/models/home_data.dart';
import '../../data/repositories/home_repository.dart';

// ============================================================
// 1. HOME CATEGORY (Simple helper class)
// ============================================================
class HomeCategory {
  final String title;
  final String description;
  final String route;
  HomeCategory({required this.title, required this.description, required this.route});
}

// ============================================================
// 2. HOME EVENTS
// ============================================================
abstract class HomeEvent {}

class LoadHomeData extends HomeEvent {}

// ============================================================
// 3. HOME STATES
// ============================================================
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<HomeCategory> categories;
  final ShopAnalytics analytics;
  final List<RecentSale> recentSales;

  HomeLoaded({
    required this.categories,
    required this.analytics,
    required this.recentSales,
  });
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

// ============================================================
// 4. HOME BLOC
// ============================================================
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository repository = HomeRepository();

  HomeBloc() : super(HomeInitial()) {
    on<LoadHomeData>((event, emit) async {
      emit(HomeLoading());
      
      try {
        final session = UserSession();
        final userId = session.userId ?? '0';
        final userType = session.userType?.name ?? 'user';

        // Fetch data from local/cloud repository in parallel
        final results = await Future.wait([
          repository.fetchAnalytics(userId, userType),
          repository.fetchRecentSales(),
        ]);

        final analytics = results[0] as ShopAnalytics;
        final sales = results[1] as List<RecentSale>;

        emit(HomeLoaded(
          categories: _getStaticCategories(),
          analytics: analytics,
          recentSales: sales,
        ));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });
  }

  // Static menu items for the dashboard grid
  List<HomeCategory> _getStaticCategories() {
    return [
      HomeCategory(
        title: "Products",
        description: "Chicken, Eggs & Items",
        route: "/products",
      ),
      HomeCategory(
        title: "Ledger",
        description: "Customer Notebook",
        route: "/customers",
      ),
      HomeCategory(
        title: "Inventory",
        description: "Stock Status",
        route: "/inventory/stocks",
      ),
      HomeCategory(
        title: "Reports",
        description: "Sales & Profit",
        route: "/inventory/reports",
      ),
    ];
  }
}