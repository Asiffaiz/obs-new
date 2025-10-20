import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:voicealerts_obs/features/dashboard/domain/models/dashboard_data_model.dart';
import 'package:voicealerts_obs/features/forms/domain/models/form_submission_model.dart';
import 'package:voicealerts_obs/features/forms/domain/repositories/form_repository.dart';
import 'package:voicealerts_obs/features/reports/domain/models/reports_model.dart';
import 'package:voicealerts_obs/features/reports/domain/repositories/reports_repository.dart';

part 'forms_event.dart';
part 'forms_state.dart';

class FormsBloc extends Bloc<FormsEvent, FormsState> {
  final FormsRepository _formsRepository;

  FormsBloc({required FormsRepository formsRepository})
    : _formsRepository = formsRepository,
      super(FormsInitial()) {
    on<LoadFormsData>(_onLoadFormsData);
    on<LoadClientAssignedForms>(_onLoadClientAssignedForms);
    on<LoadFormSubmissions>(_onLoadFormSubmissions);
  }

  Future<void> _onLoadFormsData(
    LoadFormsData event,
    Emitter<FormsState> emit,
  ) async {
    try {
      emit(FormsLoading());

      final formsData = await _formsRepository.getFormsData(
        event.formAccountNo,
        event.formToken,
      );

      emit(FormsLoaded(formsData: formsData));
    } catch (e) {
      emit(FormsError(errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadClientAssignedForms(
    LoadClientAssignedForms event,
    Emitter<FormsState> emit,
  ) async {
    try {
      emit(ClientAssignedFormsLoading());

      final formsData = await _formsRepository.getClientAssignedForms();
      final List<AssignedFormModel> assignedForms =
          formsData.map((form) => AssignedFormModel.fromJson(form)).toList();
      // print(assignedForms);
      emit(ClientAssignedFormsLoaded(clientAssignedForms: assignedForms));
    } catch (e) {
      emit(ClientAssignedFormsError(errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadFormSubmissions(
    LoadFormSubmissions event,
    Emitter<FormsState> emit,
  ) async {
    try {
      emit(FormSubmissionsLoading());

      final submissionsData = await _formsRepository.getFormSubmissions(
        event.formAccountNo,
      );
      final List<FormSubmissionModel> submissions =
          submissionsData
              .map((submission) => FormSubmissionModel.fromJson(submission))
              .toList();

      emit(FormSubmissionsLoaded(formSubmissions: submissions));
    } catch (e) {
      emit(FormSubmissionsError(errorMessage: e.toString()));
    }
  }
}
