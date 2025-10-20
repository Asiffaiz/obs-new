import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  const LoadProducts();
}

class UploadProduct extends ProductEvent {
  final String filePath;
  final int productId;

  const UploadProduct({required this.filePath, required this.productId});

  @override
  List<Object?> get props => [filePath, productId];
}

class ClearProductError extends ProductEvent {
  const ClearProductError();
}
