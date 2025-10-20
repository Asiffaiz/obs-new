import 'package:voicealerts_obs/features/dashboard/data/services/dashboard_service.dart';
import 'package:voicealerts_obs/features/dashboard/domain/Repositories/dashboard_repository.dart';
import 'package:voicealerts_obs/features/dashboard/domain/models/dashboard_data_model.dart';

class DashboardRepositoryImpl extends DashboardRepository {
  final DashboardService _dashboardService;

  DashboardRepositoryImpl({required DashboardService dashboardService})
    : _dashboardService = dashboardService;

  @override
  Future<DashboardDataModel> getDashboardData() async {
    final dashboardData = await _dashboardService.getDashboardData();
    return dashboardData;
  }
}
