part of 'rfq_submissions_bloc.dart';

sealed class RfqSubmissionsEvent extends Equatable {
  const RfqSubmissionsEvent();

  @override
  List<Object?> get props => [];
}

/// Load RFQ submissions
class LoadRfqSubmissions extends RfqSubmissionsEvent {
  const LoadRfqSubmissions();
}

/// Refresh RFQ submissions
class RefreshRfqSubmissions extends RfqSubmissionsEvent {
  const RefreshRfqSubmissions();
}

