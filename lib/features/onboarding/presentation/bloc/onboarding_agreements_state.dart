import 'package:equatable/equatable.dart';
import '../../domain/models/onboarding_signed_agreement_model.dart';
import '../../domain/models/onboarding_optional_agreement_model.dart';

enum OnboardingAgreementsStatus {
  initial,
  loading,
  loaded,
  error,
}

class OnboardingAgreementsState extends Equatable {
  final OnboardingAgreementsStatus status;
  final List<OnboardingSignedAgreementModel> signedAgreements;
  final List<OnboardingOptionalAgreementModel> optionalAgreements;
  final String? errorMessage;

  const OnboardingAgreementsState({
    this.status = OnboardingAgreementsStatus.initial,
    this.signedAgreements = const [],
    this.optionalAgreements = const [],
    this.errorMessage,
  });

  OnboardingAgreementsState copyWith({
    OnboardingAgreementsStatus? status,
    List<OnboardingSignedAgreementModel>? signedAgreements,
    List<OnboardingOptionalAgreementModel>? optionalAgreements,
    String? errorMessage,
  }) {
    return OnboardingAgreementsState(
      status: status ?? this.status,
      signedAgreements: signedAgreements ?? this.signedAgreements,
      optionalAgreements: optionalAgreements ?? this.optionalAgreements,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        signedAgreements,
        optionalAgreements,
        errorMessage,
      ];
}

