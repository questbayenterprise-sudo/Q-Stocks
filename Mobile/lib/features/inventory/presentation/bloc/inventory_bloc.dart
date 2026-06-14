import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/sales_repository.dart';

// ============================================================
// 1. INVENTORY EVENTS
// ============================================================
abstract class InventoryEvent {}

class CreateSaleEvent extends InventoryEvent {
  final SaleModel sale;
  CreateSaleEvent(this.sale);
}

// Add these for Stock management later
class LoadStocksEvent extends InventoryEvent {}

// ============================================================
// 2. INVENTORY STATES
// ============================================================
abstract class InventoryState {}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class SaleSuccess extends InventoryState {}

class InventoryError extends InventoryState {
  final String message;
  InventoryError(this.message);
}

// ============================================================
// 3. INVENTORY BLOC
// ============================================================
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  // Make sure you have created SalesRepository in lib/features/inventory/data/repositories/
  final SalesRepository repository = SalesRepository();

  InventoryBloc() : super(InventoryInitial()) {
    
    on<CreateSaleEvent>((event, emit) async {
      emit(InventoryLoading());
      try {
        // This triggers the SQLite transaction (Order + Ledger + Stock Update)
        await repository.createSale(event.sale);
        emit(SaleSuccess());
      } catch (e) {
        emit(InventoryError("Transaction Failed: ${e.toString()}"));
      }
    });

    on<LoadStocksEvent>((event, emit) async {
      // Logic for loading stock levels will go here
    });
  }
}