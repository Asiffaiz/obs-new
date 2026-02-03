import '../models/sales_order_model.dart';

abstract class SalesOrdersRepository {
  Future<List<SalesOrderModel>> getSalesOrders();
}

