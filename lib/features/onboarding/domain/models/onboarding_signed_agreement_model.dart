import 'package:equatable/equatable.dart';

class OnboardingSignedAgreementModel extends Equatable {
  final String title;
  final String signeeName;
  final String? signeeTitle;
  final String signeeEmail;
  final DateTime? signedDate;
  final bool isSigned;
  final bool isApproved;
  final bool isMandatory;
  final String pdfPath;

  const OnboardingSignedAgreementModel({
    required this.title,
    required this.signeeName,
    this.signeeTitle,
    required this.signeeEmail,
    this.signedDate,
    required this.isSigned,
    required this.isApproved,
    required this.isMandatory,
    required this.pdfPath,
  });

  factory OnboardingSignedAgreementModel.fromJson(Map<String, dynamic> json) {
    return OnboardingSignedAgreementModel(
      title: json['agreement_title']?.toString() ?? '',
      signeeName: json['signee_name']?.toString() ?? '',
      signeeTitle: json['signee_title']?.toString(),
      signeeEmail: json['signee_email']?.toString() ?? '',
      signedDate: json['signed_date'] != null
          ? DateTime.tryParse(json['signed_date'].toString())
          : null,
      isSigned: json['is_signed']?.toString().toLowerCase() == 'yes',
      isApproved: json['approved']?.toString().toLowerCase() == 'yes',
      isMandatory: json['is_mandatory']?.toString().toLowerCase() == 'yes',
      pdfPath: json['msa_pdf_path']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        title,
        signeeName,
        signeeTitle,
        signeeEmail,
        signedDate,
        isSigned,
        isApproved,
        isMandatory,
        pdfPath,
      ];
}

