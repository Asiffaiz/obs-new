import 'package:voicealerts_obs/features/dashboard/domain/models/dashboard_data_model.dart';
import 'package:voicealerts_obs/features/reports/domain/models/reports_model.dart';

abstract class ReportsRepository {
  /// Get all agreements for the current user
  Future<List<ReportsModel>> getReportsData();

  /// Get authenticated URL for viewing a report
  Future<Map<String, String>> getReportUrl(int reportId);
}
