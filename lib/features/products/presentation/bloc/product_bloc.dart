import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicealerts_obs/features/products/data/repositories/product_repository.dart';
import 'package:voicealerts_obs/features/products/presentation/bloc/product_event.dart';
import 'package:voicealerts_obs/features/products/presentation/bloc/product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository productRepository;

  ProductBloc({required this.productRepository}) : super(const ProductState()) {
    on<LoadProducts>(_onLoadProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(state.copyWith(status: ProductStatus.loading, errorMessage: null));

    try {
      final products = await productRepository.getProducts();
      emit(state.copyWith(products: products, status: ProductStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          status: ProductStatus.error,
          errorMessage: 'Failed to load products: ${e.toString()}',
        ),
      );
    }
  }
}
