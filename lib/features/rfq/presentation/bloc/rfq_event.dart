part of 'rfq_bloc.dart';

sealed class RfqEvent extends Equatable {
  const RfqEvent();

  @override
  List<Object?> get props => [];
}

/// Load RFQ form data from API
class LoadRfqFormData extends RfqEvent {
  const LoadRfqFormData();
}

/// Update the current step
class UpdateCurrentStep extends RfqEvent {
  final int step;

  const UpdateCurrentStep(this.step);

  @override
  List<Object?> get props => [step];
}

/// Update an answer for a specific question
class UpdateAnswer extends RfqEvent {
  final String questionId;
  final dynamic answer;

  const UpdateAnswer({
    required this.questionId,
    required this.answer,
  });

  @override
  List<Object?> get props => [questionId, answer];
}

/// Move to the next step
class NextStep extends RfqEvent {
  const NextStep();
}

/// Move to the previous step
class PreviousStep extends RfqEvent {
  const PreviousStep();
}

/// Submit the RFQ form
class SubmitRfqForm extends RfqEvent {
  const SubmitRfqForm();
}

/// Save the RFQ form as draft
class SaveRfqFormAsDraft extends RfqEvent {
  const SaveRfqFormAsDraft();
}

/// Validate the current step
class ValidateCurrentStep extends RfqEvent {
  const ValidateCurrentStep();
}

/// Add a product to the selection
class AddProduct extends RfqEvent {
  final int productId;

  const AddProduct(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Remove a product from the selection
class RemoveProduct extends RfqEvent {
  final int productId;

  const RemoveProduct(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Update requirement description
class UpdateRequirementDescription extends RfqEvent {
  final String description;

  const UpdateRequirementDescription(this.description);

  @override
  List<Object?> get props => [description];
}

/// Update attachment file
class UpdateAttachmentFile extends RfqEvent {
  final String? filePath;

  const UpdateAttachmentFile(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

