import 'package:equatable/equatable.dart';

abstract class SalesOrdersEvent extends Equatable {
  const SalesOrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadSalesOrders extends SalesOrdersEvent {
  const LoadSalesOrders();
}

