import 'package:voicealerts_obs/features/dashboard/domain/models/dashboard_data_model.dart';

abstract class DashboardRepository {
  /// Get all agreements for the current user
  Future<DashboardDataModel> getDashboardData();
}
