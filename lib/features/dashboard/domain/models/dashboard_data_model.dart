import 'package:equatable/equatable.dart';

class DashboardDataModel extends Equatable {
  final AgreementsSummaryModel agreementSummary;
  final List<AssignedFormModel> assignedForms;
  final String welcomeContent;

  const DashboardDataModel({
    required this.agreementSummary,
    required this.assignedForms,
    required this.welcomeContent,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    return DashboardDataModel(
      agreementSummary: AgreementsSummaryModel.fromJson(
        (json['agreement_data'] as List).isNotEmpty
            ? json['agreement_data'][0]
            : {},
      ),
      assignedForms:
          (json['assigned_forms'] as List<dynamic>?)
              ?.map((item) => AssignedFormModel.fromJson(item))
              .toList() ??
          [],
      welcomeContent: json['welcome_content'] ?? '',
    );
  }

  @override
  List<Object?> get props => [agreementSummary, assignedForms];
}

class AgreementsSummaryModel extends Equatable {
  final int totalAgreements;
  final int totalSigned;
  final int totalNotSigned;

  const AgreementsSummaryModel({
    required this.totalAgreements,
    required this.totalSigned,
    required this.totalNotSigned,
  });

  factory AgreementsSummaryModel.fromJson(Map<String, dynamic> json) {
    return AgreementsSummaryModel(
      totalAgreements: json['total_agreements'] ?? 0,
      totalSigned: json['total_signed'] ?? 0,
      totalNotSigned: json['total_not_signed'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalAgreements, totalSigned, totalNotSigned];
}

class AssignedFormModel extends Equatable {
  final String formAccountno;
  final String formTitle;
  final String formDesc;
  final int allowMultiple;
  final String btnText;
  final String isFilled;
  final String filledDate;
  final String formLink;
  final int linkForm;
  final String externalLink;

  const AssignedFormModel({
    required this.formAccountno,
    required this.formTitle,
    required this.formDesc,
    required this.allowMultiple,
    required this.btnText,
    required this.isFilled,
    required this.filledDate,
    required this.formLink,
    required this.linkForm,
    required this.externalLink,
  });

  factory AssignedFormModel.fromJson(Map<String, dynamic> json) {
    return AssignedFormModel(
      formAccountno: json['form_accountno'] ?? '',
      formTitle: json['form_title'] ?? '',
      formDesc: json['form_desc'] ?? '',
      allowMultiple: json['allow_multiple'] ?? 0,
      btnText: json['btn_text'] ?? '',
      isFilled: json['is_filled'] ?? '',
      filledDate: json['filled_date'] ?? '',
      formLink: json['form_link'] ?? '',
      linkForm: json['link_form'] ?? 0,
      externalLink: json['external_link'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    formAccountno,
    formTitle,
    formDesc,
    allowMultiple,
    btnText,
    isFilled,
    filledDate,
    formLink,
    linkForm,
    externalLink,
  ];
}
