import 'package:equatable/equatable.dart';

abstract class AgreementsEvent extends Equatable {
  const AgreementsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAgreements extends AgreementsEvent {
  const LoadAgreements();
}

class LoadSignedAgreements extends AgreementsEvent {
  const LoadSignedAgreements();
}

class LoadArchivedAgreements extends AgreementsEvent {
  const LoadArchivedAgreements();
}

class LoadOptionalAgreements extends AgreementsEvent {
  const LoadOptionalAgreements();
}

class SignAgreement extends AgreementsEvent {
  final String agreementId;
  final String signature;
  final String signMethod;
  final Map<String, dynamic>? payload;
  const SignAgreement({
    required this.agreementId,
    required this.signature,
    required this.signMethod,
    required this.payload,
  });

  @override
  List<Object?> get props => [agreementId, signature, signMethod, payload];
}

class NextAgreement extends AgreementsEvent {
  const NextAgreement();
}

class PreviousAgreement extends AgreementsEvent {
  const PreviousAgreement();
}

class GoToAgreement extends AgreementsEvent {
  final int index;

  const GoToAgreement(this.index);

  @override
  List<Object?> get props => [index];
}

class CheckMandatoryAgreements extends AgreementsEvent {
  const CheckMandatoryAgreements();
}

class SendToSignee extends AgreementsEvent {
  final String agreementId;
  final String name;
  final String email;
  final String? title;
  final String? message;

  const SendToSignee({
    required this.agreementId,
    required this.name,
    required this.email,
    this.title,
    this.message,
  });

  @override
  List<Object?> get props => [agreementId, name, email, title, message];
}

class AcceptAgreement extends AgreementsEvent {
  final String agreementId;

  const AcceptAgreement({required this.agreementId});

  @override
  List<Object?> get props => [agreementId];
}

class SaveSignature extends AgreementsEvent {
  final String agreementId;
  final String signatureUrl;
  final String signMethod;
  final Map<String, dynamic>? payload;

  const SaveSignature({
    required this.agreementId,
    required this.signatureUrl,
    required this.signMethod,
    this.payload,
  });

  @override
  List<Object?> get props => [agreementId, signatureUrl, signMethod, payload];
}

class SaveOptionalSignature extends AgreementsEvent {
  final String agreementId;
  final String signatureUrl;
  final String signMethod;
  final Map<String, dynamic>? payload;

  const SaveOptionalSignature({
    required this.agreementId,
    required this.signatureUrl,
    required this.signMethod,
    this.payload,
  });

  @override
  List<Object?> get props => [agreementId, signatureUrl, signMethod, payload];
}
