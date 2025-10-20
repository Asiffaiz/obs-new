import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // Added for Uint8List
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:file_picker/file_picker.dart';
import 'package:voicealerts_obs/config/routes.dart';
import 'package:voicealerts_obs/core/config/api_keys.dart';
import 'package:voicealerts_obs/core/constants/country_codes.dart';
import 'package:voicealerts_obs/core/services/google_places_service.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/theme/app_text_styles.dart';
import 'package:voicealerts_obs/features/auth/domain/models/address_model.dart';
import 'package:voicealerts_obs/features/forms/domain/models/form_model.dart';
import 'package:signature/signature.dart';
import 'package:voicealerts_obs/features/forms/data/services/form_service.dart';

class DynamicStepperForm extends StatefulWidget {
  final FormDefinition form;

  final void Function(Map<String, dynamic> answers)? onSubmit;
  final String formAccountNo;
  final String? formToken;
  final List<dynamic> formContent;
  final void Function()? handleScreenNavigation;
  const DynamicStepperForm({
    super.key,
    required this.form,

    this.onSubmit,
    required this.formAccountNo,
    required this.formToken,
    required this.formContent,
    required this.handleScreenNavigation,
  });

  factory DynamicStepperForm.fromJson(
    Map<String, dynamic> apiJson, {
    void Function(Map<String, dynamic>)? onSubmit,
    required String formAccountNo,
    required String formToken,
    required List<dynamic> formContent,
    required void Function() handleScreenNavigation,
  }) {
    return DynamicStepperForm(
      form: FormDefinition.fromApi(apiJson),

      onSubmit: onSubmit,
      formAccountNo: formAccountNo,
      formToken: formToken,
      formContent: formContent,
      handleScreenNavigation: handleScreenNavigation,
    );
  }

  @override
  State<DynamicStepperForm> createState() => _DynamicStepperFormState();
}

