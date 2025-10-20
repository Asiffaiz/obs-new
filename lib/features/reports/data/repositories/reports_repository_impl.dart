import 'package:voicealerts_obs/features/reports/data/services/reports_service.dart';
import 'package:voicealerts_obs/features/reports/domain/models/reports_model.dart';
import 'package:voicealerts_obs/features/reports/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl extends ReportsRepository {
  final ReportsService _reportsService;

  ReportsRepositoryImpl({required ReportsService reportsService})
    : _reportsService = reportsService;

  @override
  Future<List<ReportsModel>> getReportsData() async {
    final reportsData = await _reportsService.getReportsData();
    return reportsData;
  }

  @override
  Future<Map<String, String>> getReportUrl(int reportId) async {
    final urlData = await _reportsService.getReportUrl(reportId);
    return urlData;
  }
}
