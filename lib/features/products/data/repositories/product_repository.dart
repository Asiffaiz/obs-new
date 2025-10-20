import 'package:voicealerts_obs/features/products/data/services/product_service.dart';
import 'package:voicealerts_obs/features/products/domain/models/product_model.dart';

class ProductRepository {
  final ProductService _productService = ProductService();

  Future<List<ProductModel>> getProducts() async {
    try {
      return await _productService.getProducts();
    } catch (e) {
      rethrow;
    }
  }
}
