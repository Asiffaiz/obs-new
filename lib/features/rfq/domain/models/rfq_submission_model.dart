/// Model for RFQ submission listing
class RfqSubmission {
  final int id;
  final String submissionId;
  final String status;
  final DateTime submittedAt;
  final DateTime? updatedAt;
  final String? title;
  final int totalSteps;
  final int completedSteps;
  final Map<String, dynamic>? answers;

  RfqSubmission({
    required this.id,
    required this.submissionId,
    required this.status,
    required this.submittedAt,
    this.updatedAt,
    this.title,
    required this.totalSteps,
    required this.completedSteps,
    this.answers,
  });

  factory RfqSubmission.fromJson(Map<String, dynamic> json) {
    return RfqSubmission(
      id: json['id'] as int? ?? 0,
      submissionId: (json['submission_id'] ?? '').toString(),
      status: (json['status'] ?? 'draft').toString(),
      submittedAt: DateTime.tryParse(json['submitted_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      title: json['title']?.toString(),
      totalSteps: json['total_steps'] as int? ?? 0,
      completedSteps: json['completed_steps'] as int? ?? 0,
      answers: json['answers'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'submission_id': submissionId,
        'status': status,
        'submitted_at': submittedAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'title': title,
        'total_steps': totalSteps,
        'completed_steps': completedSteps,
        'answers': answers,
      };

  /// Check if the submission is a draft
  bool get isDraft => status.toLowerCase() == 'draft';

  /// Check if the submission is completed
  bool get isCompleted => status.toLowerCase() == 'completed' || status.toLowerCase() == 'submitted';

  /// Get progress percentage
  double get progressPercentage {
    if (totalSteps == 0) return 0;
    return (completedSteps / totalSteps) * 100;
  }

  /// Get display status
  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'submitted':
      case 'completed':
        return 'Submitted';
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}

