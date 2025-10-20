import 'package:equatable/equatable.dart';

class FormSubmissionModel extends Equatable {
  final int id;
  final String submitterName;
  final String submitterEmail;
  final String? sentByEmail;
  final String? sentByAccountno;
  final int isSubmitted;
  final String sentOn;
  final String? submittedOn;
  final String? pdfName;
  final String extraFiles;
  final String formToken;
  final String? emailSubject;
  final String? emailContent;
  final String? submittedBy;
  final int submissionStatus;
  final int linkForm;
  final String? externalLink;
  final String formTitle;
  final String progress;
  final String? orderNo;

  const FormSubmissionModel({
    required this.id,
    required this.submitterName,
    required this.submitterEmail,
    this.sentByEmail,
    this.sentByAccountno,
    required this.isSubmitted,
    required this.sentOn,
    this.submittedOn,
    this.pdfName,
    required this.extraFiles,
    required this.formToken,
    this.emailSubject,
    this.emailContent,
    this.submittedBy,
    required this.submissionStatus,
    required this.linkForm,
    this.externalLink,
    required this.formTitle,
    required this.progress,
    this.orderNo,
  });

  factory FormSubmissionModel.fromJson(Map<String, dynamic> json) {
    return FormSubmissionModel(
      id: json['id'] ?? 0,
      submitterName: json['submitter_name'] ?? '',
      submitterEmail: json['submitter_email'] ?? '',
      sentByEmail: json['sent_by_email'],
      sentByAccountno: json['sent_by_accountno'],
      isSubmitted: json['is_submitted'] ?? 0,
      sentOn: json['sent_on'] ?? '',
      submittedOn: json['submitted_on'],
      pdfName: json['pdf_name'],
      extraFiles: json['extra_files'] ?? '[]',
      formToken: json['form_token'] ?? '',
      emailSubject: json['email_subject'],
      emailContent: json['email_content'],
      submittedBy: json['submitted_by'],
      submissionStatus: json['submission_status'] ?? 0,
      linkForm: json['link_form'] ?? 0,
      externalLink: json['external_link'],
      formTitle: json['form_title'] ?? '',
      progress: json['progress'] ?? '',
      orderNo: json['order_no'],
    );
  }

  bool get submitted => isSubmitted == 1;

  String get status {
    switch (submissionStatus) {
      case 1:
        return 'Completed';
      case 2:
        return 'In Progress';
      case 3:
        return 'Not Started';
      default:
        return 'Unknown';
    }
  }

  @override
  List<Object?> get props => [
    id,
    submitterName,
    submitterEmail,
    sentByEmail,
    sentByAccountno,
    isSubmitted,
    sentOn,
    submittedOn,
    pdfName,
    extraFiles,
    formToken,
    emailSubject,
    emailContent,
    submittedBy,
    submissionStatus,
    linkForm,
    externalLink,
    formTitle,
    progress,
    orderNo,
  ];
}
