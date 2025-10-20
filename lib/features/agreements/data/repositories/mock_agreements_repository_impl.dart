import 'package:voicealerts_obs/features/agreements/data/services/agreements_service.dart';
import 'package:voicealerts_obs/features/agreements/domain/models/archived_agreement_modal.dart';
import '../../domain/models/agreement_model.dart';
import '../../domain/models/signed_agreement_model.dart';
import '../../domain/repositories/agreements_repository.dart';

class MockAgreementsRepositoryImpl implements AgreementsRepository {
  final AgreementService _agreementsService;

  MockAgreementsRepositoryImpl({required AgreementService agreementsService})
    : _agreementsService = agreementsService;

  final List<AgreementModel> _agreements = [];

  @override
  Future<List<AgreementModel>> getAgreements() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _agreements;
  }

  // @override
  // Future<List<AgreementModel>> getMandatoryAgreements() async {
  //   // Simulate network delay
  //   await Future.delayed(const Duration(milliseconds: 800));
  //   return _agreements.where((agreement) => agreement.isMandatory).toList();
  // }

  @override
  Future<List<AgreementModel>> getMandatoryAgreements() async {
    return await _agreementsService.getMandatoryAgreements();
  }

  @override
  Future<List<ArchivedAgreementModel>> getArchivedAgreements() async {
    return await _agreementsService.getArchivedAgreements();
  }

  @override
  Future<List<AgreementModel>> getOptionalAgreements() async {
    return await _agreementsService.getOptionalAgreements();
  }

  @override
  Future<List<SignedAgreementModel>> getSignedAgreements() async {
    return await _agreementsService.getSignedAgreements();
  }

  @override
  Future<bool> areAllMandatoryAgreementsSigned() async {
    final mandatoryAgreements =
        await _agreementsService.getMandatoryAgreements();

    if (mandatoryAgreements.isEmpty) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> signAgreement(
    String agreementId,
    String signature,
    String signMethod, [
    Map<String, dynamic>? payload,
  ]) async {
    try {
      var success = false;
      // Try to use the real API if payload is provided
      if (payload != null) {
        success = await _agreementsService.signAgreement(
          agreementId,
          signature,
          signMethod,
          payload,
        );

        if (!success) {
          throw Exception('Failed to sign agreement');
        }
      } else {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      return success;
    } catch (e) {
      print(e);
      // If API call fails, still return a mock response
      return false;
    }
  }

  @override
  Future<AgreementModel?> getAgreementById(String agreementId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return _agreements.firstWhere(
      (agreement) => agreement.id == agreementId,
      orElse: () => throw Exception('Agreement not found'),
    );
  }

  @override
  Future<bool> sendToSignee(
    String agreementId,
    String name,
    String email,
    String? title,
    String? message,
  ) async {
    return await _agreementsService.sendToSignee(
      agreementId,
      name,
      email,
      title,
      message,
    );
  }

  @override
  Future<AgreementModel> acceptAgreement(String agreementId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _agreements.indexWhere(
      (agreement) => agreement.id == agreementId,
    );

    if (index == -1) {
      throw Exception('Agreement not found');
    }

    final updatedAgreement = _agreements[index].copyWith(
      status: AgreementStatus.signed,
      signedDate: DateTime.now(),
    );

    // Update the agreement in the list
    _agreements[index] = updatedAgreement;

    return updatedAgreement;
  }

  @override
  Future<AgreementModel> saveSignature(
    String agreementId,
    String signatureUrl,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _agreements.indexWhere(
      (agreement) => agreement.id == agreementId,
    );

    if (index == -1) {
      throw Exception('Agreement not found');
    }

    final updatedAgreement = _agreements[index].copyWith(
      status: AgreementStatus.signed,
      signedDate: DateTime.now(),
      signatureUrl: signatureUrl,
    );

    // Update the agreement in the list
    _agreements[index] = updatedAgreement;

    return updatedAgreement;
  }
}
