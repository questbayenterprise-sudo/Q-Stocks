import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/models/shop_model.dart';

// ============================================================
// 1. SHOP EVENTS
// ============================================================
abstract class ShopEvent {}

class LoadShops extends ShopEvent {}

class SaveShopEvent extends ShopEvent {
  final ShopModel shop;
  SaveShopEvent(this.shop);
}

class DeleteShopEvent extends ShopEvent {
  final String id;
  DeleteShopEvent(this.id);
}

// ============================================================
// 2. SHOP STATES
// ============================================================
abstract class ShopState {}

class ShopInitial extends ShopState {}

class ShopLoading extends ShopState {}

class ShopSaving extends ShopState {}

class ShopLoaded extends ShopState {
  final List<ShopModel> shops;
  ShopLoaded(this.shops);
}

class ShopError extends ShopState {
  final String message;
  ShopError(this.message);
}

// ============================================================
// 3. SHOP BLOC
// ============================================================
class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final ShopRepository repository = ShopRepository();

  ShopBloc() : super(ShopInitial()) {
    
    // Handler for Loading Shops
    on<LoadShops>((event, emit) async {
      emit(ShopLoading());
      try {
        final shops = await repository.fetchShops();
        emit(ShopLoaded(shops));
      } catch (e) {
        emit(ShopError("Failed to fetch shops: ${e.toString()}"));
      }
    });

    // Handler for Saving/Updating a Shop
    on<SaveShopEvent>((event, emit) async {
      emit(ShopSaving());
      try {
        await repository.saveShop(event.shop);
        // After saving, immediately trigger a reload to update the list
        add(LoadShops()); 
      } catch (e) {
        emit(ShopError("Failed to save: ${e.toString()}"));
      }
    });

    // Handler for Deleting a Shop
    on<DeleteShopEvent>((event, emit) async {
      try {
        await repository.deleteShop(event.id);
        add(LoadShops());
      } catch (e) {
        emit(ShopError("Delete failed: ${e.toString()}"));
      }
    });
  }
}