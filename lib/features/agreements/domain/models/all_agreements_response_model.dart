import 'package:voicealerts_obs/features/onboarding/domain/models/onboarding_signed_agreement_model.dart';
import 'package:voicealerts_obs/features/onboarding/domain/models/onboarding_optional_agreement_model.dart';

class AllAgreementsResponseModel {
  final List<OnboardingSignedAgreementModel> signedAgreements;
  final List<OnboardingOptionalAgreementModel> optionalAgreements;

  const AllAgreementsResponseModel({
    required this.signedAgreements,
    required this.optionalAgreements,
  });

  factory AllAgreementsResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    final signedAgreementsList =
        data['signed_agreements'] as List<dynamic>? ?? [];
    final optionalAgreementsList =
        data['optional_agreements'] as List<dynamic>? ?? [];

    return AllAgreementsResponseModel(
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

