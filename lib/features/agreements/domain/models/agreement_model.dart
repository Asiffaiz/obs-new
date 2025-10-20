import 'package:equatable/equatable.dart';

enum AgreementStatus { pending, signed, approved, rejected }



class AgreementModel extends Equatable {
  final int id;
  final String agreementAccountNo;
  final String title;
  final String description;
  final String type;
  final AgreementStatus status;
  final bool isMandatory;
  final String content; // HTML content
  final DateTime? signedDate;
  final DateTime? approvedDate;
  final DateTime? rejectedDate;
  final String? rejectionReason;
  final String? signatureUrl;
  final String? signerName;
  final String? signerEmail;
  final String? signerCity;
  final String? signerState;
  final String? signerZip;
  final String? signerCountry;
  final Map<String, dynamic> signatoryDetails;

  const AgreementModel({
    required this.id,
    required this.agreementAccountNo,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.isMandatory,
    required this.content,
    this.signedDate,
    this.approvedDate,
    this.rejectedDate,
    this.rejectionReason,
    this.signatureUrl,
    this.signerName,
    this.signerEmail,
    this.signerCity,
    this.signerState,
    this.signerZip,
    this.signerCountry,
    required this.signatoryDetails,
  });

  AgreementModel copyWith({
    int? id,
    String? agreementAccountNo,
    String? title,
    String? description,
    String? type,
    AgreementStatus? status,
    bool? isMandatory,
    String? content,
    DateTime? signedDate,
    DateTime? approvedDate,
    DateTime? rejectedDate,
    String? rejectionReason,
    String? signatureUrl,
    String? signerName,
    String? signerEmail,
    String? signerCity,
    String? signerState,
    String? signerZip,
    String? signerCountry,
    Map<String, dynamic>? signatoryDetails,
  }) {
    return AgreementModel(
      id: id ?? this.id,
      agreementAccountNo: agreementAccountNo ?? this.agreementAccountNo,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      isMandatory: isMandatory ?? this.isMandatory,
      content: content ?? this.content,
      signedDate: signedDate ?? this.signedDate,
      approvedDate: approvedDate ?? this.approvedDate,
      rejectedDate: rejectedDate ?? this.rejectedDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      signerName: signerName ?? this.signerName,
      signerEmail: signerEmail ?? this.signerEmail,
      signerCity: signerCity ?? this.signerCity,
      signerState: signerState ?? this.signerState,
      signerZip: signerZip ?? this.signerZip,
      signerCountry: signerCountry ?? this.signerCountry,
      signatoryDetails: signatoryDetails ?? this.signatoryDetails,
    );
  }

  @override
  List<Object?> get props => [
    id,
    agreementAccountNo,
    title,
    description,
    type,
    status,
    isMandatory,
    content,
    signedDate,
    approvedDate,
    rejectedDate,
    rejectionReason,
    signatureUrl,
    signerName,
    signerEmail,
    signerCity,
    signerState,
    signerZip,
    signerCountry,
    signatoryDetails,
  ];
}
