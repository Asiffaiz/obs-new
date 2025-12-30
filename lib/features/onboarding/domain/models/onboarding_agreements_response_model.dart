import 'onboarding_signed_agreement_model.dart';
import 'onboarding_optional_agreement_model.dart';

class OnboardingAgreementsResponseModel {
  final List<OnboardingSignedAgreementModel> signedAgreements;
  final List<OnboardingOptionalAgreementModel> optionalAgreements;

  const OnboardingAgreementsResponseModel({
    required this.signedAgreements,
    required this.optionalAgreements,
  });

  factory OnboardingAgreementsResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    final signedAgreementsList = data['signed_agreements'] as List<dynamic>? ?? [];
    final optionalAgreementsList = data['optional_agreements'] as List<dynamic>? ?? [];

    return OnboardingAgreementsResponseModel(
      signedAgreements: signedAgreementsList
          .map((item) => OnboardingSignedAgreementModel.fromJson(
                item is Map ? Map<String, dynamic>.from(item) : {},
              ))
          .toList(),
      optionalAgreements: optionalAgreementsList
          .map((item) => OnboardingOptionalAgreementModel.fromJson(
                item is Map ? Map<String, dynamic>.from(item) : {},
              ))
          .toList(),
    );
  }
}

