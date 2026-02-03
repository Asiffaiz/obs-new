import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/sales_orders_repository.dart';
import 'sales_orders_event.dart';
import 'sales_orders_state.dart';

class SalesOrdersBloc extends Bloc<SalesOrdersEvent, SalesOrdersState> {
  final SalesOrdersRepository _salesOrdersRepository;

  SalesOrdersBloc({required SalesOrdersRepository salesOrdersRepository})
      : _salesOrdersRepository = salesOrdersRepository,
        super(const SalesOrdersState()) {
    on<LoadSalesOrders>(_onLoadSalesOrders);
  }

  Future<void> _onLoadSalesOrders(
    LoadSalesOrders event,
    Emitter<SalesOrdersState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SalesOrdersStatus.loading));

      final salesOrders = await _salesOrdersRepository.getSalesOrders();

      emit(
        state.copyWith(
          status: SalesOrdersStatus.loaded,
          salesOrders: salesOrders,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SalesOrdersStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}

