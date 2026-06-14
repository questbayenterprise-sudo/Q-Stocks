import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/models/product_model.dart';

abstract class ProductEvent {}
class LoadProducts extends ProductEvent {}
class SaveProductEvent extends ProductEvent {
  final ProductModel product;
  SaveProductEvent(this.product);
}
class DeleteProductEvent extends ProductEvent {
  final String id;
  DeleteProductEvent(this.id);
}

abstract class ProductState {}
class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  ProductLoaded(this.products);
}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository = ProductRepository();

  ProductBloc() : super(ProductInitial()) {
    on<LoadProducts>((event, emit) async {
      emit(ProductLoading());
      try {
        final products = await repository.fetchProducts();
        emit(ProductLoaded(products));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });

    on<SaveProductEvent>((event, emit) async {
      try {
        await repository.saveProduct(event.product);
        add(LoadProducts());
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });

    on<DeleteProductEvent>((event, emit) async {
      try {
        await repository.deleteProduct(event.id);
        add(LoadProducts());
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });
  }
}