import 'package:voicealerts_obs/features/rfq/domain/models/rfq_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_submission_model.dart';

abstract class RfqRepository {
  /// Get RFQ submissions list
  Future<List<RfqSubmission>> getRfqSubmissions();

  /// Get RFQ form data
  Future<RfqFormDefinition> getRfqFormData();

  /// Submit RFQ form
  Future<bool> submitRfqForm({
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
  });

  /// Save RFQ form as draft
  Future<bool> saveRfqFormAsDraft({
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
  });
}

