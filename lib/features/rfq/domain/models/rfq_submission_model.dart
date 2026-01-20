/// Model for RFQ submission listing
class RfqSubmission {
  final String rfqAccountNo;
  final DateTime createdAt;
  final String? rfqAttachment;
  final String status;
  final DateTime? dateUpdated;

  RfqSubmission({
    required this.rfqAccountNo,
    required this.createdAt,
    this.rfqAttachment,
    required this.status,
    this.dateUpdated,
  });

  factory RfqSubmission.fromJson(Map<String, dynamic> json) {
    return RfqSubmission(
      rfqAccountNo: (json['rfq_accountno'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      rfqAttachment: json['rfq_attachement']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      dateUpdated:
          json['dateUpdated'] != null
              ? DateTime.tryParse(json['dateUpdated'])
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'rfq_accountno': rfqAccountNo,
    'createdAt': createdAt.toIso8601String(),
    'rfq_attachement': rfqAttachment,
    'status': status,
    'dateUpdated': dateUpdated?.toIso8601String(),
  };

  /// Check if attachment exists
  bool get hasAttachment => rfqAttachment != null && rfqAttachment!.isNotEmpty;

  /// Get display status
  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'submitted':
      case 'completed':
        return 'Completed';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