class _DynamicStepperFormState extends State<DynamicStepperForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();
  final FormsService _formsService = FormsService();
  bool _isSaving = false;

  // answers keyed by question id
  final Map<String, dynamic> _answers = {};
  late final String _formMediaPath;

  late final Map<String, FormQuestion> _qById;
  late final List<FormGroup> _orderedGroups;

  @override
  void initState() {
    super.initState();
    _qById = {for (final q in widget.form.questions) q.id: q};
    _orderedGroups = [...widget.form.groups]
      ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
    _formMediaPath = widget.form.formMediaPath ?? '';
    _loadDraftValues();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadDraftValues() {
    if (widget.form.draftResponse != null &&
        widget.form.draftResponse!.isNotEmpty) {
      // Load answers from draft response
      for (var question in widget.form.draftResponse!) {
        if (question.answer != null && question.answer!.isNotEmpty) {
          // Store the answer in our answers map
          _answers[question.id] = question.answer;
        }
      }
    }

    setState(() {
      try {
        var stepCount = widget.form.progress?.split('/')[0] ?? '0';
        _currentStep = int.parse(stepCount);
      } catch (e) {
        _currentStep = 0;
      }
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      if (_isSaving) return;

      setState(() {
        _isSaving = true;
      });

      try {
        // Save current step's data
        _formKey.currentState?.save();

        final success = await _formsService.saveForm(
          formAccountNo: widget.formAccountNo,
          formToken: widget.formToken ?? '',
          formContent: widget.formContent,
          formTitle: widget.form.title,
          formDesc: widget.form.description ?? '',
          submittedStep: _currentStep,
          totalSteps: _orderedGroups.length,
          answers: _answers,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Form saved successfully')),
          );

          // Navigate to dashboard after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (widget.handleScreenNavigation != null) {
              widget.handleScreenNavigation!();
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save form')));
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields.')),
      );
    }
  }

  Future<void> _saveFormAsDraft() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (_isSaving) return;

      setState(() {
        _isSaving = true;
      });

      try {
        // Save current step's data
        _formKey.currentState?.save();

        final success = await _formsService.saveFormAsDraft(
          formAccountNo: widget.formAccountNo,
          formToken: widget.formToken ?? '',
          formContent: widget.formContent,
          formTitle: widget.form.title,
          formDesc: widget.form.description ?? '',
          submittedStep: _currentStep + 1,
          totalSteps: _orderedGroups.length,
          answers: _answers,
        );

        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Form saved as draft')));
        }

        //////////////////////////////
        setState(() {
          _currentStep++;
          // Reset scroll position when changing steps
          _scrollController.jumpTo(0);
        });
        //////////////////////////////
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save form: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields.')),
      );
    }
  }

  void _nextStep() async {
    if (_currentStep < _orderedGroups.length - 1) {
      // Save current step data
      _formKey.currentState?.save();

      // Save as draft
      await _saveFormAsDraft();

      // setState(() {
      //   _currentStep++;
      //   // Reset scroll position when changing steps
      //   _scrollController.jumpTo(0);
      // });
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      // Save current step data
      _formKey.currentState?.save();

      setState(() {
        _currentStep--;
        // Reset scroll position when going back
        _scrollController.jumpTo(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal stepper indicator (always visible)
        _buildStepperIndicator(),

        const SizedBox(height: 16),

        // Form content - scrollable
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form title and description (only on first step)
                  if (_currentStep == 0 && widget.form.title.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   widget.form.title,
                          //   style: Theme.of(context).textTheme.displayMedium,
                          // ),
                          if (widget.form.description != null &&
                              widget.form.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _Htmlish(widget.form.description!),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // Current step content
                  _buildCurrentStepContent(),

                  // Add some bottom padding for scrolling
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(0, 46),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(0, 46),
                  ),
                  child:
                      _isSaving
                          ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(),
                            ),
                          )
                          : Text(
                            _currentStep == _orderedGroups.length - 1
                                ? (widget.form.submitText ?? 'Submit')
                                : 'Next',
                          ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  final List<String> _orderedGroups2 = List.generate(
    20,
    (index) => "Step ${index + 1}",
  );

  // Widget _buildStepperIndicator() {
  //   return Container(
  //     height: 80,
  //     child: Row(
  //       mainAxisAlignment:
  //           _orderedGroups.length == 1
  //               ? MainAxisAlignment.start
  //               : MainAxisAlignment.start,
  //       children: List.generate(_orderedGroups2.length, (index) {
  //         bool isActive = index == _currentStep;
  //         bool isCompleted = index < _currentStep;

  //         return _orderedGroups.length == 1
  //             ? Container(
  //               width: 120, // Fixed width when there's only one group
  //               child: _buildStepIndicator(index, isActive, isCompleted),
  //             )
  //             : Expanded(
  //               child: _buildStepIndicator(index, isActive, isCompleted),
  //             );
  //       }),
  //     ),
  //   );
  // }

  Widget _buildStepperIndicator() {
    return Container(
      height: 80, // keeps your step indicator height
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // 🔹 makes it scroll sideways
        itemCount: _orderedGroups.length,
        itemBuilder: (context, index) {
          bool isActive = index == _currentStep;
          bool isCompleted = index < _currentStep;

          return Container(
            width:
                MediaQuery.of(context).size.width *
                0.2, // 🔹 fixed width for each step
            padding: EdgeInsets.all(0),
            margin: EdgeInsets.symmetric(horizontal: 0),
            child: _buildStepIndicator(index, isActive, isCompleted),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(int index, bool isActive, bool isCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step circle
        GestureDetector(
          onTap: () async {
            // Save current step data
            //  _formKey.currentState?.save();

            // Save as draft if moving to a different step
            // if (_currentStep != index) {
            //   await _saveFormAsDraft();
            // }

            // setState(() {
            //   _currentStep = index;
            //   // Reset scroll position when changing steps
            //   _scrollController.jumpTo(0);
            // });
          },
          child: Container(
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
            ),
            child: Center(
              child:
                  isCompleted
                      ? Icon(Icons.check, color: Colors.white, size: 20)
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
        ),
        const SizedBox(height: 8),
        // Step title
        //    commented step title for now
        // Expanded(
        //   child: Text(
        //     _orderedGroups[index].title.isEmpty
        //         ? 'Step ${index + 1}'
        //         : _orderedGroups[index].title,
        //     textAlign: TextAlign.center,
        //     maxLines: 1,
        //     overflow: TextOverflow.ellipsis,
        //     style: TextStyle(
        //       fontSize: 12,
        //       fontWeight:
        //           isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
        //       color:
        //           isActive || isCompleted
        //               ? Theme.of(context).primaryColor
        //               : Colors.grey.shade600,
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    final group = _orderedGroups[_currentStep];

    // Pull questions by ids, ignore missing, then sort by each question's sequenceNumber
    final qs =
        group.questionIds
            .map((id) => _qById[id])
            .whereType<FormQuestion>()
            .toList()
          ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group title
        if (group.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              group.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

        // Group description
        if (group.desc.trim().isNotEmpty) ...[
          _Htmlish(group.desc),
          const SizedBox(height: 24),
        ],

        // Questions
        ...qs.map(
          (q) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildField(q),
          ),
        ),
      ],
    );
  }

  Widget _buildField(FormQuestion q) {
    final key = ValueKey(q.id);
    switch (q.answerType) {
      case 'label':
      case 'fixed fields':
      case 'fixed_fields':
        return _LabelField(text: q.questionText);
      case 'dropdown':
        return _DropdownField(
          key: key,
          question: q,
          initial: _answers[q.id],
          onSaved: (v) => _answers[q.id] = v,
        );
      case 'textarea':
        return _InputField(
          key: key,
          question: q,
          maxLines: 5,
          initial: (_answers[q.id] ?? '').toString(),
          onSaved: (v) => _answers[q.id] = v?.trim(),
        );
      case 'checkbox':
        return _CheckboxField(
          key: key,
          question: q,
          initial: _answers[q.id] == "Yes",
          onSaved: (v) => _answers[q.id] = v == true ? "Yes" : "No",
        );
      case 'radio':
        return _RadioField(
          key: key,
          question: q,
          initial: (_answers[q.id] ?? '').toString(),
          onSaved: (v) => _answers[q.id] = v,
        );
      case 'image_input':
        return _ImageInputField(
          key: key,
          question: q,
          initial: _answers[q.id],
          onSaved: (v) => _answers[q.id] = v,
          formMediaPath: _formMediaPath,
          formToken: widget.formToken ?? '',
        );
      case 'date':
        return _DateField(
          key: key,
          question: q,
          initial: _answers[q.id],
          onSaved: (v) => _answers[q.id] = v?.toIso8601String(),
        );
      case 'time':
        return _TimeField(
          key: key,
          question: q,
          initial: _answers[q.id],
          onSaved: (v) => _answers[q.id] = v,
        );
      case 'datetime':
        return _DateTimeField(
          key: key,
          question: q,
          initial: _answers[q.id],
          onSaved: (v) => _answers[q.id] = v?.toIso8601String(),
        );
      case 'signature':
        return _SignatureField(
          key: key,
          question: q,
          initial: _answers[q.id],
          formMediaPath: _formMediaPath,
          onSaved: (v) => _answers[q.id] = v,
        );
      case 'input':
        if (q.validationValue == "validation_phone") {
          // Extract initial value if available
          String? initialValue = _answers[q.id]?.toString();
          String initialCountryCode = '+1'; // Default
          String initialNumber = '';

          // Parse initial value if it exists
          if (initialValue != null && initialValue.isNotEmpty) {
            // Try to extract country code and number
            // Most international numbers follow format +[country code][number]
            // We need to properly identify the country code part
            String countryCode = '+1'; // Default
            String number = '';

            var countryCodes = CountryCodes.countryCodes;
            // Find the matching country code
            for (String code in countryCodes) {
              if (initialValue.startsWith(code)) {
                countryCode = code;
                number = initialValue.substring(code.length);
                break;
              }
            }

            // If no match found, try a simple regex as fallback
            if (number.isEmpty && initialValue.startsWith('+')) {
              RegExp regex = RegExp(r'^\+(\d{1,3})(.*)$');
              var match = regex.firstMatch(initialValue);
              if (match != null && match.groupCount >= 2) {
                countryCode = '+${match.group(1)}';
                number = match.group(2) ?? '';
              } else {
                // If still no match, just use the whole string as number
                number = initialValue;
              }
            }

            initialCountryCode = countryCode;
            initialNumber = number;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(question: q),
              const SizedBox(height: 8),
              _PhoneNumberField(
                initialCountryCode: initialCountryCode,
                initialNumber: initialNumber,
                onPhoneNumberChanged: (countryCode, number) {
                  _answers[q.id] = "$countryCode$number";
                },

                validator: (value) {
                  if (q.required && (value == null || value.isEmpty)) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ],
          );
        } else if (q.validationValue == "validation_fulladdress") {
          // Handle address field with Google Places autocomplete
          return _AddressField(
            key: key,
            question: q,
            initial: (_answers[q.id] ?? '').toString(),
            onSaved: (v) => _answers[q.id] = v?.trim(),
          );
        }
        return _InputField(
          key: key,
          question: q,
          initial: (_answers[q.id] ?? '').toString(),
          onSaved: (v) => _answers[q.id] = v?.trim(),
        );

      default:
        return _InputField(
          key: key,
          question: q,
          initial: (_answers[q.id] ?? '').toString(),
          onSaved: (v) => _answers[q.id] = v?.trim(),
        );
    }
  }
}

// ===== Small render helpers =====
class _QuestionCard extends StatelessWidget {
  final Widget child;
  const _QuestionCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _PhoneNumberField extends StatefulWidget {
  final Function(String, String) onPhoneNumberChanged;
  final String? Function(String?)? validator;
  final String initialCountryCode;
  final String initialNumber;

  const _PhoneNumberField({
    super.key,
    required this.onPhoneNumberChanged,
    this.validator,
    this.initialCountryCode = '+1',
    this.initialNumber = '',
  });

  @override
  State<_PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<_PhoneNumberField> {
  late final TextEditingController _controller;
  late String _countryCode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNumber);
    _countryCode = widget.initialCountryCode;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Custom validator wrapper that adapts our validator to the expected type
  String? _phoneValidator(PhoneNumber? phone) {
    if (widget.validator != null && phone != null) {
      return widget.validator!(phone.number);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Filter countries to only include the ones we want
    // final supportedCountries =
    //     countries
    //         .where(
    //           (country) => country.dialCode.contains(country.code),
    //         )
    //         .toList();

    // Find the country code that matches our initial country code
    String initialCountryCode = 'US'; // Default fallback
    for (var country in countries) {
      if ('+${country.dialCode}' == _countryCode) {
        initialCountryCode = country.code;
        break;
      }
    }

    return IntlPhoneField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      initialCountryCode: initialCountryCode,
      // countries: supportedCountries,
      onChanged: (phone) {
        // Pass both country code and phone number to parent
        widget.onPhoneNumberChanged(phone.countryCode, phone.number);
      },
      onSaved: (phone) {
        widget.onPhoneNumberChanged(
          phone?.countryCode ?? '',
          phone?.number ?? '',
        );
      },
      validator: _phoneValidator,
      dropdownIconPosition: IconPosition.trailing,
      flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 8),
      showDropdownIcon: true,
      disableLengthCheck: false,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
    );
  }
}

class _AddressField extends StatefulWidget {
  final FormQuestion question;
  final String initial;
  final void Function(String?) onSaved;

  const _AddressField({
    super.key,
    required this.question,
    required this.initial,
    required this.onSaved,
  });

  @override
  State<_AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<_AddressField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
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
        _FieldLabel(question: widget.question),
        const SizedBox(height: 8),
        _AddressAutocomplete(
          controller: _controller,
          label: widget.question.questionText,
          onAddressSelected: (address) {
            // Store the full address as a single string
            _controller.text = address.street;
            widget.onSaved(address.street);
          },
          onSaved: (v) => widget.onSaved(v),
          errorText:
              widget.question.required && _controller.text.isEmpty
                  ? 'Required'
                  : null,
        ),
        // Invisible field for form validation
        Visibility(
          visible: false,
          child: TextFormField(
            controller: _controller,
            validator: (value) {
              if (widget.question.required &&
                  (value == null || value.isEmpty)) {
                return 'Required';
              }
              return null;
            },
            onSaved: widget.onSaved,
          ),
        ),
      ],
    );
  }
}

class _AddressAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final Function(AddressModel) onAddressSelected;
  final String label;
  final String? errorText;
  final void Function(String) onSaved;
  const _AddressAutocomplete({
    super.key,
    required this.controller,
    required this.onAddressSelected,
    required this.label,
    required this.onSaved,
    this.errorText,
  });

  @override
  State<_AddressAutocomplete> createState() => _AddressAutocompleteState();
}

class _AddressAutocompleteState extends State<_AddressAutocomplete> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  bool _showSuggestions = false;
  List<AddressModel> _filteredAddresses = [];
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  bool _isLoading = false;

  // Google Places API key from config
  final _placesService = GooglePlacesService(
    apiKey: ApiKeys.googlePlacesApiKey,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = widget.controller.text;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _filteredAddresses = []);
      } else {
        // Use the Google Places API to fetch address predictions
        final predictions = await _placesService.getPlacePredictions(query);
        setState(() => _filteredAddresses = predictions);
      }

      if (_focusNode.hasFocus) {
        _updateOverlay();
      }
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showSuggestions = true;
      _updateOverlay();
    } else {
      _showSuggestions = false;
      _removeOverlay();
    }
  }

  void _updateOverlay() {
    _removeOverlay();

    if (_filteredAddresses.isEmpty) {
      return;
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 5),
              child: Material(
                elevation: 4,
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _filteredAddresses.length,
                    itemBuilder: (context, index) {
                      final address = _filteredAddresses[index];
                      final description = address.street;

                      return ListTile(
                        dense: true,
                        title: Text(
                          description,
                          style: AppTextStyles.bodyMedium,
                        ),
                        onTap: () async {
                          // When user taps an address prediction, fetch the full details
                          widget.controller.text = description;
                          widget.onSaved(description);
                          // Hide keyboard
                          FocusScope.of(context).unfocus();

                          // if (address.placeId != null) {
                          //   // Show loading indicator in the widget
                          //   setState(() {
                          //     _isLoading = true;
                          //   });

                          //   // Get full address details
                          //   final fullAddress = await _placesService
                          //       .getPlaceDetails(address.placeId!);

                          //   setState(() {
                          //     _isLoading = false;
                          //   });

                          //   if (fullAddress != null) {
                          //     widget.onAddressSelected(fullAddress);

                          //     // Update the controller with the formatted address
                          //     widget.controller.text =
                          //         '${fullAddress.street}, ${fullAddress.city}, ${fullAddress.state}, ${fullAddress.country}';
                          //   }
                          // }

                          _removeOverlay();
                          _focusNode.unfocus();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _clearText() {
    widget.controller.clear();
    setState(() => _filteredAddresses = []);
    _removeOverlay();
    widget.onSaved('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: widget.errorText,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              prefixIcon: Icon(
                Icons.location_on,
                color: AppColors.primaryColor,
              ),
              suffixIcon:
                  widget.controller.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _clearText(),
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4),
            child: Row(
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                // const Text('Loading address details...'),
              ],
            ),
          ),
      ],
    );
  }
}

