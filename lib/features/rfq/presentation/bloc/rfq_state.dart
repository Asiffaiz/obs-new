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
  final List<int> selectedProductIds; // IDs of selected products
  final String? requirementDescription; // Additional requirement description
  final String? attachmentFile; // Attachment file path or base64
  final bool isEditMode; // Whether we're in edit mode
  final String? rfqAccountNo; // RFQ account number when editing

  const RfqState({
    this.status = RfqFormStatus.initial,
    this.formDefinition,
    this.currentStep = 0,
    this.answers = const {},
    this.validationErrors = const {},
    this.errorMessage,
    this.selectedProductIds = const [],
    this.requirementDescription,
    this.attachmentFile,
    this.isEditMode = false,
    this.rfqAccountNo,
  });

  RfqState copyWith({
    RfqFormStatus? status,
    RfqFormDefinition? formDefinition,
    int? currentStep,
    Map<String, dynamic>? answers,
    Map<String, String>? validationErrors,
    String? errorMessage,
    List<int>? selectedProductIds,
    String? requirementDescription,
    String? attachmentFile,
    bool? isEditMode,
    String? rfqAccountNo,
  }) {
    return RfqState(
      status: status ?? this.status,
      formDefinition: formDefinition ?? this.formDefinition,
      currentStep: currentStep ?? this.currentStep,
      answers: answers ?? this.answers,
      validationErrors: validationErrors ?? this.validationErrors,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedProductIds: selectedProductIds ?? this.selectedProductIds,
      requirementDescription: requirementDescription ?? this.requirementDescription,
      attachmentFile: attachmentFile ?? this.attachmentFile,
      isEditMode: isEditMode ?? this.isEditMode,
      rfqAccountNo: rfqAccountNo ?? this.rfqAccountNo,
    );
  }

  /// Check if the form is on the last step (including additional information step)
  bool get isLastStep {
    if (formDefinition == null) return false;
    // Additional information is always the last step
    return currentStep >= formDefinition!.orderedGroups.length;
  }

  /// Check if the form is on the first step
  bool get isFirstStep => currentStep == 0;

  /// Get total number of steps (including additional information step)
  int get totalSteps {
    if (formDefinition == null) return 0;
    return formDefinition!.orderedGroups.length + 1; // +1 for additional information step
  }

  /// Check if current step is the additional information step
  bool get isAdditionalInformationStep {
    if (formDefinition == null) return false;
    return currentStep == formDefinition!.orderedGroups.length;
  }

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
        selectedProductIds,
        requirementDescription,
        attachmentFile,
        isEditMode,
        rfqAccountNo,
      ];
}

