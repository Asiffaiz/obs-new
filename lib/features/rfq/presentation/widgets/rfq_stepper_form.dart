import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/features/rfq/data/services/rfq_service.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_product_model.dart';
import 'package:voicealerts_obs/features/rfq/presentation/bloc/rfq_bloc.dart';

class RfqStepperForm extends StatefulWidget {
  final VoidCallback? onSubmitSuccess;

  const RfqStepperForm({super.key, this.onSubmitSuccess});

  @override
  State<RfqStepperForm> createState() => _RfqStepperFormState();
}

class _RfqStepperFormState extends State<RfqStepperForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _previousStep = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _animateStepChange(int newStep) {
    final isForward = newStep > _previousStep;
    _slideAnimation = Tween<Offset>(
      begin: Offset(isForward ? 0.1 : -0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.reset();
    _animationController.forward();
    _previousStep = newStep;

    // Scroll to top
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RfqBloc, RfqState>(
      listenWhen:
          (previous, current) =>
              previous.currentStep != current.currentStep ||
              previous.status != current.status,
      listener: (context, state) {
        if (state.currentStep != _previousStep) {
          _animateStepChange(state.currentStep);
        }

        if (state.status == RfqFormStatus.submitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('RFQ submitted successfully!'),
              backgroundColor: AppColors.successColor,
            ),
          );
          widget.onSubmitSuccess?.call();
        }

        if (state.status == RfqFormStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }

        if (state.validationErrors.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete all required fields'),
              backgroundColor: AppColors.warningColor,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == RfqFormStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.formDefinition == null) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Stepper indicator
            _buildStepperIndicator(context, state),
            const SizedBox(height: 16),

            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Show additional information step or regular questions
                          if (state.isAdditionalInformationStep)
                            _buildAdditionalInformationStep(context, state)
                          else ...[
                            // Group header
                            if (state.currentGroup != null)
                              _buildGroupHeader(state.currentGroup!),

                            const SizedBox(height: 20),

                            // Questions
                            ...state.currentQuestions.map(
                              (question) => Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _buildQuestionField(
                                  context,
                                  state,
                                  question,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(context, state),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No RFQ form available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperIndicator(BuildContext context, RfqState state) {
    final orderedGroups = state.formDefinition!.orderedGroups;
    final totalSteps =
        orderedGroups.length + 1; // +1 for additional information step

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: totalSteps,
        itemBuilder: (context, index) {
          final isActive = index == state.currentStep;
          final isCompleted = index < state.currentStep;

          // Last step is always "Additional Information"
          final stepTitle =
              index < orderedGroups.length
                  ? orderedGroups[index].groupTitle
                  : 'Additional Information';

          return Container(
            width: MediaQuery.of(context).size.width * 0.4,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildStepIndicatorItem(
              context,
              index,
              stepTitle,
              isActive,
              isCompleted,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicatorItem(
    BuildContext context,
    int index,
    String title,
    bool isActive,
    bool isCompleted,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Step circle with animation
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? Theme.of(context).primaryColor
                    : isActive
                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                    : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isActive || isCompleted
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400,
              width: 2,
            ),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child:
                isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color:
                            isActive
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
        const SizedBox(width: 8),
        // Step title
        Expanded(
          child: Text(
            title.isEmpty ? 'Step ${index + 1}' : title,
            textAlign: TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
              color:
                  isActive || isCompleted
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupHeader(RfqQuestionGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.groupTitle.isNotEmpty)
          Text(
            group.groupTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        if (group.groupDesc.isNotEmpty) ...[
          const SizedBox(height: 8),
          _HtmlContent(group.groupDesc),
        ],
      ],
    );
  }

  Widget _buildQuestionField(
    BuildContext context,
    RfqState state,
    RfqQuestion question,
  ) {
    final questionId = question.id.toString();
    final currentAnswer = state.answers[questionId];
    final hasError = state.validationErrors.containsKey(questionId);

    switch (question.questionType.toLowerCase()) {
      case 'label':
      case 'simple_text':
        return _RfqLabelField(question: question);

      case 'textfield':
        return _RfqTextField(
          question: question,
          initialValue: currentAnswer?.toString() ?? '',
          hasError: hasError,
          onChanged: (value) {
            context.read<RfqBloc>().add(
              UpdateAnswer(questionId: questionId, answer: value),
            );
          },
        );

      case 'textarea':
        return _RfqTextAreaField(
          question: question,
          initialValue: currentAnswer?.toString() ?? '',
          hasError: hasError,
          onChanged: (value) {
            context.read<RfqBloc>().add(
              UpdateAnswer(questionId: questionId, answer: value),
            );
          },
        );

      case 'dropdown':
        return _RfqDropdownField(
          question: question,
          initialValue: currentAnswer?.toString(),
          hasError: hasError,
          onChanged: (value) {
            context.read<RfqBloc>().add(
              UpdateAnswer(questionId: questionId, answer: value),
            );
          },
        );

      case 'radio':
        return _RfqRadioField(
          question: question,
          initialValue: currentAnswer?.toString(),
          hasError: hasError,
          onChanged: (value) {
            context.read<RfqBloc>().add(
              UpdateAnswer(questionId: questionId, answer: value),
            );
          },
        );

      case 'checkbox':
        return _RfqCheckboxField(
          question: question,
          initialValue:
              currentAnswer is List
                  ? List<String>.from(currentAnswer)
                  : <String>[],
          hasError: hasError,
          onChanged: (value) {
            context.read<RfqBloc>().add(
              UpdateAnswer(questionId: questionId, answer: value),
            );
          },
        );

      case 'fileinput':
        return _RfqFileInputField(
          question: question,
          initialValue: currentAnswer?.toString(),
          hasError: hasError,
          onChanged: (value) {
            context.read<RfqBloc>().add(
              UpdateAnswer(questionId: questionId, answer: value),
            );
          },
        );

      default:
        return _RfqTextField(
          question: question,
          initialValue: currentAnswer?.toString() ?? '',
          hasError: hasError,
          onChanged: (value) {
            context.read<RfqBloc>().add(
              UpdateAnswer(questionId: questionId, answer: value),
            );
          },
        );
    }
  }

  Widget _buildAdditionalInformationStep(BuildContext context, RfqState state) {
    return FutureBuilder<List<RfqProduct>>(
      future: RfqService().getRfqProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final products = snapshot.data ?? [];
        final selectedProductIds = state.selectedProductIds;
        final selectedProducts =
            products.where((p) => selectedProductIds.contains(p.id)).toList();

        return ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 0,
            maxWidth: double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Step Title
              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Add Product/Service Section
              _buildProductSelector(context, products, selectedProductIds),
              const SizedBox(height: 20),

              // Selected Products List
              if (selectedProducts.isNotEmpty) ...[
                _buildSelectedProductsList(context, selectedProducts),
                const SizedBox(height: 20),
              ],

              // Additional Information Label
              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Requirement Description Textarea
              _buildRequirementDescriptionField(context, state),
              const SizedBox(height: 20),

              // Attachment Field
              _buildAttachmentField(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductSelector(
    BuildContext context,
    List<RfqProduct> products,
    List<int> selectedProductIds,
  ) {
    return _ProductSelectorWidget(
      products: products,
      selectedProductIds: selectedProductIds,
      onAddProduct: (productId) {
        context.read<RfqBloc>().add(AddProduct(productId));
      },
    );
  }

  Widget _buildSelectedProductsList(
    BuildContext context,
    List<RfqProduct> selectedProducts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Selected Products (${selectedProducts.length})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ...selectedProducts.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectedProductTile(
              product: product,
              onDelete: () {
                context.read<RfqBloc>().add(RemoveProduct(product.id));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementDescriptionField(
    BuildContext context,
    RfqState state,
  ) {
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        initialValue: state.requirementDescription ?? '',
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Describe Your Requirement',
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          context.read<RfqBloc>().add(UpdateRequirementDescription(value));
        },
      ),
    );
  }

  Widget _buildAttachmentField(BuildContext context, RfqState state) {
    return _RfqAttachmentField(
      initialValue: state.attachmentFile,
      onChanged: (filePath) {
        context.read<RfqBloc>().add(UpdateAttachmentFile(filePath));
      },
    );
  }

  Widget _buildNavigationButtons(BuildContext context, RfqState state) {
    final isLoading =
        state.status == RfqFormStatus.saving ||
        state.status == RfqFormStatus.submitting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (!state.isFirstStep)
            Expanded(
              child: OutlinedButton(
                onPressed:
                    isLoading
                        ? null
                        : () =>
                            context.read<RfqBloc>().add(const PreviousStep()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),

          if (!state.isFirstStep) const SizedBox(width: 16),

          // Next/Submit button
          Expanded(
            child: ElevatedButton(
              onPressed:
                  isLoading
                      ? null
                      : () => context.read<RfqBloc>().add(const NextStep()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        state.isLastStep ? 'Submit' : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Question Field Widgets =====

class _RfqFieldLabel extends StatelessWidget {
  final RfqQuestion question;

  const _RfqFieldLabel({required this.question});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
        children: [
          TextSpan(text: question.questionTitle),
          if (question.isMandatory)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _RfqLabelField extends StatelessWidget {
  final RfqQuestion question;

  const _RfqLabelField({required this.question});

  @override
  Widget build(BuildContext context) {
    // Check if there are HTML options to display
    if (question.options.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...question.options.map((option) => _HtmlContent(option.optionText)),
        ],
      );
    }

    return Text(
      question.questionTitle,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _RfqTextField extends StatefulWidget {
  final RfqQuestion question;
  final String initialValue;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _RfqTextField({
    required this.question,
    required this.initialValue,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_RfqTextField> createState() => _RfqTextFieldState();
}

class _RfqTextFieldState extends State<_RfqTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RfqFieldLabel(question: widget.question),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.question.questionTitle,
            errorText: widget.hasError ? 'This field is required' : null,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class _RfqTextAreaField extends StatefulWidget {
  final RfqQuestion question;
  final String initialValue;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _RfqTextAreaField({
    required this.question,
    required this.initialValue,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_RfqTextAreaField> createState() => _RfqTextAreaFieldState();
}

class _RfqTextAreaFieldState extends State<_RfqTextAreaField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RfqFieldLabel(question: widget.question),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: widget.question.questionTitle,
            errorText: widget.hasError ? 'This field is required' : null,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class _RfqDropdownField extends StatefulWidget {
  final RfqQuestion question;
  final String? initialValue;
  final bool hasError;
  final ValueChanged<String?> onChanged;

  const _RfqDropdownField({
    required this.question,
    required this.initialValue,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_RfqDropdownField> createState() => _RfqDropdownFieldState();
}

class _RfqDropdownFieldState extends State<_RfqDropdownField> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options.map((o) => o.optionText).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RfqFieldLabel(question: widget.question),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value:
              _selectedValue != null && options.contains(_selectedValue)
                  ? _selectedValue
                  : null,
          menuMaxHeight: 300,
          decoration: InputDecoration(
            hintText: 'Select an option',
            errorText: widget.hasError ? 'This field is required' : null,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(
                Icons.arrow_drop_down_circle_outlined,
                color: Colors.grey,
                size: 20,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
          ),
          items:
              options
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option, style: const TextStyle(fontSize: 14)),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() => _selectedValue = value);
            widget.onChanged(value);
          },
          isExpanded: true,
          dropdownColor: Colors.white,
        ),
      ],
    );
  }
}

class _RfqRadioField extends StatefulWidget {
  final RfqQuestion question;
  final String? initialValue;
  final bool hasError;
  final ValueChanged<String?> onChanged;

  const _RfqRadioField({
    required this.question,
    required this.initialValue,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_RfqRadioField> createState() => _RfqRadioFieldState();
}

class _RfqRadioFieldState extends State<_RfqRadioField> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RfqFieldLabel(question: widget.question),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  widget.hasError ? AppColors.errorColor : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children:
                widget.question.options.map((option) {
                  return RadioListTile<String>(
                    dense: true,
                    title: Text(
                      option.optionText,
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: option.optionText,
                    groupValue: _selectedValue,
                    onChanged: (value) {
                      setState(() => _selectedValue = value);
                      widget.onChanged(value);
                    },
                    activeColor: Theme.of(context).primaryColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                }).toList(),
          ),
        ),
        if (widget.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'This field is required',
              style: TextStyle(color: AppColors.errorColor, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _RfqCheckboxField extends StatefulWidget {
  final RfqQuestion question;
  final List<String> initialValue;
  final bool hasError;
  final ValueChanged<List<String>> onChanged;

  const _RfqCheckboxField({
    required this.question,
    required this.initialValue,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_RfqCheckboxField> createState() => _RfqCheckboxFieldState();
}

class _RfqCheckboxFieldState extends State<_RfqCheckboxField> {
  late List<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RfqFieldLabel(question: widget.question),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  widget.hasError ? AppColors.errorColor : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children:
                widget.question.options.map((option) {
                  final isSelected = _selectedValues.contains(
                    option.optionText,
                  );
                  return CheckboxListTile(
                    dense: true,
                    title: Text(
                      option.optionText,
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedValues.add(option.optionText);
                        } else {
                          _selectedValues.remove(option.optionText);
                        }
                      });
                      widget.onChanged(List.from(_selectedValues));
                    },
                    activeColor: Theme.of(context).primaryColor,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                }).toList(),
          ),
        ),
        if (widget.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'This field is required',
              style: TextStyle(color: AppColors.errorColor, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _RfqFileInputField extends StatefulWidget {
  final RfqQuestion question;
  final String? initialValue;
  final bool hasError;
  final ValueChanged<String?> onChanged;

  const _RfqFileInputField({
    required this.question,
    required this.initialValue,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_RfqFileInputField> createState() => _RfqFileInputFieldState();
}

class _RfqFileInputFieldState extends State<_RfqFileInputField> {
  String? _fileName;
  bool _isUploading = false;

  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  final List<String> _allowedExtensions = [
    'png',
    'jpg',
    'jpeg',
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _fileName = widget.initialValue;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.size > maxFileSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File is too large. Maximum size is 10MB.'),
              ),
            );
          }
          return;
        }

        setState(() {
          _isUploading = true;
        });

        // Get file bytes
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        if (bytes != null) {
          setState(() {
            _fileName = file.name;
            _isUploading = false;
          });

          // Convert to base64 and notify parent
          final base64Data = base64Encode(bytes);
          widget.onChanged(base64Data);
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  void _clearFile() {
    setState(() {
      _fileName = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RfqFieldLabel(question: widget.question),
        const SizedBox(height: 8),

        if (_fileName != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: _clearFile,
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _isUploading ? null : _pickFile,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      widget.hasError
                          ? AppColors.errorColor
                          : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.attach_file,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _isUploading ? 'Uploading...' : 'Select file',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  if (_isUploading)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),

        if (widget.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'This field is required',
              style: TextStyle(color: AppColors.errorColor, fontSize: 12),
            ),
          ),

        if (_fileName == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Allowed: PNG, JPG, PDF, DOC, DOCX, XLS, XLSX, CSV',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

// ===== Additional Information Step Widgets =====

class _ProductSelectorWidget extends StatefulWidget {
  final List<RfqProduct> products;
  final List<int> selectedProductIds;
  final Function(int) onAddProduct;

  const _ProductSelectorWidget({
    required this.products,
    required this.selectedProductIds,
    required this.onAddProduct,
  });

  @override
  State<_ProductSelectorWidget> createState() => _ProductSelectorWidgetState();
}

class _ProductSelectorWidgetState extends State<_ProductSelectorWidget> {
  int? _selectedProductId;

  @override
  Widget build(BuildContext context) {
    final availableProducts =
        widget.products
            .where((p) => !widget.selectedProductIds.contains(p.id))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Add product/service',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        // Use ConstrainedBox to ensure proper width constraints
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 0,
            maxWidth: double.infinity,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Select a product/service',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  items:
                      availableProducts
                          .map(
                            (product) => DropdownMenuItem(
                              value: product.id,
                              child: Text(
                                product.displayName,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (productId) {
                    setState(() {
                      _selectedProductId = productId;
                    });
                  },
                  value: _selectedProductId,
                ),
              ),
              const SizedBox(width: 12),
              // Use ConstrainedBox to set button width constraints
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 90, maxWidth: 120),
                child: ElevatedButton.icon(
                  onPressed:
                      _selectedProductId == null
                          ? null
                          : () {
                            widget.onAddProduct(_selectedProductId!);
                            setState(() {
                              _selectedProductId = null;
                            });
                          },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectedProductTile extends StatelessWidget {
  final RfqProduct product;
  final VoidCallback onDelete;

  const _SelectedProductTile({required this.product, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Name',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Delete Icon
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.errorColor,
                    size: 20,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Remove product',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Use ConstrainedBox to ensure proper width constraints
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 0,
                maxWidth: double.infinity,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Flexible(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.displayDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // View Button - fixed minimum width to prevent overflow
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 80,
                      maxWidth: 100,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () => _showProductDetails(context, product),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        side: BorderSide(color: AppColors.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, RfqProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Product Name
                      Text(
                        product.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (product.sku != null && product.sku!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'SKU: ${product.sku}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.displayDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      if (product.productDesc != null &&
                          product.productDesc!.trim().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Full Description',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _HtmlContent(product.productDesc!),
                      ],
                    ],
                  ),
                ),
          ),
    );
  }
}

// ===== Attachment Field Widget =====

class _RfqAttachmentField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const _RfqAttachmentField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_RfqAttachmentField> createState() => _RfqAttachmentFieldState();
}

class _RfqAttachmentFieldState extends State<_RfqAttachmentField> {
  String? _fileName;
  Uint8List? _fileBytes;
  bool _isUploading = false;

  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  final List<String> _allowedExtensions = [
    'png',
    'jpg',
    'jpeg',
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
    'txt',
    'zip',
    'rar',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _fileName = widget.initialValue;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.size > maxFileSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File is too large. Maximum size is 50MB.'),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
          return;
        }

        setState(() {
          _isUploading = true;
        });

        // Get file bytes
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        if (bytes != null) {
          setState(() {
            _fileName = file.name;
            _fileBytes = bytes;
            _isUploading = false;
          });

          // Convert to base64 and notify parent
          final base64Data = base64Encode(bytes);
          widget.onChanged(base64Data);
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _clearFile() {
    setState(() {
      _fileName = null;
      _fileBytes = null;
    });
    widget.onChanged(null);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Attachment',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        if (_fileName != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_fileBytes != null)
                        Text(
                          _formatFileSize(_fileBytes!.length),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: _clearFile,
                ),
              ],
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 0,
              maxWidth: double.infinity,
            ),
            child: InkWell(
              onTap: _isUploading ? null : _pickFile,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.attach_file,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _isUploading ? 'Uploading...' : 'Select file',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    if (_isUploading)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

        // File format and size info
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Supported formats: PNG, JPG, PDF, DOC, DOCX, XLS, XLSX, CSV, TXT, ZIP, RAR\nMax file size: 50 MB',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ===== Helper Widgets =====

class _HtmlContent extends StatelessWidget {
  final String html;

  const _HtmlContent(this.html);

  bool _looksLikeHtml(String s) => RegExp(r'<[^>]+>').hasMatch(s);

  @override
  Widget build(BuildContext context) {
    if (_looksLikeHtml(html)) {
      return Html(data: html);
    }

    return Text(
      html.trim(),
      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
    );
  }
}
