import 'package:equatable/equatable.dart';
import 'package:voicealerts_obs/features/agreements/domain/models/archived_agreement_modal.dart';
import 'package:voicealerts_obs/features/onboarding/domain/models/onboarding_signed_agreement_model.dart';
import 'package:voicealerts_obs/features/onboarding/domain/models/onboarding_optional_agreement_model.dart';
import '../../domain/models/agreement_model.dart';
import '../../domain/models/signed_agreement_model.dart';

enum AgreementsStatus {
  initial,
  loading,
  loaded,
  error,
  signing,
  signed,
  sendingToSignee,
  sentToSignee,
  acceptingAgreement,
  acceptedAgreement,
  savingSignature,
  savingSignatureError,
  savedSignature,
  showNextAgreement,
  loadingSignedAgreements,
  loadedSignedAgreements,
  loadingOptionalAgreements,
  loadedOptionalAgreements,
  loadingArchivedAgreements,
  loadedArchivedAgreements,
  loadingAllAgreements,
  loadedAllAgreements,
}

enum AgreementViewMode { list, detail, sign, sendToSignee }

class AgreementsState extends Equatable {
  final AgreementsStatus status;
  final List<AgreementModel> agreements;
  final List<SignedAgreementModel> signedAgreements;
  final List<ArchivedAgreementModel> archivedAgreements;
  final List<OnboardingSignedAgreementModel> allSignedAgreements;
  final List<OnboardingOptionalAgreementModel> allOptionalAgreements;
  final String? errorMessage;
  final int currentAgreementIndex;
  final bool allMandatoryAgreementsSigned;
  final AgreementViewMode viewMode;
  final String? signatureUrl;

  const AgreementsState({
    this.status = AgreementsStatus.initial,
    this.agreements = const [],
    this.signedAgreements = const [],
    this.archivedAgreements = const [],
    this.allSignedAgreements = const [],
    this.allOptionalAgreements = const [],
    this.errorMessage,
    this.currentAgreementIndex = 0,
    this.allMandatoryAgreementsSigned = false,
    this.viewMode = AgreementViewMode.list,
    this.signatureUrl,
  });

  AgreementsState copyWith({
    AgreementsStatus? status,
    List<AgreementModel>? agreements,
    List<SignedAgreementModel>? signedAgreements,
    List<ArchivedAgreementModel>? archivedAgreements,
    List<OnboardingSignedAgreementModel>? allSignedAgreements,
    List<OnboardingOptionalAgreementModel>? allOptionalAgreements,
    String? errorMessage,
    int? currentAgreementIndex,
    bool? allMandatoryAgreementsSigned,
    AgreementViewMode? viewMode,
    String? signatureUrl,
  }) {
    return AgreementsState(
      status: status ?? this.status,
      agreements: agreements ?? this.agreements,
      signedAgreements: signedAgreements ?? this.signedAgreements,
      archivedAgreements: archivedAgreements ?? this.archivedAgreements,
      allSignedAgreements: allSignedAgreements ?? this.allSignedAgreements,
      allOptionalAgreements: allOptionalAgreements ?? this.allOptionalAgreements,
      errorMessage: errorMessage,
      currentAgreementIndex:
          currentAgreementIndex ?? this.currentAgreementIndex,
      allMandatoryAgreementsSigned:
          allMandatoryAgreementsSigned ?? this.allMandatoryAgreementsSigned,
      viewMode: viewMode ?? this.viewMode,
      signatureUrl: signatureUrl ?? this.signatureUrl,
    );
  }

  AgreementModel? get currentAgreement {
    if (agreements.isEmpty || currentAgreementIndex >= agreements.length) {
      return null;
    }
    return agreements[currentAgreementIndex];
  }

  bool get hasNextAgreement => currentAgreementIndex < agreements.length - 1;
  bool get hasPreviousAgreement => currentAgreementIndex > 0;

  @override
  List<Object?> get props => [
    status,
    agreements,
    signedAgreements,
    archivedAgreements,
    allSignedAgreements,
    allOptionalAgreements,
    errorMessage,
    currentAgreementIndex,
    allMandatoryAgreementsSigned,
    viewMode,
    signatureUrl,
  ];
}
