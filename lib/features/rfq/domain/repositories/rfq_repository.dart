import 'package:voicealerts_obs/features/rfq/domain/models/rfq_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_product_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_submission_model.dart';

abstract class RfqRepository {
  /// Get RFQ submissions list
  Future<List<RfqSubmission>> getRfqSubmissions();

  /// Get RFQ form data
  Future<RfqFormDefinition> getRfqFormData();

  /// Submit RFQ form
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
  });

  /// Save RFQ form as draft
  Future<bool> saveRfqFormAsDraft({
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
    List<int>? selectedProductIds,
    String? requirementDescription,
    String? attachmentFile,
  });
}

