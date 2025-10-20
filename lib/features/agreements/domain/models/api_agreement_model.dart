import '../../domain/models/agreement_model.dart';

class ApiAgreementModel {
  final String agreementAccountNo;
  final String agreementTitle;
  final int agreementId;
  final bool isSigned;
  final bool isMandatory;
  final int seqNo;
  final String agreementType;
  final String agreementInstructions;
  final String agreementContent;
  final String signerCity;
  final String signerState;
  final String signerZip;
  final String signerCountry;
  final Map<String, dynamic> signatoryDetails;
  ApiAgreementModel({
    required this.agreementAccountNo,
    required this.agreementTitle,
    required this.agreementId,
    required this.isSigned,
    required this.isMandatory,
    required this.seqNo,
    required this.agreementType,
    required this.agreementInstructions,
    required this.agreementContent,
    required this.signerCity,
    required this.signerState,
    required this.signerZip,
    required this.signerCountry,
    required this.signatoryDetails,
  });

  factory ApiAgreementModel.fromJson(Map<String, dynamic> json) {
    return ApiAgreementModel(
      agreementAccountNo: json['agreement_accountno'] ?? '',
      agreementTitle: json['agreement_title'] ?? '',
      agreementId: json['agreement_id'] ?? '',
      isSigned: json['is_signed']?.toString().toLowerCase() == 'yes',
      isMandatory: json['is_mandatory']?.toString().toLowerCase() == 'yes',
      seqNo: int.tryParse(json['seqno']?.toString() ?? '0') ?? 0,
      agreementType: json['agreement_type'] ?? '',
      agreementInstructions: json['agreement_instructions'] ?? '',
      agreementContent: json['agreement_content'] ?? '',
      signatoryDetails: json['signatory_details'][0] ?? {},
      signerCity: json['city'] ?? '',
      signerState: json['state'] ?? '',
      signerZip: json['zip'] ?? '',
      signerCountry: json['country'] ?? '',
    );
  }

  // Convert API model to domain model
  AgreementModel toDomainModel() {
    // Map agreement type string to enum

    // Map signed status to enum
    AgreementStatus status =
        isSigned ? AgreementStatus.signed : AgreementStatus.pending;

    return AgreementModel(
      id: agreementId,
      agreementAccountNo: agreementAccountNo,
      title: agreementTitle,
      description: agreementInstructions,
      type: agreementType,
      status: status,
      isMandatory: isMandatory,
      content: agreementContent,
      signerCity: signerCity,
      signerState: signerState,
      signerZip: signerZip,
      signerCountry: signerCountry,
      signatoryDetails: signatoryDetails,
    );
  }
}
