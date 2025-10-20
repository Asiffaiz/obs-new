part of 'reports_bloc.dart';

sealed class ReportsState extends Equatable {
  final List<ReportsModel> reportsData;

  const ReportsState({this.reportsData = const []});

  @override
  List<Object> get props => [reportsData];
}

final class ReportsInitial extends ReportsState {
  const ReportsInitial() : super();
}

final class ReportsLoading extends ReportsState {
  const ReportsLoading({super.reportsData});
}

final class ReportsLoaded extends ReportsState {
  const ReportsLoaded({required super.reportsData});
}

final class ReportsError extends ReportsState {
  final String errorMessage;

  const ReportsError({required this.errorMessage, super.reportsData});

  @override
  List<Object> get props => [errorMessage, reportsData];
}

final class ReportUrlLoading extends ReportsState {
  const ReportUrlLoading({required super.reportsData});
}

final class ReportUrlLoaded extends ReportsState {
  final String url;
  final String title;

  const ReportUrlLoaded({
    required this.url,
    required this.title,
    required super.reportsData,
  });

  @override
  List<Object> get props => [url, title, reportsData];
}

final class ReportUrlError extends ReportsState {
  final String errorMessage;

  const ReportUrlError({
    required this.errorMessage,
    required super.reportsData,
  });

  @override
  List<Object> get props => [errorMessage, reportsData];
}
