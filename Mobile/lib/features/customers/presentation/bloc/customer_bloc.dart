import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class CustomerEvent {}
class LoadCustomers extends CustomerEvent {}

// States
abstract class CustomerState {}
class CustomerInitial extends CustomerState {}
class CustomerLoading extends CustomerState {}
class CustomerLoaded extends CustomerState {}
class CustomerError extends CustomerState {
  final String message;
  CustomerError(this.message);
}

// Bloc
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc() : super(CustomerInitial()) {
    on<LoadCustomers>((event, emit) async {
      emit(CustomerLoading());
      // Logic for loading customers and balances will go here
      emit(CustomerLoaded());
    });
  }
}