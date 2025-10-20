part of 'reports_bloc.dart';

sealed class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object> get props => [];
}

class LoadReportsData extends ReportsEvent {}

class GetReportUrl extends ReportsEvent {
  final int reportId;

  const GetReportUrl({required this.reportId});

  @override
  List<Object> get props => [reportId];
}
