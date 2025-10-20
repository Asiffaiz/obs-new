import 'package:voicealerts_obs/features/agreements/domain/models/archived_agreement_modal.dart';

import '../models/agreement_model.dart';
import '../models/signed_agreement_model.dart';

abstract class AgreementsRepository {
  /// Get all agreements for the current user
  Future<List<AgreementModel>> getAgreements();

  /// Get all archived agreements
  Future<List<ArchivedAgreementModel>> getArchivedAgreements();

  /// Get all mandatory agreements that need to be signed
  Future<List<AgreementModel>> getMandatoryAgreements();

  /// Get all optional agreements
  Future<List<AgreementModel>> getOptionalAgreements();

  /// Get all signed agreements
  Future<List<SignedAgreementModel>> getSignedAgreements();

  /// Check if all mandatory agreements are signed and approved
  Future<bool> areAllMandatoryAgreementsSigned();

  /// Sign an agreement
  Future<bool> signAgreement(
    String agreementId,
    String signature,
    String signMethod, [
    Map<String, dynamic>? payload,
  ]);



  /// Get an agreement by ID
  Future<AgreementModel?> getAgreementById(String agreementId);

  /// Send agreement to signee
  Future<bool> sendToSignee(
    String agreementId,
    String name,
    String email,
    String? title,
    String? message,
  );

  /// Accept agreement directly
  Future<AgreementModel> acceptAgreement(String agreementId);

  /// Save signature for agreement
  Future<AgreementModel> saveSignature(String agreementId, String signatureUrl);
}
