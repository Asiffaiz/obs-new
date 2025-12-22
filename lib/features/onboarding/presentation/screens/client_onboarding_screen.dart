import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/config/routes.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/features/agreements/presentation/bloc/agreements_bloc.dart';
import 'package:voicealerts_obs/features/agreements/presentation/bloc/agreements_event.dart';
import 'package:voicealerts_obs/features/agreements/presentation/bloc/agreements_state.dart';
import 'package:voicealerts_obs/features/agreements/domain/models/signed_agreement_model.dart';
import 'package:voicealerts_obs/features/auth/data/services/auth_service.dart';
import 'package:voicealerts_obs/features/profile/presentation/screens/client_profile_screen.dart';

class ClientOnboardingScreen extends StatefulWidget {
  const ClientOnboardingScreen({super.key});

  @override
  State<ClientOnboardingScreen> createState() => _ClientOnboardingScreenState();
}

class _ClientOnboardingScreenState extends State<ClientOnboardingScreen> {
  int _currentStep = 2;
  StepperType stepperType = StepperType.vertical;
  bool _isLoading = false;
  List<SignedAgreementModel> _signedAgreements = [];
  Map<String, String> _userData = {};

  // Dynamic onboarding configuration
  Map<String, dynamic> _onboardingSettings = {};
  List<String> _stepNames = [];
  List<bool> _stepCompleted = [];
  int _totalSteps = 0;
  int _progress = 0;

  // Form data cache (formId -> form submissions)
  Map<String, List<Map<String, dynamic>>> _formDataCache = {};

  @override
  void initState() {
    super.initState();
    _loadOnboardingSettings();
    _loadSignedAgreements();
    _loadUserData();
  }

  void _loadOnboardingSettings() {
    // Mock JSON data - replace with actual API call
    final jsonResponse = {
      "steps": {
        "Basic Information": {
          "form": "",
          "allowSkip": 0,
          "enable": 0,
          "isFilled": 1,
          "type": "basic",
        },
        "Agreement Terms": {
          "form": "",
          "allowSkip": 0,
          "enable": 0,
          "isFilled": 1,
          "type": "agreement",
        },
        "New KYC": {
          "form": "336586336586",
          "allowSkip": 1,
          "enable": 0,
          "isFilled": 1,
          "type": "form",
        },
        "Interop": {
          "form": "336586336587",
          "allowSkip": 1,
          "enable": 0,
          "isFilled": 0,
          "type": "form",
        },
        "Security": {
          "form": "336586336588",
          "allowSkip": 1,
          "enable": 0,
          "isFilled": 0,
          "type": "form",
        },
        "Data Protection": {
          "form": "336586336589",
          "allowSkip": 1,
          "enable": 0,
          "isFilled": 0,
          "type": "form",
        },
      },
      "total_steps": 6,
      "progress": 2, // 2 steps completed
    };

    setState(() {
      _onboardingSettings = jsonResponse['steps'] as Map<String, dynamic>;
      _stepNames = _onboardingSettings.keys.toList();
      _totalSteps = jsonResponse['total_steps'] as int;
      _progress = jsonResponse['progress'] as int;

      // Set completion based on isFilled from API
      _stepCompleted = List.generate(_stepNames.length, (index) {
        final stepName = _stepNames[index];
        final stepConfig = _onboardingSettings[stepName];
        return (stepConfig['isFilled'] as int) == 1;
      });
    });

    // Load form data for steps with form IDs
    _loadFormsData();
  }

  void _loadFormsData() {
    // Load dummy form data for each form
    _onboardingSettings.forEach((stepName, config) {
      final formId = config['form'] as String;
      if (formId.isNotEmpty) {
        // Mock form submissions - replace with actual API call
        setState(() {
          _formDataCache[formId] = _getDummyFormData(formId);
        });
      }
    });
  }

  List<Map<String, dynamic>> _getDummyFormData(String formId) {
    // Dynamic form data mapping - replace with actual API call
    final Map<String, List<Map<String, dynamic>>> formsData = {
      "336586336586": [
        {
          'title': 'Know Your Customers',
          'signee': 'James Smith',
          'date': 'June 14 2025',
          'email': 'James@tcpaas.com',
          'status': 'Submitted',
        },
      ],
      "336586336587": [
        {
          'title': 'Interop Configuration',
          'description':
              'Configure your interop settings to connect with external systems. This form helps you set up integration points and data exchange protocols.',
        },
      ],
      "336586336588": [
        {
          'title': 'Security',
          'description':
              'Configure your security settings to protect your data and systems. Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown Lorem Ipsum has been the industry\'s standard dummy',
        },
      ],
      "336586336589": [
        {
          'title': 'Data Protection',
          'description':
              'Configure your data protection settings to protect your data and systems. Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown Lorem Ipsum has been the industry\'s standard dummy',
        },
      ],
    };

    // Return form data for the given formId, or empty list if not found
    return formsData[formId] ?? [];
  }

