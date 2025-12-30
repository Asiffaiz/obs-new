import '../../domain/models/onboarding_agreements_response_model.dart';
import '../../domain/repositories/onboarding_agreements_repository.dart';
import '../services/onboarding_agreements_service.dart';

class OnboardingAgreementsRepositoryImpl
    implements OnboardingAgreementsRepository {
  final OnboardingAgreementsService _service;

  OnboardingAgreementsRepositoryImpl(this._service);

  @override
  Future<OnboardingAgreementsResponseModel> getOnboardingAgreements({
    required String accountNo,
    required String email,
  }) async {
    return await _service.getOnboardingAgreements(
      accountNo: accountNo,
      email: email,
    );
  }
}

