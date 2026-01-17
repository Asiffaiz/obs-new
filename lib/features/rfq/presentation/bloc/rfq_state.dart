part of 'rfq_bloc.dart';

enum RfqFormStatus {
  initial,
  loading,
  loaded,
  saving,
  submitting,
  submitted,
  error,
}

class RfqState extends Equatable {
  final RfqFormStatus status;
  final RfqFormDefinition? formDefinition;
  final int currentStep;
  final Map<String, dynamic> answers;
  final Map<String, String> validationErrors;
  final String? errorMessage;

  const RfqState({
    this.status = RfqFormStatus.initial,
    this.formDefinition,
    this.currentStep = 0,
    this.answers = const {},
    this.validationErrors = const {},
    this.errorMessage,
  });

  RfqState copyWith({
    RfqFormStatus? status,
    RfqFormDefinition? formDefinition,
    int? currentStep,
    Map<String, dynamic>? answers,
    Map<String, String>? validationErrors,
    String? errorMessage,
  }) {
    return RfqState(
      status: status ?? this.status,
      formDefinition: formDefinition ?? this.formDefinition,
      currentStep: currentStep ?? this.currentStep,
      answers: answers ?? this.answers,
      validationErrors: validationErrors ?? this.validationErrors,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if the form is on the last step
  bool get isLastStep {
    if (formDefinition == null) return false;
    return currentStep >= formDefinition!.orderedGroups.length - 1;
  }

  /// Check if the form is on the first step
  bool get isFirstStep => currentStep == 0;

  /// Get total number of steps
  int get totalSteps => formDefinition?.orderedGroups.length ?? 0;

  /// Get current group
  RfqQuestionGroup? get currentGroup {
    if (formDefinition == null) return null;
    final groups = formDefinition!.orderedGroups;
    if (currentStep >= groups.length) return null;
    return groups[currentStep];
  }

  /// Get questions for current group
  List<RfqQuestion> get currentQuestions {
    if (formDefinition == null || currentGroup == null) return [];
    return formDefinition!.getQuestionsForGroup(currentGroup!.groupId);
  }

  @override
  List<Object?> get props => [
        status,
        formDefinition,
        currentStep,
        answers,
        validationErrors,
        errorMessage,
      ];
}

