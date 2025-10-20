part of 'forms_bloc.dart';

sealed class FormsEvent extends Equatable {
  const FormsEvent();

  @override
  List<Object> get props => [];
}

class LoadFormsData extends FormsEvent {
  final String formAccountNo;
  final String formToken;
  const LoadFormsData({required this.formAccountNo, required this.formToken});

  @override
  List<Object> get props => [formAccountNo, formToken];
}

class LoadClientAssignedForms extends FormsEvent {
  const LoadClientAssignedForms();

  @override
  List<Object> get props => [];
}

class LoadFormSubmissions extends FormsEvent {
  final String formAccountNo;
  const LoadFormSubmissions({required this.formAccountNo});

  @override
  List<Object> get props => [formAccountNo];
}
