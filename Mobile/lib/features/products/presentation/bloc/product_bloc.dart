import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class ProductEvent {}
class LoadProducts extends ProductEvent {}

// States
abstract class ProductState {}
class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

// Bloc
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(ProductInitial()) {
    on<LoadProducts>((event, emit) async {
      emit(ProductLoading());
      // Logic for loading broiler products will go here
      emit(ProductLoaded());
    });
  }
}