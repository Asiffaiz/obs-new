import 'package:voicealerts_obs/features/rfq/data/services/rfq_service.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_submission_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/repositories/rfq_repository.dart';

class RfqRepositoryImpl implements RfqRepository {
  final RfqService _rfqService;

  RfqRepositoryImpl({required RfqService rfqService}) : _rfqService = rfqService;

  @override
  Future<List<RfqSubmission>> getRfqSubmissions() async {
    return await _rfqService.getRfqSubmissions();
  }

  @override
  Future<RfqFormDefinition> getRfqFormData() async {
    return await _rfqService.getRfqFormData();
  }

  @override
  Future<bool> submitRfqForm({
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
  }) async {
    return await _rfqService.submitRfqForm(
      answers: answers,
      currentStep: currentStep,
      totalSteps: totalSteps,
    );
  }

  @override
  Future<bool> saveRfqFormAsDraft({
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
  }) async {
    return await _rfqService.saveRfqFormAsDraft(
      answers: answers,
      currentStep: currentStep,
      totalSteps: totalSteps,
    );
  }
}

