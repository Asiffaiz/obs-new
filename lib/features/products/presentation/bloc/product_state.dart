import 'package:equatable/equatable.dart';
import 'package:voicealerts_obs/features/documents/domain/models/document_model.dart';
import 'package:voicealerts_obs/features/products/domain/models/product_model.dart';

enum ProductStatus { initial, loading, loaded, error, uploading, uploaded }

class ProductState extends Equatable {
  final List<ProductModel> products;
  final ProductStatus status;
  final String? errorMessage;
  final bool isUploading;
  final bool uploadSuccess;

  const ProductState({
    this.products = const [],
    this.status = ProductStatus.initial,
    this.errorMessage,
    this.isUploading = false,
    this.uploadSuccess = false,
  });

  ProductState copyWith({
    List<ProductModel>? products,
    ProductStatus? status,
    String? errorMessage,
    bool? isUploading,
    bool? uploadSuccess,
  }) {
    return ProductState(
      products: products ?? this.products,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isUploading: isUploading ?? this.isUploading,
      uploadSuccess: uploadSuccess ?? this.uploadSuccess,
    );
  }

  @override
  List<Object?> get props => [
    products,
    status,
    errorMessage,
    isUploading,
    uploadSuccess,
  ];
}
