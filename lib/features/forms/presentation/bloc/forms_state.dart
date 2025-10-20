part of 'forms_bloc.dart';

sealed class FormsState extends Equatable {
  const FormsState();

  @override
  List<Object> get props => [];
}

final class FormsInitial extends FormsState {}

final class FormsLoading extends FormsState {}

final class FormsLoaded extends FormsState {
  final List<dynamic> formsData;

  const FormsLoaded({required this.formsData});

  @override
  List<Object> get props => [formsData];
}

final class FormsError extends FormsState {
  final String errorMessage;

  const FormsError({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}

final class ClientAssignedFormsInitial extends FormsState {}

final class ClientAssignedFormsLoading extends FormsState {}

final class ClientAssignedFormsLoaded extends FormsState {
  final List<AssignedFormModel> clientAssignedForms;

  const ClientAssignedFormsLoaded({required this.clientAssignedForms});

  @override
  List<Object> get props => [clientAssignedForms];
}

final class ClientAssignedFormsError extends FormsState {
  final String errorMessage;

  const ClientAssignedFormsError({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}

final class FormSubmissionsLoading extends FormsState {}

final class FormSubmissionsLoaded extends FormsState {
  final List<FormSubmissionModel> formSubmissions;

  const FormSubmissionsLoaded({required this.formSubmissions});

  @override
  List<Object> get props => [formSubmissions];
}

final class FormSubmissionsError extends FormsState {
  final String errorMessage;

  const FormSubmissionsError({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}
