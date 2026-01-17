part of 'rfq_submissions_bloc.dart';

enum RfqSubmissionsStatus {
  initial,
  loading,
  loaded,
  error,
}

class RfqSubmissionsState extends Equatable {
  final RfqSubmissionsStatus status;
  final List<RfqSubmission> submissions;
  final String? errorMessage;

  const RfqSubmissionsState({
    this.status = RfqSubmissionsStatus.initial,
    this.submissions = const [],
    this.errorMessage,
  });

  RfqSubmissionsState copyWith({
    RfqSubmissionsStatus? status,
    List<RfqSubmission>? submissions,
    String? errorMessage,
  }) {
    return RfqSubmissionsState(
      status: status ?? this.status,
      submissions: submissions ?? this.submissions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Get drafts
  List<RfqSubmission> get drafts =>
      submissions.where((s) => s.isDraft).toList();

  /// Get submitted RFQs
  List<RfqSubmission> get submitted =>
      submissions.where((s) => !s.isDraft).toList();

  @override
  List<Object?> get props => [status, submissions, errorMessage];
}

