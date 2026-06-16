import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/sale_item_line.dart';
import '../../data/repositories/sales_repository.dart';

// ============================================================
// 1. INVENTORY EVENTS
// ============================================================
abstract class InventoryEvent {}

// For simple single-product sales
class CreateSaleEvent extends InventoryEvent {
  final SaleModel sale;
  CreateSaleEvent(this.sale);
}

// For the modern multi-product invoices
class SaveInvoiceEvent extends InventoryEvent {
  final String customerId;
  final String shopId;
  final List<SaleItemLine> items;
  final double advance;
  final String status;

  SaveInvoiceEvent({
    required this.customerId,
    required this.shopId,
    required this.items,
    required this.advance,
    required this.status,
  });
}

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
  final SalesRepository repository = SalesRepository();

  InventoryBloc() : super(InventoryInitial()) {
    
    // Handler for Multi-Product Invoice (Modern UI)
    on<SaveInvoiceEvent>((event, emit) async {
      emit(InventoryLoading());
      try {
        // Calculate total amount from all lines
        double total = event.items.fold(0, (sum, item) => sum + item.lineTotal);

        // FIXED: Calling with named arguments as required by SalesRepository
        await repository.createSale(
          customerId: event.customerId,
          shopId: event.shopId,
          totalAmount: total,
          advancePaid: event.advance,
          status: event.status,
          items: event.items,
        );

        emit(SaleSuccess());
      } catch (e) {
        emit(InventoryError("Save Failed: ${e.toString()}"));
      }
    });

    // Handler for Single Sale (Compatibility)
    on<CreateSaleEvent>((event, emit) async {
      emit(InventoryLoading());
      try {
        // Map the single sale model to the repository's new multi-item format
        await repository.createSale(
          customerId: event.sale.customerId,
          shopId: event.sale.shopId,
          totalAmount: event.sale.totalAmount,
          advancePaid: event.sale.paidAmount,
          status: 'COMPLETED',
          items: [
            SaleItemLine(
              // Create a dummy line item for the single product
              quantity: event.sale.weight,
              unitPrice: event.sale.rate,
            )
          ],
        );
        emit(SaleSuccess());
      } catch (e) {
        emit(InventoryError("Transaction Failed: ${e.toString()}"));
      }
    });
  }
}