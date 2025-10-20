class DocumentModel {
  final String documentTitle;
  final String documentFile;
  final DateTime addedOn;
  final bool allowDocumentSubmission;
  final bool? isApproved;
  final bool submissionSubmitted;
  final String? filePath;
  final int documentId;

  DocumentModel({
    required this.documentTitle,
    required this.documentFile,
    required this.addedOn,
    required this.allowDocumentSubmission,
    this.isApproved,
    required this.submissionSubmitted,
    this.filePath,
    required this.documentId,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      documentTitle: json['document_title'] ?? '',
      documentFile: json['document_file'] ?? '',
      addedOn:
          json['addedOn'] != null
              ? DateTime.parse(json['addedOn'])
              : DateTime.now(),
      allowDocumentSubmission: json['allow_document_submission'] == 'Yes' ,
      isApproved:
          json['is_approved'] != null ? json['is_approved'] == 'Yes' : null,
      submissionSubmitted: json['submission_submitted'] == 'Yes',
      filePath: json['file_path'],
      documentId: json['document_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document_title': documentTitle,
      'document_file': documentFile,
      'addedOn': addedOn.toIso8601String(),
      'allow_document_submission': allowDocumentSubmission ? 'Yes' : 'No',
      'is_approved': isApproved == null ? null : (isApproved! ? 'Yes' : 'No'),
      'submission_submitted': submissionSubmitted ? 'Yes' : 'No',
      'file_path': filePath,
      'document_id': documentId,
    };
  }
}