class _LabelField extends StatelessWidget {
  final String text;
  const _LabelField({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _InputField extends StatelessWidget {
  final FormQuestion question;
  final String? initial;
  final int maxLines;
  final void Function(String?) onSaved;
  const _InputField({
    super.key,
    required this.question,
    required this.initial,
    required this.onSaved,
    this.maxLines = 1,
  });

  String? _validator(String? value) {
    final v = (value ?? '').trim();
    if (question.required && v.isEmpty) return 'Required';

    final rule = (question.validationValue ?? '').toLowerCase();
    if (v.isNotEmpty) {
      if (rule.contains('email')) {
        final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
        if (!ok) return 'Invalid email';
      }
      if (rule.contains('phone')) {
        final ok = RegExp(r'^[+\d][\d\s\-()]{6,}$').hasMatch(v);
        if (!ok) return 'Invalid phone';
      }
      if (rule.contains('zip')) {
        if (!RegExp(r'^[0-9A-Za-z\-\s]{3,10}\$').hasMatch(v))
          return 'Invalid ZIP';
      }
      if (rule.contains('state')) {
        if (v.length < 2) return 'Enter state';
      }
      if (rule.contains('city')) {
        if (v.length < 2) return 'Enter city';
      }
    }

    // inputFormat constraints
    final fmt = (question.inputFormat ?? '').toLowerCase();
    if (fmt == 'number_only' &&
        v.isNotEmpty &&
        !RegExp(r'^\d+\$').hasMatch(v)) {
      return 'Numbers only';
    }
    if (fmt == 'alphanumeric' &&
        v.isNotEmpty &&
        !RegExp(r'^[a-zA-Z0-9 _-]+\$').hasMatch(v)) {
      return 'Only letters, numbers, space, _ and -';
    }

    // maxLength
    final ml = int.tryParse((question.maxLength ?? '').toString());
    if (ml != null && v.length > ml) return 'Max $ml characters';

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(question: question),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initial,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: question.questionText,
            prefixIcon:
                maxLines == 1 ? _getIconForField(question.questionText) : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 12,
            ),
          ),
          style: const TextStyle(fontSize: 14),
          validator: _validator,
          onSaved: onSaved,
          keyboardType:
              (question.inputFormat?.toLowerCase() == 'number_only')
                  ? TextInputType.number
                  : TextInputType.text,
        ),
      ],
    );
  }

  Widget? _getIconForField(String questionText) {
    final text = questionText.toLowerCase();
    IconData iconData;

    if (text.contains('email')) {
      iconData = Icons.email_outlined;
    } else if (text.contains('phone')) {
      iconData = Icons.phone_outlined;
    } else if (text.contains('name')) {
      iconData = Icons.person_outline;
    } else if (text.contains('address')) {
      iconData = Icons.location_on_outlined;
    } else if (text.contains('city') ||
        text.contains('state') ||
        text.contains('zip')) {
      iconData = Icons.location_city_outlined;
    } else if (text.contains('website')) {
      iconData = Icons.language_outlined;
    } else {
      iconData = Icons.edit_outlined;
    }

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Icon(iconData, color: Colors.grey, size: 20),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final FormQuestion question;
  final String? initial;
  final void Function(String?) onSaved;
  const _DropdownField({
    super.key,
    required this.question,
    required this.initial,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    String? current = initial;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(question: question),
        const SizedBox(height: 8),
        StatefulBuilder(
          builder: (context, setState) {
            return Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButtonFormField<String>(
                    menuMaxHeight: 300,
                    items:
                        question.options
                            .map(
                              (o) => DropdownMenuItem(
                                value: o,
                                child: Text(
                                  o,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    value:
                        current != null && question.options.contains(current)
                            ? current
                            : null,
                    onChanged: (v) => setState(() => current = v),
                    onSaved: onSaved,
                    validator:
                        (v) =>
                            (question.required && (v == null || v.isEmpty))
                                ? 'Required'
                                : null,
                    decoration: InputDecoration(
                      hintText: 'Select Value',
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
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    isExpanded: true,
                    itemHeight: 48,
                    dropdownColor: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CheckboxField extends StatefulWidget {
  final FormQuestion question;
  final bool initial;
  final void Function(bool) onSaved;
  const _CheckboxField({
    super.key,
    required this.question,
    required this.initial,
    required this.onSaved,
  });
  @override
  State<_CheckboxField> createState() => _CheckboxFieldState();
}

class _CheckboxFieldState extends State<_CheckboxField> {
  late bool value = widget.initial;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(question: widget.question),
        const SizedBox(height: 4),
        Theme(
          data: Theme.of(context).copyWith(
            checkboxTheme: CheckboxThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              fillColor: WidgetStateProperty.resolveWith<Color>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).primaryColor;
                }
                return Colors.white;
              }),
            ),
          ),
          child: CheckboxListTile(
            value: value,
            onChanged: (v) {
              setState(() => value = v ?? false);
              widget.onSaved(v ?? false);
            },
            title: Text(
              widget.question.questionText,
              style: const TextStyle(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        // Hook into form save/validate
        Builder(
          builder: (context) {
            return Visibility(
              visible: false,
              child: TextFormField(
                initialValue: value.toString(),
                validator:
                    (_) =>
                        (widget.question.required && !value)
                            ? 'Required'
                            : null,
                onSaved: (_) => widget.onSaved(value),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RadioField extends StatefulWidget {
  final FormQuestion question;
  final String? initial;
  final void Function(String?) onSaved;
  const _RadioField({
    super.key,
    required this.question,
    required this.initial,
    required this.onSaved,
  });
  @override
  State<_RadioField> createState() => _RadioFieldState();
}

class _RadioFieldState extends State<_RadioField> {
  String? value;
  @override
  void initState() {
    super.initState();
    value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(question: widget.question),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              radioTheme: RadioThemeData(
                fillColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).primaryColor;
                  }
                  return Colors.grey.shade400;
                }),
              ),
            ),
            child: Column(
              children:
                  widget.question.options
                      .map(
                        (opt) => RadioListTile<String>(
                          dense: true,
                          title: Text(
                            opt,
                            style: const TextStyle(fontSize: 14),
                          ),
                          value: opt,
                          groupValue: value,
                          onChanged: (v) {
                            setState(() => value = v);
                            widget.onSaved(value);
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
        // Hook into form save/validate
        Builder(
          builder: (context) {
            return Visibility(
              visible: false,
              child: TextFormField(
                initialValue: value ?? '',
                validator:
                    (_) =>
                        (widget.question.required &&
                                (value == null || value!.isEmpty))
                            ? 'Required'
                            : null,
                onSaved: (_) => widget.onSaved(value),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ImageInputField extends StatefulWidget {
  final FormQuestion question;
  final dynamic initial;
  final void Function(dynamic) onSaved;
  final String formMediaPath;
  final String formToken;

  const _ImageInputField({
    super.key,
    required this.question,
    required this.initial,
    required this.onSaved,
    required this.formMediaPath,
    required this.formToken,
  });
  @override
  State<_ImageInputField> createState() => _ImageInputFieldState();
}

class _ImageInputFieldState extends State<_ImageInputField> {
  String? fileUrl; // URL of the file if already uploaded
  Uint8List? _fileBytes; // File bytes if selected but not uploaded
  String? _fileName; // Name of the selected file
  String? _fileType; // Type of the selected file
  int? _fileSize; // Size of the file in bytes
  bool _isUploading = false; // Flag to indicate upload in progress
  final FormsService _formsService = FormsService();

  // Maximum file size (10MB)
  static const int MAX_FILE_SIZE = 10 * 1024 * 1024;

  // List of allowed file extensions
  final List<String> _allowedExtensions = [
    '.png',
    '.jpg',
    '.jpeg',
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.csv',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      if (widget.initial is String) {
        // If it's a URL, store it directly
        if (widget.initial.toString().startsWith('http')) {
          fileUrl = widget.initial.toString();
          _extractFileNameFromUrl(fileUrl!);
        }
        // If it's a filename (check for common file extensions)
        else if (_isLikelyFilename(widget.initial.toString())) {
          fileUrl = widget.initial.toString();
          _fileName = widget.initial.toString();
        }
        // If it's base64 data, convert to bytes
        else if (widget.initial.toString().startsWith('data:') ||
            _isBase64(widget.initial.toString())) {
          _fileBytes = _convertBase64ToBytes(widget.initial.toString());
          _fileName = 'Selected file';
          if (_fileBytes != null) {
            _fileSize = _fileBytes!.length;
          }
        }
      }
    }
  }

  // Check if a string is likely a filename by looking for common file extensions
  bool _isLikelyFilename(String str) {
    // Common file extensions we support
    final fileExtensions = [
      '.png',
      '.jpg',
      '.jpeg',
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.csv',
    ];

    // Check if the string ends with any of our supported extensions
    for (final ext in fileExtensions) {
      if (str.toLowerCase().endsWith(ext)) {
        return true;
      }
    }

    // Also check for filenames with timestamp prefixes (common server-side naming pattern)
    final filenamePattern = RegExp(
      r'\d+-[\w\s.]+\.(png|jpg|jpeg|pdf|doc|docx|xls|xlsx|csv)$',
      caseSensitive: false,
    );
    return filenamePattern.hasMatch(str);
  }

  bool _isBase64(String str) {
    try {
      base64Decode(str.replaceAll(RegExp(r'\s'), ''));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        _fileName = pathSegments.last;
      } else {
        _fileName = 'Uploaded file';
      }
    } catch (_) {
      _fileName = 'Uploaded file';
    }
  }

  Uint8List? _convertBase64ToBytes(String base64String) {
    try {
      // Remove data:image/jpeg;base64, prefix if present
      final sanitized =
          base64String.contains(',')
              ? base64String.split(',')[1]
              : base64String;
      return base64Decode(sanitized);
    } catch (e) {
      return null;
    }
  }

  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1) {
      return fileName.substring(lastDot).toLowerCase();
    }
    return '';
  }

  bool _isAllowedFile(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    return _allowedExtensions.any(
      (ext) =>
          ext.toLowerCase() == extension || ext.toLowerCase() == '.$extension',
    );
  }

  Future<void> _pickFile() async {
    try {
      // Define allowed file extensions
      List<String> allowedExtensions = [];
      for (String ext in _allowedExtensions) {
        // Remove the leading dot for FilePicker
        if (ext.startsWith('.')) {
          allowedExtensions.add(ext.substring(1));
        } else {
          allowedExtensions.add(ext);
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: true, // Ensure we get the file bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file type
        if (!_isAllowedFile(file.name)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File type not allowed. Please select a valid file.',
              ),
            ),
          );
          return;
        }

        // Validate file size
        final fileSize = file.size;
        if (fileSize > MAX_FILE_SIZE) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File is too large. Maximum size is 10MB.')),
          );
          return;
        }

        // Check if we have the bytes directly (web)
        if (file.bytes != null) {
          setState(() {
            _fileName = file.name;
            _fileType = file.extension;
            _fileBytes = file.bytes;
            _fileSize = file.size;
            fileUrl = null; // Clear the URL as we have a new file
          });

          // Automatically upload the file
          _uploadFile();
        }
        // For mobile platforms, read the file
        else if (file.path != null) {
          final fileBytes = await File(file.path!).readAsBytes();
          setState(() {
            _fileName = file.name;
            _fileType = file.extension;
            _fileBytes = fileBytes;
            _fileSize = fileBytes.length;
            fileUrl = null;
          });

          // Automatically upload the file
          _uploadFile();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _uploadFile() async {
    if (_fileBytes == null || _fileName == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // For file upload, we need to convert the bytes to base64
      final base64Data = base64Encode(_fileBytes!);

      final uploadedFileUrl = await _formsService.saveFormMedia(
        base64Data: base64Data,
        fileName: _fileName!,
        fileType:
            _fileType != null
                ? _getMimeTypeFromExtension(_fileType!)
                : _getFileTypeFromName(_fileName!),
      );

      setState(() {
        fileUrl = uploadedFileUrl;
        _isUploading = false;
      });

      // Call onSaved with the URL
      widget.onSaved(fileUrl);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('File uploaded successfully')));
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
    }
  }

  String _getFileTypeFromName(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
      case '.csv':
        return 'application/excel';
      default:
        return 'application/octet-stream';
    }
  }

  String _getMimeTypeFromExtension(String extension) {
    // Remove leading dot if present
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;

    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }

  // Format file size to human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _clearFile() {
    setState(() {
      fileUrl = null;
      _fileBytes = null;
      _fileName = null;
      _fileType = null;
      _fileSize = null;
    });

    // Clear the answer in the parent widget
    widget.onSaved(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(question: widget.question),
        const SizedBox(height: 8),

        // File preview area
        if (fileUrl != null || _fileBytes != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // If it's an image file, show the image preview
                if (fileUrl != null && _isImageFile(fileUrl!))
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.formMediaPath + fileUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                Row(
                  children: [
                    Icon(
                      _getFileIcon(_fileName ?? ''),
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fileName ?? 'Selected file',
                            style: TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_fileSize != null)
                            Text(
                              _formatFileSize(_fileSize!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Show clear button
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: _clearFile,
                    ),
                  ],
                ),

                // Show upload progress if uploading
                if (_isUploading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Uploading file...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // File selection button - only show if no file is selected
        if (fileUrl == null && _fileBytes == null)
          InkWell(
            onTap: _pickFile,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.attach_file,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Select file',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // File type hint - only show if no file is selected
        if (fileUrl == null && _fileBytes == null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Allowed: PNG, JPG, PDF, DOC, DOCX, XLS, XLSX, CSV',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Invisible field to participate in validation/save
        Visibility(
          visible: false,
          child: TextFormField(
            validator:
                (_) =>
                    (widget.question.required &&
                            fileUrl == null &&
                            _fileBytes == null)
                        ? 'Required'
                        : null,
            onSaved: (_) {
              // If we have a URL, use that directly
              if (fileUrl != null) {
                widget.onSaved(fileUrl);
              }
              // If we have file bytes but no URL, it means the file needs to be uploaded
              else if (_fileBytes != null) {
                // The file will be uploaded when the form is submitted
                // For now, we'll save the base64 data
                widget.onSaved(base64Encode(_fileBytes!));
              } else {
                widget.onSaved(null);
              }
            },
          ),
        ),
      ],
    );
  }

  bool _isImageFile(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    return extension == '.jpg' ||
        extension == '.jpeg' ||
        extension == '.png' ||
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png');
  }

  IconData _getFileIcon(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
      case '.csv':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _DateField extends StatefulWidget {
  final FormQuestion question;
  final dynamic initial; // DateTime? or String?
  final void Function(DateTime?) onSaved;
  const _DateField({
    super.key,
    required this.question,
    required this.initial,
    required this.onSaved,
  });
  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  DateTime? value;
  @override
  void initState() {
    super.initState();
    if (widget.initial is String && widget.initial.isNotEmpty) {
      value = DateTime.parse(widget.initial);
    } else if (widget.initial is DateTime) {
      value = widget.initial as DateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(
      text: value == null ? '' : _fmtDate(value!),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(question: widget.question),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select date',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(Icons.calendar_today, color: Colors.grey, size: 20),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(fontSize: 14),
          validator:
              (_) =>
                  (widget.question.required && value == null)
                      ? 'Required'
                      : null,
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Theme.of(context).primaryColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => value = picked);
              ctrl.text = _fmtDate(picked);
            }
          },
          onSaved: (_) => widget.onSaved(value),
        ),
      ],
    );
  }
}

class _TimeField extends StatefulWidget {
  final FormQuestion question;
  final dynamic initial;
  final void Function(TimeOfDay?) onSaved;
  const _TimeField({
    super.key,
    required this.question,
    required this.initial,
    required this.onSaved,
  });
  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  TimeOfDay? value;
  @override
  void initState() {
    super.initState();
    if (widget.initial is TimeOfDay) value = widget.initial as TimeOfDay;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(
      text: value == null ? '' : value!.format(context),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(question: widget.question),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select time',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(Icons.access_time, color: Colors.grey, size: 20),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(fontSize: 14),
          validator:
              (_) =>
                  (widget.question.required && value == null)
                      ? 'Required'
                      : null,
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: value ?? TimeOfDay.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Theme.of(context).primaryColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => value = picked);
              ctrl.text = picked.format(context);
            }
          },
          onSaved: (_) => widget.onSaved(value),
        ),
      ],
    );
  }
}

class _DateTimeField extends StatefulWidget {
  final FormQuestion question;
  final dynamic initial;
  final void Function(DateTime?) onSaved;
  const _DateTimeField({
    super.key,
    required this.question,
    required this.initial,
    required this.onSaved,
  });
  @override
  State<_DateTimeField> createState() => _DateTimeFieldState();
}

class _DateTimeFieldState extends State<_DateTimeField> {
  DateTime? value;
  @override
  void initState() {
    super.initState();
    if (widget.initial is String && widget.initial.isNotEmpty) {
      value = DateTime.parse(widget.initial);
    } else if (widget.initial is DateTime) {
      value = widget.initial as DateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(
      text: value == null ? '' : '${_fmtDateTime(value!)}',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(question: widget.question),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select date and time',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(Icons.event, color: Colors.grey, size: 20),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(fontSize: 14),
          validator:
              (_) =>
                  (widget.question.required && value == null)
                      ? 'Required'
                      : null,
          onTap: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Theme.of(context).primaryColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (d == null) return;
            final t = await showTimePicker(
              context: context,
              initialTime:
                  value != null
                      ? TimeOfDay.fromDateTime(value!)
                      : TimeOfDay.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Theme.of(context).primaryColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (t == null) return;

            final newDateTime = DateTime(
              d.year,
              d.month,
              d.day,
              t.hour,
              t.minute,
            );
            setState(() => value = newDateTime);

            ctrl.text = '${_fmtDateTime(newDateTime)}';
          },
          onSaved: (_) => widget.onSaved(value),
        ),
      ],
    );
  }
}

class _SignatureField extends StatefulWidget {
  final FormQuestion question;
  final dynamic initial;
  final String formMediaPath;
  final void Function(dynamic) onSaved;
  const _SignatureField({
    super.key,
    required this.question,
    required this.initial,
    required this.formMediaPath,
    required this.onSaved,
  });
  @override
  State<_SignatureField> createState() => _SignatureFieldState();
}

class _SignatureFieldState extends State<_SignatureField> {
  String? signatureToken;
  String? fileUrl; // URL of the file if already uploaded
  late SignatureController _signatureController;
  bool _isDrawMode = true;
  bool _isUploading = false; // Flag to indicate upload in progress
  final FormsService _formsService = FormsService();

  @override
  void initState() {
    super.initState();
    signatureToken = widget.initial?.toString();
    // Check if the initial value is a URL
    if (widget.initial != null && widget.initial.isNotEmpty) {
      fileUrl = widget.initial.toString();
    }
    _signatureController = SignatureController(
      penStrokeWidth: 5,

      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _exportSignature() async {
    if (_signatureController.isNotEmpty) {
      final exportedImage = await _signatureController.toPngBytes(
        // height: 300,
        // width: 300,
      );
      if (exportedImage != null) {
        setState(() {
          signatureToken = base64Encode(exportedImage);
          fileUrl = null; // Clear the URL as we have a new signature
        });

        // Automatically upload the signature
        _uploadSignature(exportedImage);
      }
    }
  }

  Future<void> _uploadSignature(Uint8List signatureBytes) async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Convert the signature to base64
      final base64Data = base64Encode(signatureBytes);

      // Use the same service as image upload
      final uploadedFileUrl = await _formsService.saveFormMedia(
        base64Data: base64Data,
        fileName: 'signature_${DateTime.now().millisecondsSinceEpoch}.png',
        fileType: 'image/png',
      );

      setState(() {
        fileUrl = uploadedFileUrl;
        _isUploading = false;
      });

      // Call onSaved with the URL
      widget.onSaved(fileUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signature uploaded successfully')),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading signature: $e')));
    }
  }

  void _showSignatureDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            height: 500,
            child: Column(
              children: [
                Text('Draw Signature'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: double.infinity,
                    height: 400, // Increased height for larger drawing area
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Signature(
                        controller: _signatureController,
                        // width: 300,
                        // height: 300,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _signatureController.clear();
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _exportSignature();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(80, 20), // Smaller button size
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(question: widget.question),
        const SizedBox(height: 8),

        // Signature preview
        if (fileUrl != null)
          // Display the uploaded signature from URL
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Image.network(
              widget.formMediaPath + fileUrl!,
              height: 190,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          )
        else if (signatureToken != null)
          // Display the local signature from memory
          Container(
            height: 200, // Increased height for larger preview
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Image.memory(
              base64Decode(signatureToken!),
              height: 190, // Adjusted for container padding
              fit: BoxFit.contain,
            ),
          ),

        // Signature button
        InkWell(
          onTap: _showSignatureDialog,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.draw_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Text(
                    signatureToken != null || fileUrl != null
                        ? 'Signature captured'
                        : 'Add signature',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          signatureToken != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
                if (signatureToken != null || fileUrl != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        signatureToken = null;
                        fileUrl = null;
                        _signatureController.clear();
                      });
                      // Clear the answer in the parent widget
                      widget.onSaved(null);
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.edit,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Show upload progress if uploading
        if (_isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Uploading signature...',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

        // Invisible field for validation/save
        Visibility(
          visible: false,
          child: TextFormField(
            validator:
                (_) =>
                    (widget.question.required &&
                            fileUrl == null &&
                            signatureToken == null)
                        ? 'Required'
                        : null,
            onSaved: (_) {
              // If we have a URL, use that directly
              if (fileUrl != null) {
                widget.onSaved(fileUrl);
              }
              // If we have signature token but no URL, it means the signature needs to be uploaded
              else if (signatureToken != null) {
                widget.onSaved(signatureToken);
              } else {
                widget.onSaved(null);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final FormQuestion question;
  const _FieldLabel({required this.question});
  @override
  Widget build(BuildContext context) {
    final txt =
        question.questionText.isEmpty ? 'Untitled' : question.questionText;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
        children: [
          TextSpan(text: txt),
          if (question.required)
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

// Very lightweight HTML-ish renderer for group descriptions that may include <p>, <ul>, <li>, <br>
class _Htmlish extends StatelessWidget {
  final String html;
  const _Htmlish(this.html);

  bool looksLikeHtml(String? s) => s != null && RegExp(r'<[^>]+>').hasMatch(s);

  String stripHtml(String s) => s.replaceAll(RegExp(r'<[^>]*>'), '');

  @override
  Widget build(BuildContext context) {
    if (looksLikeHtml(html)) {
      return Html(
        //  shrinkWrap: true,
        data: html,
      );
    } else {
      // For non-HTML text, just display it normally
      return Text(
        html.trim(),
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
      );
    }
  }
}

String _fmtDateTime(DateTime d) => DateFormat('dd MMM yyyy hh:mm a').format(d);

String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

// ===== Example usage (drop into any screen) =====
class DynamicFormScreen extends StatelessWidget {
  final String formTitle;
  final Map<String, dynamic> apiJson;
  final String formAccountNo;
  final String formToken;
  final void Function()? handleScreenNavigation;
  const DynamicFormScreen({
    super.key,
    required this.formTitle,
    required this.apiJson,
    required this.formAccountNo,
    required this.formToken,
    required this.handleScreenNavigation,
  });

  @override
  Widget build(BuildContext context) {
    // Extract form data from apiJson
    final String formAccountNo = this.formAccountNo ?? '';
    final String formToken = this.formToken ?? '';
    final List<dynamic> formContent = [apiJson['form_content']] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DynamicStepperForm.fromJson(
        apiJson,
        formAccountNo: formAccountNo,
        formToken: formToken,
        formContent: formContent,
        handleScreenNavigation: handleScreenNavigation!,
        onSubmit: (answers) {
          // For now just show JSON in a dialog
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text('Collected Answers'),
                  content: SingleChildScrollView(
                    child: Text(
                      const JsonEncoder.withIndent('  ').convert(answers),
                    ),
                  ),
                ),
          );
        },
      ),
    );
  }
}
