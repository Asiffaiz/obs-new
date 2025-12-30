import 'package:equatable/equatable.dart';

class OnboardingOptionalAgreementModel extends Equatable {
  final String agreementAccountNo;
  final int agreementId;
  final String title;
  final bool isSigned;
  final bool isMandatory;
  final int seqNo;
  final String agreementType;
  final String agreementInstructions;
  final String agreementContent;
  final List<Map<String, dynamic>> signatoryDetails;

  const OnboardingOptionalAgreementModel({
    required this.agreementAccountNo,
    required this.agreementId,
    required this.title,
    required this.isSigned,
    required this.isMandatory,
    required this.seqNo,
    required this.agreementType,
    required this.agreementInstructions,
    required this.agreementContent,
    required this.signatoryDetails,
  });

  factory OnboardingOptionalAgreementModel.fromJson(Map<String, dynamic> json) {
    return OnboardingOptionalAgreementModel(
      agreementAccountNo: json['agreement_accountno']?.toString() ?? '',
      agreementId: int.tryParse(json['agreement_id']?.toString() ?? '0') ?? 0,
      title: json['agreement_title']?.toString() ?? '',
      isSigned: json['is_signed']?.toString().toLowerCase() == 'yes',
      isMandatory: json['is_mandatory']?.toString().toLowerCase() == 'yes',
      seqNo: int.tryParse(json['seqno']?.toString() ?? '0') ?? 0,
      agreementType: json['agreement_type']?.toString() ?? '',
      agreementInstructions: json['agreement_instructions']?.toString() ?? '',
      agreementContent: json['agreement_content']?.toString() ?? '',
      signatoryDetails: json['signatory_details'] != null
          ? List<Map<String, dynamic>>.from(
              (json['signatory_details'] as List)
                  .map((item) => item is Map ? Map<String, dynamic>.from(item) : {}),
            )
          : [],
    );
  }

  @override
  List<Object?> get props => [
        agreementAccountNo,
        agreementId,
        title,
        isSigned,
        isMandatory,
        seqNo,
        agreementType,
        agreementInstructions,
        agreementContent,
        signatoryDetails,
      ];
}

