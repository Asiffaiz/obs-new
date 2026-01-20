import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:voicealerts_obs/features/rfq/data/services/rfq_service.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/repositories/rfq_repository.dart';

part 'rfq_event.dart';
part 'rfq_state.dart';

class RfqBloc extends Bloc<RfqEvent, RfqState> {
  final RfqRepository _rfqRepository;

  RfqBloc({required RfqRepository rfqRepository})
    : _rfqRepository = rfqRepository,
      super(const RfqState()) {
    on<LoadRfqFormData>(_onLoadRfqFormData);
    on<UpdateCurrentStep>(_onUpdateCurrentStep);
    on<UpdateAnswer>(_onUpdateAnswer);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<SubmitRfqForm>(_onSubmitRfqForm);
    on<SaveRfqFormAsDraft>(_onSaveRfqFormAsDraft);
    on<ValidateCurrentStep>(_onValidateCurrentStep);
    on<AddProduct>(_onAddProduct);
    on<RemoveProduct>(_onRemoveProduct);
    on<UpdateRequirementDescription>(_onUpdateRequirementDescription);
    on<UpdateAttachmentFile>(_onUpdateAttachmentFile);
  }

  Future<void> _onLoadRfqFormData(
    LoadRfqFormData event,
    Emitter<RfqState> emit,
  ) async {
    emit(state.copyWith(status: RfqFormStatus.loading));

    try {
      final formDefinition = await _rfqRepository.getRfqFormData();
      emit(
        state.copyWith(
          status: RfqFormStatus.loaded,
          formDefinition: formDefinition,
          currentStep: 0,
          answers: {},
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: RfqFormStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void _onUpdateCurrentStep(UpdateCurrentStep event, Emitter<RfqState> emit) {
    emit(state.copyWith(currentStep: event.step));
  }

  void _onUpdateAnswer(UpdateAnswer event, Emitter<RfqState> emit) {
    final updatedAnswers = Map<String, dynamic>.from(state.answers);
    updatedAnswers[event.questionId] = event.answer;
    emit(state.copyWith(answers: updatedAnswers));
  }

  Future<void> _onNextStep(NextStep event, Emitter<RfqState> emit) async {
    if (state.formDefinition == null) return;

    final orderedGroups = state.formDefinition!.orderedGroups;
    final isLastDynamicStep = state.currentStep >= orderedGroups.length - 1;
    final isAdditionalInfoStep = state.currentStep == orderedGroups.length;

    // Validate current step (skip validation for additional info step)
    if (!isAdditionalInfoStep && !_validateCurrentStep(emit)) {
      return;
    }

    if (isAdditionalInfoStep) {
      // On additional info step, submit the form
      add(const SubmitRfqForm());
    } else if (isLastDynamicStep) {
      // Move from last dynamic step to additional info step
      emit(
        state.copyWith(
          currentStep: state.currentStep + 1,
          validationErrors: {},
        ),
      );
    } else {
      // Save as draft and move to next step
      emit(state.copyWith(status: RfqFormStatus.saving));

      try {
        await _rfqRepository.saveRfqFormAsDraft(
          answers: state.answers,
          currentStep: state.currentStep + 1,
          totalSteps: orderedGroups.length + 1, // +1 for additional info step
          selectedProductIds:
              state.selectedProductIds.isNotEmpty
                  ? state.selectedProductIds
                  : null,
          requirementDescription:
              state.requirementDescription?.isNotEmpty == true
                  ? state.requirementDescription
                  : null,
          attachmentFile: state.attachmentFile,
        );

        emit(
          state.copyWith(
            status: RfqFormStatus.loaded,
            currentStep: state.currentStep + 1,
            validationErrors: {},
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: RfqFormStatus.loaded,
            currentStep: state.currentStep + 1,
          ),
        );
      }
    }
  }

  void _onPreviousStep(PreviousStep event, Emitter<RfqState> emit) {
    if (state.currentStep > 0) {
      emit(
        state.copyWith(
          currentStep: state.currentStep - 1,
          validationErrors: {},
        ),
      );
    }
  }

  Future<void> _onSubmitRfqForm(
    SubmitRfqForm event,
    Emitter<RfqState> emit,
  ) async {
    if (kDebugMode) {
      print('RFQ Submit: SubmitRfqForm event received');
    }

    if (state.formDefinition == null) {
      if (kDebugMode) {
        print('RFQ Submit: Form definition is null, aborting');
      }
      return;
    }

    // Skip validation if on additional info step (last step)
    final isAdditionalInfoStep = state.isAdditionalInformationStep;
    if (!isAdditionalInfoStep && !_validateCurrentStep(emit)) {
      if (kDebugMode) {
        print('RFQ Submit: Validation failed, aborting');
      }
      return;
    }

    if (kDebugMode) {
      print('RFQ Submit: Starting submission process...');
    }

    emit(state.copyWith(status: RfqFormStatus.submitting));

    try {
      // Fetch products for the payload
      final rfqService = RfqService();
      final allProducts = await rfqService.getRfqProducts();

      final success = await _rfqRepository.submitRfqForm(
        formDefinition: state.formDefinition!,
        answers: state.answers,
        currentStep: state.currentStep + 1,
        totalSteps:
            state.formDefinition!.orderedGroups.length +
            1, // +1 for additional info step
        selectedProductIds: state.selectedProductIds,
        allProducts: allProducts,
        requirementDescription: state.requirementDescription,
        attachmentFile: state.attachmentFile,
        fileName: null, // TODO: Store fileName in state if needed
      );

      if (success) {
        emit(state.copyWith(status: RfqFormStatus.submitted));
      } else {
        emit(
          state.copyWith(
            status: RfqFormStatus.error,
            errorMessage: 'Failed to submit form',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: RfqFormStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSaveRfqFormAsDraft(
    SaveRfqFormAsDraft event,
    Emitter<RfqState> emit,
  ) async {
    if (state.formDefinition == null) return;

    emit(state.copyWith(status: RfqFormStatus.saving));

    try {
      await _rfqRepository.saveRfqFormAsDraft(
        answers: state.answers,
        currentStep: state.currentStep + 1,
        totalSteps:
            state.formDefinition!.orderedGroups.length +
            1, // +1 for additional info step
        selectedProductIds:
            state.selectedProductIds.isNotEmpty
                ? state.selectedProductIds
                : null,
        requirementDescription:
            state.requirementDescription?.isNotEmpty == true
                ? state.requirementDescription
                : null,
        attachmentFile: state.attachmentFile,
      );

      emit(state.copyWith(status: RfqFormStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(status: RfqFormStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void _onValidateCurrentStep(
    ValidateCurrentStep event,
    Emitter<RfqState> emit,
  ) {
    _validateCurrentStep(emit);
  }

  bool _validateCurrentStep(Emitter<RfqState> emit) {
    if (state.formDefinition == null) return false;

    final orderedGroups = state.formDefinition!.orderedGroups;
    if (state.currentStep >= orderedGroups.length) return false;

    final currentGroup = orderedGroups[state.currentStep];
    final questionsForGroup = state.formDefinition!.getQuestionsForGroup(
      currentGroup.groupId,
    );

    final errors = <String, String>{};

    for (final question in questionsForGroup) {
      if (question.isMandatory) {
        final answer = state.answers[question.id.toString()];
        if (answer == null ||
            (answer is String && answer.trim().isEmpty) ||
            (answer is List && answer.isEmpty)) {
          errors[question.id.toString()] = 'This field is required';
        }
      }
    }

    if (errors.isNotEmpty) {
      emit(state.copyWith(validationErrors: errors));
      return false;
    }

    emit(state.copyWith(validationErrors: {}));
    return true;
  }

  void _onAddProduct(AddProduct event, Emitter<RfqState> emit) {
    final currentProducts = List<int>.from(state.selectedProductIds);
    if (!currentProducts.contains(event.productId)) {
      currentProducts.add(event.productId);
      emit(state.copyWith(selectedProductIds: currentProducts));
    }
  }

  void _onRemoveProduct(RemoveProduct event, Emitter<RfqState> emit) {
    final currentProducts = List<int>.from(state.selectedProductIds);
    currentProducts.remove(event.productId);
    emit(state.copyWith(selectedProductIds: currentProducts));
  }

  void _onUpdateRequirementDescription(
    UpdateRequirementDescription event,
    Emitter<RfqState> emit,
  ) {
    emit(state.copyWith(requirementDescription: event.description));
  }

  void _onUpdateAttachmentFile(
    UpdateAttachmentFile event,
    Emitter<RfqState> emit,
  ) {
    emit(state.copyWith(attachmentFile: event.filePath));
  }
}