  void _loadSignedAgreements() {
    context.read<AgreementsBloc>().add(const LoadSignedAgreements());
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final userData = await authService.getUserData();
    if (mounted) {
      setState(() {
        _userData = userData;
      });
    }
  }

  // Skip current step (if allowed)
  void _skipStep(int stepIndex) {
    setState(() {
      _stepCompleted[stepIndex] = true;
      _progress++;

      // Check if this was the last step
      if (_progress >= _totalSteps) {
        _completeOnboarding();
      } else if (stepIndex < _stepNames.length - 1) {
        // Move to next step
        _currentStep = stepIndex + 1;
      }
    });
  }

  // Mark step as complete and move to next or finish
  void _completeStep(int stepIndex) {
    setState(() {
      _stepCompleted[stepIndex] = true;
      _progress++;

      // Update the config
      final stepName = _stepNames[stepIndex];
      _onboardingSettings[stepName]['isFilled'] = 1;

      // Check if this was the last step
      if (_progress >= _totalSteps) {
        _completeOnboarding();
      } else if (stepIndex < _stepNames.length - 1) {
        // Move to next step
        _currentStep = stepIndex + 1;
      }
    });
  }

  // Complete onboarding and navigate to home
  Future<void> _completeOnboarding() async {
    // Show success popup with animation
    await _showSuccessPopup();

    // Save completion status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('client_onboarding_complete', true);

    // Navigate with smooth transition
    if (mounted) {
      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 300));
      context.go(AppRoutes.home);
    }
  }

  // Show animated success popup
  Future<void> _showSuccessPopup() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const OnboardingSuccessDialog();
      },
    );
  }

  // Determine the step state - use indexed for all to let stepIconBuilder handle visuals
  StepState _getStepState(int stepIndex) {
    // Always return indexed so our custom stepIconBuilder has full control
    return StepState.indexed;
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Welcome Onboarding'),
        actions: [
          TextButton(
            onPressed: _completeOnboarding,
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: -13,
                  right: -20,
                  bottom: 0,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: const Color(
                          0xFF007BFF,
                        ), // Blue for current uncompleted
                        onPrimary: Colors.white,
                        // Use secondary color for completed steps
                        secondary: const Color(
                          0xFF25C196,
                        ), // Green for completed
                        onSecondary: Colors.white,
                      ),
                    ),

                    child: Stepper(
                      margin: const EdgeInsets.all(0),
                      steps: _stepper(),
                      clipBehavior: Clip.none,
                      type: stepperType,
                      currentStep: _currentStep,
                      // Custom connector color based on step state
                      connectorColor: WidgetStateProperty.resolveWith<Color>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.error) ||
                            states.contains(WidgetState.focused) ||
                            states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.selected)) {
                          return Color(0xFF25C196);
                        }
                        // Check if this is a completed step
                        // if (states.contains(WidgetState.selected)) {
                        //   return const Color(0xFF25C196); // Green for completed
                        // }
                        return Colors.grey.shade300;
                      }),
                      // Custom step icon builder to control individual step colors
                      stepIconBuilder: (stepIndex, stepState) {
                        // Determine color and icon based on step completion and selection
                        final bool isCompleted =
                            _stepCompleted[stepIndex] == true;
                        final bool isCurrent = _currentStep == stepIndex;

                        Color bgColor;
                        Widget iconChild;

                        if (isCompleted) {
                          // Completed step - show green checkmark with Lottie animation
                          bgColor = const Color(0xFF25C196);
                          // Old icon animation code (commented out)
                          // iconChild = TweenAnimationBuilder<double>(
                          //   key: ValueKey('check_$stepIndex'),
                          //   duration: const Duration(milliseconds: 800),
                          //   tween: Tween(begin: 0.0, end: 1.0),
                          //   curve: Curves.elasticOut,
                          //   builder: (context, value, child) {
                          //     return Transform.scale(
                          //       scale: value,
                          //       child: Transform.rotate(
                          //         angle: value * 6.28, // Full rotation
                          //         child: const Icon(
                          //           Icons.check,
                          //           color: Colors.white,
                          //           size: 18,
                          //         ),
                          //       ),
                          //     );
                          //   },
                          // );
                          // New Lottie animation with fallback to icon
                          iconChild = _AnimatedCheckmark(
                            key: ValueKey('check_$stepIndex'),
                          );
                        } else if (isCurrent) {
                          // Current uncompleted step - show blue circle with number
                          bgColor = const Color(0xFF007BFF);
                          iconChild = Center(
                            child: Text(
                              '${stepIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        } else {
                          // Inactive uncompleted step - show grey circle with number
                          bgColor = Colors.grey.shade400;
                          iconChild = Center(
                            child: Text(
                              '${stepIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: bgColor,
                            shape: BoxShape.circle,
                          ),
                          child: iconChild,
                        );
                      },
                      controlsBuilder: (
                        BuildContext context,
                        ControlsDetails details,
                      ) {
                        return const SizedBox.shrink(); // Hide default buttons
                      },
                      onStepTapped: (step) {
                        setState(() {
                          _currentStep = step;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  steperTitleStyle() {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    );
  }

  steperStepNumberStyle() {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Colors.grey.shade600,
    );
  }

  List<Step> _stepper() {
    if (_stepNames.isEmpty) {
      return []; // Return empty if settings not loaded yet
    }

    List<Step> steps = [];

    for (int i = 0; i < _stepNames.length; i++) {
      final stepName = _stepNames[i];
      final config = _onboardingSettings[stepName];
      final stepType = config['type'] as String;
      final formId = config['form'] as String;
      final allowSkip = (config['allowSkip'] as int) == 1;
      final isFilled = (config['isFilled'] as int) == 1;
      Widget stepContent;

      // Determine content based on step type
      switch (stepType) {
        case 'basic':
          stepContent = _buildBasicDetailsStep();
          break;
        case 'agreement':
          stepContent = _buildAgreementsStep();
          break;
        case 'form':
          stepContent = _buildFormStep(formId, stepName, i, isFilled);
          break;
        default:
          stepContent = Center(child: Text('Unknown step type: $stepType'));
      }

      // Build subtitle with skip option if allowed
      Widget? subtitle;
      Widget? skipButton;
      if (_stepCompleted[i]) {
        subtitle = steperSubtitleStyle();
      } else if (allowSkip && _currentStep == i && !isFilled) {
        skipButton = Row(
          children: [
            InkWell(
              onTap: () => _skipStep(i),
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 12,
                  color: HexColor("#136FD4"),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
      }

      steps.add(
        Step(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step ${i + 1}'.toUpperCase(),
                style: steperStepNumberStyle(),
              ),
              Text(stepName, style: steperTitleStyle()),
            ],
          ),
          subtitle: subtitle,
          isActive: _currentStep >= i,
          state: _getStepState(i),
          content: AnimatedSize(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: stepContent,
            ),
          ),
        ),
      );
    }

    return steps;
  }

  Widget _buildBasicDetailsStep() {
    return Transform.translate(
      offset: const Offset(-20, 0),
      child: SizedBox(
        // height: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.appButtonColor,
                          child: Text(
                            _userData['name']?.isNotEmpty == true
                                ? _userData['name']![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name and Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData['name'] ?? 'User',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userData['email'] ?? 'email@example.com',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Additional Info
                    if (_userData['comp_name']?.isNotEmpty == true) ...[
                      _buildInfoRow(
                        'Company',
                        _userData['comp_name'] ?? '',
                        Icons.business,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_userData['phone']?.isNotEmpty == true) ...[
                      _buildInfoRow(
                        'Phone',
                        _userData['phone'] ?? '',
                        Icons.phone,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_userData['accountno']?.isNotEmpty == true)
                      _buildInfoRow(
                        'Account No',
                        _userData['accountno'] ?? '',
                        Icons.account_circle,
                      ),
                    const SizedBox(height: 20),
                    // Edit Button
                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to full profile screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClientProfileScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appButtonColor,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  steperSubtitleStyle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: HexColor("##25C196").withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text('Completed', style: TextStyle(color: HexColor("#25C196"))),
    );
  }

  Widget _buildAgreementsStep() {
    return BlocConsumer<AgreementsBloc, AgreementsState>(
      listener: (context, state) {
        if (state.status == AgreementsStatus.loadedSignedAgreements) {
          setState(() {
            _signedAgreements = state.signedAgreements;
            _isLoading = false;
          });
        } else if (state.status == AgreementsStatus.loadingSignedAgreements) {
          setState(() {
            _isLoading = true;
          });
        } else if (state.status == AgreementsStatus.error) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load agreements')),
          );
        }
      },
      builder: (context, state) {
        if (_isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (_signedAgreements.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No signed agreements found')),
          );
        }

        return _buildSignedAgreementsList(_signedAgreements);
      },
    );
  }

  Widget _buildSignedAgreementsList(List<SignedAgreementModel> agreements) {
    // For now, show dummy data
    final dummyAgreements = [
      {
        'id': 1,
        'title': 'Mailer Service Agreement',
        'signee': 'James Smith',
        'date': 'June 14 2025',
        'email': 'James@tcpaas.com',
        'isSigned': true,
      },
      {
        'id': 2,
        'title': 'Service Level Agreement',
        'description':
            'This is a description of the service level agreement, it is a long description of the service level agreement that is used to describe the service level agreement.',
        'date': 'June 10 2025',
        'email': 'john@tcpaas.com',
        'isSigned': false,
      },
      {
        'id': 3,
        'title': 'Privacy Policy Agreement',
        'signee': 'Jane Smith',
        'date': 'June 12 2025',
        'email': 'jane@tcpaas.com',
        'isSigned': true,
      },
      {
        'id': 4,
        'title': 'Terms of Service',
        'signee': 'Bob Wilson',
        'date': 'June 08 2025',
        'email': 'bob@tcpaas.com',
        'isSigned': true,
      },
      {
        'id': 5,
        'title': 'Data Processing Agreement',
        'signee': 'Alice Brown',
        'date': 'June 15 2025',
        'email': 'alice@tcpaas.com',
        'isSigned': true,
      },
    ];

    final signedCount =
        dummyAgreements.where((a) => a['isSigned'] == true).length;
    final unsignedCount =
        dummyAgreements.where((a) => a['isSigned'] == false).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // Header with counts and arrow
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: HexColor("#25C196").withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '0$signedCount Signed',
                    style: TextStyle(
                      color: HexColor("##25C196"),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '0$unsignedCount Unsigned',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Horizontal scrollable list of cards
        Transform.translate(
          offset: const Offset(-20, 0),
          child: SizedBox(
            height: 200, // Fixed height for the horizontal scrollable list
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: dummyAgreements.length,
              itemBuilder: (context, index) {
                final agreement = dummyAgreements[index];
                if (agreement['isSigned'] == true) {
                  return _buildSignedAgreementCardHorizontal(agreement);
                } else {
                  return _buildUnsignedAgreementCardHorizontal(agreement);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnsignedAgreementCardHorizontal(Map<String, dynamic> agreement) {
    final title = agreement['title'] as String;
    final description = agreement['description'] as String;

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.81,
        margin: const EdgeInsets.only(right: 9, left: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    height: 73,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.7),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor("#136FD4"),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ), // Remove all padding
                          minimumSize:
                              Size.zero, // Remove minimum size constraints
                          tapTargetSize:
                              MaterialTapTargetSize
                                  .shrinkWrap, // Reduce tap target
                        ),
                        child: const Text(
                          'Download',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Spacer(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor("#7B7B7B"),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ), // Remove all padding
                          minimumSize:
                              Size.zero, // Remove minimum size constraints
                          tapTargetSize:
                              MaterialTapTargetSize
                                  .shrinkWrap, // Reduce tap target
                        ),

                        child: const Text(
                          'Send to Signee',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HexColor("#25C196"),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                        ), // Remove all padding
                        minimumSize:
                            Size.zero, // Remove minimum size constraints
                        tapTargetSize:
                            MaterialTapTargetSize
                                .shrinkWrap, // Reduce tap target
                      ),

                      child: const Text(
                        'Sign',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignedAgreementCardHorizontal(Map<String, dynamic> agreement) {
    final isSigned = agreement['isSigned'] as bool;

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.81,
        margin: const EdgeInsets.only(right: 9, left: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Title with check icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color:
                          isSigned
                              ? HexColor("##25C196")
                              : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSigned ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      agreement['title'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Signee and Date in single row
              Row(
                children: [
                  const Text(
                    'Signee: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      agreement['signee'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Date
              Row(
                children: [
                  const Text(
                    'Date: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    agreement['date'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Email
              Row(
                children: [
                  const Text(
                    'Email: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      agreement['email'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor("#136FD4"),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Download',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor("#7B7B7B"),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormStep(
    String formId,
    String stepName,
    int stepIndex,
    isFilled,
  ) {
    // Get form submission from cache (single entry)
    final formSubmissions = _formDataCache[formId] ?? [];

    if (formSubmissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('No data available for $stepName'),
        ),
      );
    }

    // Get the first (and only) form submission
    final submission = formSubmissions.first;

    // Display single card without ListView
    return _buildFormCard(submission, stepIndex, isFilled);
  }

  Widget _buildFormCard(Map<String, dynamic> form, int stepIndex, isFilled) {
    final title = form['title'] as String;

    return Transform.translate(
      offset: const Offset(-20, 0), // Move left by 10 pixels
      child: Container(
        width:
            MediaQuery.of(
              context,
            ).size.width, // Full width since it's not in a list
        height: 200, // Fixed height for consistent UI
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Content based on filled status
              Expanded(
                child:
                    isFilled
                        ? _buildFilledFormContent(form)
                        : _buildUnfilledFormContent(form, stepIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilledFormContent(Map<String, dynamic> form) {
    final signee = form['signee'] as String;
    final date = form['date'] as String;
    final email = form['email'] as String;
    final status = form['status'] as String;

    // Determine status color
    Color statusColor =
        status == 'Completed' ? HexColor("#25C196") : HexColor("#136FD4");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Signee
        Row(
          children: [
            const Text(
              'Signee: ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            Flexible(
              child: Text(
                signee,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Date
        // Row(
        //   children: [
        //     const Text(
        //       'Date: ',
        //       style: TextStyle(
        //         fontSize: 14,
        //         fontWeight: FontWeight.w400,
        //         color: Colors.black87,
        //       ),
        //     ),
        //     Text(
        //       date,
        //       style: const TextStyle(
        //         fontSize: 14,
        //         fontWeight: FontWeight.w600,
        //         color: Colors.blue,
        //       ),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 6),
        // Email
        Row(
          children: [
            const Text(
              'Email: ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            Flexible(
              child: Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Status
        Row(
          children: [
            const Text(
              'Status : ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 14), // Push buttons to bottom
        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor("#136FD4"),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Download',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            Spacer(),
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor("#7B7B7B"),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Add New',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor("#25C196"),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnfilledFormContent(Map<String, dynamic> form, int stepIndex) {
    final description = form['description'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Description with gradient fade effect
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  maxLines: 7,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Gradient overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.7),
                        Colors.white,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Start button - marks step as complete
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                // Mark this step as complete and move to next
                _completeStep(stepIndex);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HexColor("#136FD4"),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Animated Checkmark Widget - Shows Lottie animation then static icon
class _AnimatedCheckmark extends StatefulWidget {
  const _AnimatedCheckmark({super.key});

  @override
  State<_AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<_AnimatedCheckmark> {
  bool _showIcon = false;

  @override
  void initState() {
    super.initState();
    // Wait for Lottie animation to complete (typically 1-2 seconds)
    // Then show static icon
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _showIcon = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showIcon) {
      // Show static checkmark icon after animation completes
      return const Icon(Icons.check, color: Colors.white, size: 18);
    }

    // Show Lottie animation with larger size to fit better in circle
    return Lottie.asset(
      'assets/icons/Checked.json',
      repeat: false,
      fit: BoxFit.fill, // 🔥 THIS IS THE KEY
      animate: true,
      onLoaded: (composition) {
        // Optional: Set timer based on actual animation duration
        if (mounted) {
          Future.delayed(composition.duration, () {
            if (mounted) {
              setState(() {
                _showIcon = true;
              });
            }
          });
        }
      },
    );
  }
}

// Animated Success Dialog
class OnboardingSuccessDialog extends StatefulWidget {
  const OnboardingSuccessDialog({Key? key}) : super(key: key);

  @override
  State<OnboardingSuccessDialog> createState() =>
      _OnboardingSuccessDialogState();
}

class _OnboardingSuccessDialogState extends State<OnboardingSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000), // Slower animation
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Auto close after 4 seconds (longer display time)
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated checkmark circle
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(
                    milliseconds: 1200,
                  ), // Slower checkmark animation
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: HexColor("#25C196"),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 50 * value,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Success text
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You have successfully completed the onboarding process.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Animated progress indicator
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(
                    milliseconds: 3500,
                  ), // Slower progress bar
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            HexColor("#25C196"),
                          ),
                          minHeight: 4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Redirecting to dashboard...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
