import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_model.dart';
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

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: orderedGroups.length,
        itemBuilder: (context, index) {
          final isActive = index == state.currentStep;
          final isCompleted = index < state.currentStep;

          return Container(
            width: MediaQuery.of(context).size.width * 0.4,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildStepIndicatorItem(
              context,
              index,
              orderedGroups[index].groupTitle,
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
