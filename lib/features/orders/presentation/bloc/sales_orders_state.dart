import 'package:equatable/equatable.dart';
import '../../domain/models/sales_order_model.dart';

enum SalesOrdersStatus {
  initial,
  loading,
  loaded,
  error,
}

class SalesOrdersState extends Equatable {
  final SalesOrdersStatus status;
  final List<SalesOrderModel> salesOrders;
  final String? errorMessage;

  const SalesOrdersState({
    this.status = SalesOrdersStatus.initial,
    this.salesOrders = const [],
    this.errorMessage,
  });

  SalesOrdersState copyWith({
    SalesOrdersStatus? status,
    List<SalesOrderModel>? salesOrders,
    String? errorMessage,
  }) {
    return SalesOrdersState(
      status: status ?? this.status,
      salesOrders: salesOrders ?? this.salesOrders,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, salesOrders, errorMessage];
}

