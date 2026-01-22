import 'package:voicealerts_obs/features/rfq/data/services/rfq_service.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_product_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_submission_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/repositories/rfq_repository.dart';

class RfqRepositoryImpl implements RfqRepository {
  final RfqService _rfqService;

  RfqRepositoryImpl({required RfqService rfqService})
    : _rfqService = rfqService;

  @override
  Future<List<RfqSubmission>> getRfqSubmissions() async {
    return await _rfqService.getRfqSubmissions();
  }

  @override
  Future<RfqFormDefinition> getRfqFormData() async {
    return await _rfqService.getRfqFormData();
  }

  @override
  Future<Map<String, dynamic>> getRfqFormDataForEdit(
    String rfqAccountNo,
  ) async {
    return await _rfqService.getRfqFormDataForEdit(rfqAccountNo);
  }

  @override
  Future<bool> submitRfqForm({
    required RfqFormDefinition formDefinition,
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
    required List<int> selectedProductIds,
    required List<RfqProduct> allProducts,
    String? requirementDescription,
    String? attachmentFile,
    String? fileName,
  }) async {
    return await _rfqService.submitRfqForm(
      formDefinition: formDefinition,
      answers: answers,
      currentStep: currentStep,
      totalSteps: totalSteps,
      selectedProductIds: selectedProductIds,
      allProducts: allProducts,
      requirementDescription: requirementDescription,
      attachmentFile: attachmentFile,
      fileName: fileName,
    );
  }

  @override
  Future<bool> updateRfqForm({
    required String rfqAccountNo,
    required RfqFormDefinition formDefinition,
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
    required List<int> selectedProductIds,
    required List<RfqProduct> allProducts,
    String? requirementDescription,
    String? attachmentFile,
    String? fileName,
  }) async {
    return await _rfqService.updateRfqForm(
      rfqAccountNo: rfqAccountNo,
      formDefinition: formDefinition,
      answers: answers,
      currentStep: currentStep,
      totalSteps: totalSteps,
      selectedProductIds: selectedProductIds,
      allProducts: allProducts,
      requirementDescription: requirementDescription,
      attachmentFile: attachmentFile,
      fileName: fileName,
    );
  }

  @override
  Future<bool> saveRfqFormAsDraft({
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
    List<int>? selectedProductIds,
    String? requirementDescription,
    String? attachmentFile,
  }) async {
    return await _rfqService.saveRfqFormAsDraft(
      answers: answers,
      currentStep: currentStep,
      totalSteps: totalSteps,
      selectedProductIds: selectedProductIds,
      requirementDescription: requirementDescription,
      attachmentFile: attachmentFile,
    );
  }
}
