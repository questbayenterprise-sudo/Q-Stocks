import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

// ============================================================
// 1. CUSTOMER EVENTS
// ============================================================
abstract class CustomerEvent {}

class LoadCustomers extends CustomerEvent {}

class SaveCustomerEvent extends CustomerEvent {
  final CustomerModel customer;
  SaveCustomerEvent(this.customer);
}

class DeleteCustomerEvent extends CustomerEvent {
  final String id;
  DeleteCustomerEvent(this.id);
}

// ============================================================
// 2. CUSTOMER STATES
// ============================================================
abstract class CustomerState {}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<CustomerModel> customers;
  final double totalOutstanding; // Helpful for the summary header

  CustomerLoaded({
    required this.customers, 
    this.totalOutstanding = 0.0
  });
}

class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
}

// ============================================================
// 3. CUSTOMER BLOC
// ============================================================
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  // Use the repository we created earlier
  final CustomerRepository repository = CustomerRepository();

  CustomerBloc() : super(CustomerInitial()) {
    
    // --- Event: Load all active customers ---
    on<LoadCustomers>((event, emit) async {
      emit(CustomerLoading());
      try {
        final List<CustomerModel> customers = await repository.fetchCustomers();
        
        // Calculate total outstanding for the header summary
        double total = customers.fold(0, (sum, item) => sum + item.currentBalance);
        
        emit(CustomerLoaded(
          customers: customers, 
          totalOutstanding: total
        ));
      } catch (e) {
        emit(CustomerError("Could not load customers: ${e.toString()}"));
      }
    });

    // --- Event: Add or Update a customer ---
    on<SaveCustomerEvent>((event, emit) async {
      // Note: We don't necessarily need a 'Saving' state if the UI 
      // uses context.pop() immediately, but it's good for logic.
      try {
        await repository.saveCustomer(event.customer);
        // After saving, refresh the list automatically
        add(LoadCustomers());
      } catch (e) {
        emit(CustomerError("Failed to save customer: ${e.toString()}"));
      }
    });

    // --- Event: Soft Delete (Deactivate) a customer ---
    on<DeleteCustomerEvent>((event, emit) async {
      try {
        await repository.deleteCustomer(event.id);
        // Refresh the list to remove the deleted customer from view
        add(LoadCustomers());
      } catch (e) {
        emit(CustomerError("Delete failed: ${e.toString()}"));
      }
    });
  }
}