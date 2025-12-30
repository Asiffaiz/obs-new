import '../models/onboarding_agreements_response_model.dart';

abstract class OnboardingAgreementsRepository {
  /// Get all agreements (signed and optional) for onboarding
  Future<OnboardingAgreementsResponseModel> getOnboardingAgreements({
    required String accountNo,
    required String email,
  });
}

