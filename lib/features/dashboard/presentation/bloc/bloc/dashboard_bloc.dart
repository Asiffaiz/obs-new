import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:voicealerts_obs/features/dashboard/domain/Repositories/dashboard_repository.dart';
import 'package:voicealerts_obs/features/dashboard/domain/models/dashboard_data_model.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _dashboardRepository;

  DashboardBloc({required DashboardRepository dashboardRepository})
    : _dashboardRepository = dashboardRepository,
      super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }



  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(DashboardLoading());

      final dashboardData =
          await _dashboardRepository.getDashboardData();

      emit(
        DashboardLoaded(
          dashboardData: dashboardData,
        ),
      );
    } catch (e) {
      emit(
        DashboardError(
          errorMessage: e.toString(),
        ),
      );
    }
  }
}


