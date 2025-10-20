import 'package:equatable/equatable.dart';

class ArchivedAgreementModel extends Equatable {
  final String title;
  final DateTime revokeDate;
  final DateTime signedDate;
  final bool isSigned;
  final String revokeReason;
  final String agreementPath;

  const ArchivedAgreementModel({
    required this.title,
    required this.revokeDate,
    required this.signedDate,
    required this.isSigned,
    required this.revokeReason,
    required this.agreementPath,
  });

  factory ArchivedAgreementModel.fromJson(Map<String, dynamic> json) {
    return ArchivedAgreementModel(
      title: json['agreement_title'] ?? '',
      signedDate:
          DateTime.tryParse(json['signed_date'] ?? '') ?? DateTime.now(),
      revokeDate:
          DateTime.tryParse(json['revoke_date'] ?? '') ?? DateTime.now(),
      isSigned: json['is_signed']?.toString().toLowerCase() == 'yes',
      revokeReason: json['revoke_reason'] ?? '',
      agreementPath: json['agreement_path'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    title,
    signedDate,
    isSigned,
    revokeDate,
    revokeReason,
    agreementPath,
  ];
}
