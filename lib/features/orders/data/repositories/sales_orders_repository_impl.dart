import '../../domain/models/sales_order_model.dart';
import '../../domain/repositories/sales_orders_repository.dart';
import '../services/sales_orders_service.dart';

class SalesOrdersRepositoryImpl implements SalesOrdersRepository {
  final SalesOrdersService _salesOrdersService;

  SalesOrdersRepositoryImpl({required SalesOrdersService salesOrdersService})
      : _salesOrdersService = salesOrdersService;

  @override
  Future<List<SalesOrderModel>> getSalesOrders() async {
    return await _salesOrdersService.getSalesOrders();
  }
}

