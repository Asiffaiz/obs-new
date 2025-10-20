import 'package:voicealerts_obs/features/forms/data/services/form_service.dart';
import 'package:voicealerts_obs/features/forms/domain/repositories/form_repository.dart';

class FormsRepositoryImpl extends FormsRepository {
  final FormsService _formsService;

  FormsRepositoryImpl({required FormsService formsService})
    : _formsService = formsService;

  @override
  Future<List<dynamic>> getFormsData(
    String formAccountNo,
    String formToken,
  ) async {
    return await _formsService.getFormsData(formAccountNo, formToken);
  }

  @override
  Future<List<dynamic>> getClientAssignedForms() async {
    return await _formsService.getClientAssignedForms();
  }

  @override
  Future<List<dynamic>> getFormSubmissions(String formAccountNo) async {
    return await _formsService.getFormSubmissions(formAccountNo);
  }
}
