import 'package:equatable/equatable.dart';

class SignedAgreementModel extends Equatable {
  final String title;
  final String signeeName;
  final String signeeTitle;
  final String signeeEmail;
  final DateTime signedDate;
  final bool isSigned;
  final bool isApproved;
  final bool isMandatory;
  final String pdfPath;

  const SignedAgreementModel({
    required this.title,
    required this.signeeName,
    required this.signeeTitle,
    required this.signeeEmail,
    required this.signedDate,
    required this.isSigned,
    required this.isApproved,
    required this.isMandatory,
    required this.pdfPath,
  });

  factory SignedAgreementModel.fromJson(Map<String, dynamic> json) {
    return SignedAgreementModel(
      title: json['agreement_title'] ?? '',
      signeeName: json['signee_name'] ?? '',
      signeeTitle: json['signee_title'] ?? '',
      signeeEmail: json['signee_email'] ?? '',
      signedDate:
          DateTime.tryParse(json['signed_date'] ?? '') ?? DateTime.now(),
      isSigned: json['is_signed']?.toString().toLowerCase() == 'yes',
      isApproved: json['approved']?.toString().toLowerCase() == 'yes',
      isMandatory: json['is_mandatory']?.toString().toLowerCase() == 'yes',
      pdfPath: json['msa_pdf_path'] ?? '',
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
