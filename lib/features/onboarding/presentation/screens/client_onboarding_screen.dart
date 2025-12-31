import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/config/routes.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custome_pdf_viewer.dart';
import 'package:voicealerts_obs/features/agreements/domain/models/agreement_model.dart';
import 'package:voicealerts_obs/features/agreements/presentation/bloc/agreements_bloc.dart';
import 'package:voicealerts_obs/features/agreements/presentation/bloc/agreements_event.dart';
import 'package:voicealerts_obs/features/agreements/presentation/bloc/agreements_state.dart';
import 'package:voicealerts_obs/features/agreements/domain/models/signed_agreement_model.dart';
import 'package:voicealerts_obs/features/agreements/presentation/screens/agreement_detail_screen.dart';
import 'package:voicealerts_obs/features/auth/data/services/auth_service.dart';
import 'package:voicealerts_obs/features/forms/presentation/screens/form_submissions_screen.dart';
import 'package:voicealerts_obs/features/onboarding/presentation/bloc/onboarding_agreements_bloc.dart';
import 'package:voicealerts_obs/features/onboarding/presentation/bloc/onboarding_agreements_event.dart';
import 'package:voicealerts_obs/features/onboarding/presentation/bloc/onboarding_agreements_state.dart';
import 'package:voicealerts_obs/features/onboarding/domain/models/onboarding_signed_agreement_model.dart';
import 'package:voicealerts_obs/features/onboarding/domain/models/onboarding_optional_agreement_model.dart';
import 'package:voicealerts_obs/features/forms/presentation/screens/form_main_screen.dart';
import 'package:voicealerts_obs/features/profile/presentation/screens/client_profile_screen.dart';

class ClientOnboardingScreen extends StatefulWidget {
  const ClientOnboardingScreen({super.key});

  @override
  State<ClientOnboardingScreen> createState() => _ClientOnboardingScreenState();
}

class _ClientOnboardingScreenState extends State<ClientOnboardingScreen> {
  int _currentStep = 3;
  StepperType stepperType = StepperType.vertical;
  bool _isLoading = false;
  bool _agreementsLoaded = false; // Flag to prevent multiple API calls
  List<SignedAgreementModel> _signedAgreements = [];
  List<OnboardingSignedAgreementModel> _onboardingSignedAgreements = [];
  List<OnboardingOptionalAgreementModel> _onboardingOptionalAgreements = [];
  Map<String, String> _userData = {};

  // Dynamic onboarding configuration
  Map<String, dynamic> _onboardingSettings = {};
  List<String> _stepNames = [];
  List<bool> _stepCompleted = [];
  int _totalSteps = 0;
  int _progress = 0;

  // Form data cache (formId -> form submissions)
  Map<String, List<Map<String, dynamic>>> _formDataCache = {};

  // Scroll controller for smooth step navigation
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _stepKeys = {};

  @override
  void initState() {
    super.initState();
    _loadOnboardingSettings();
    _loadSignedAgreements();
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  _navigateToForm(String formAccountNo, String formToken) {
    if (formAccountNo != '' && formToken != '' && formToken != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => FormMainScreen(
                formAccountNo: formAccountNo,
                formToken: formToken,
                isFrom: 'onboarding',
                refreshForms: null,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Smooth fade and slide transition without bounce
            const begin = Offset(0.0, 0.05);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var slideAnimation = Tween(
              begin: begin,
              end: end,
            ).animate(CurvedAnimation(parent: animation, curve: curve));

            var fadeAnimation = Tween(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(parent: animation, curve: curve));

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(position: slideAnimation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
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

        "Brand Identity Application": {
          "form": "973318973318",
          "form_token": "6b986c43-dbc2-47c8-8c2b-3a0ed9a84809",
          'description':
              'Please submit your Brand Identity information using this form to help us protect and strengthen your brand identity. Our goal is to get your application vetted as quickly and efficiently as possible.',
          "allowSkip": 1,
          "allow_multiple": 1,
          "enable": 0,
          "isFilled": 1,
          "isSkipped": 0,
          "type": "form",
        },
        "VoiceAlerts Carrier Login": {
          "form": "9890298902",
          "form_token": "37c0f7e6-2104-41b7-9290-fcdb4a43110c",
          'description':
              'Login to your VoiceAlerts Carrier Dashboard for streamlined service management and insights.',
          "allowSkip": 1,
          "allow_multiple": 0,
          "enable": 0,
          "isFilled": 0,
          "isSkipped": 0,
          "type": "form",
        },
        "Online Business": {
          "form": "302962302962",
          "form_token": "563c891e-3986-499e-9a9f-c09d7b932a20",
          'description':
              'Online Grocery Business Introduction &amp; Feedback FormAbout Us: We are an online grocery store committed to delivering fresh, quality products straight to your doorstep. From daily essentials to seasonal produce, we make grocery shopping easy, fast, and affordable.',
          "allowSkip": 1,
          "allow_multiple": 0,
          "enable": 0,
          "isFilled": 0,
          "isSkipped": 0,
          "type": "form",
        },
      },
      "total_steps": 5,
      "progress": 2, // 2 steps completed
    };

    setState(() {
      _onboardingSettings = jsonResponse['steps'] as Map<String, dynamic>;
      _stepNames = _onboardingSettings.keys.toList();
      _totalSteps = jsonResponse['total_steps'] as int;

      // Initialize isSkipped to 0 if not present
      _onboardingSettings.forEach((stepName, config) {
        if (!config.containsKey('isSkipped')) {
          config['isSkipped'] = 0;
        }
      });

      // Set completion based on isFilled from API
      _stepCompleted = List.generate(_stepNames.length, (index) {
        final stepName = _stepNames[index];
        final stepConfig = _onboardingSettings[stepName];
        return (stepConfig['isFilled'] as int) == 1;
      });

      // Recalculate progress based on actual completed steps to ensure sync
      _progress = _stepCompleted.where((completed) => completed).length;
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
      "9890298902": [
        {
          'title': 'VoiceAlerts Carrier Login',
          'description':
              'Login to your VoiceAlerts Carrier Dashboard for streamlined service management and insights.',
        },
      ],
      "973318973318": [
        {
          'title': 'Brand Identity Application',
          'description':
              'Please submit your Brand Identity information using this form to help us protect and strengthen your brand identity. Our goal is to get your application vetted as quickly and efficiently as possible.',
        },
      ],
      "302962302962": [
        {
          'title': 'Online Business',
          'description':
              'Online Grocery Business Introduction &amp; Feedback FormAbout Us: We are an online grocery store committed to delivering fresh, quality products straight to your doorstep. From daily essentials to seasonal produce, we make grocery shopping easy, fast, and affordable.',
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

  void _loadOnboardingAgreements() {
    // Prevent multiple simultaneous calls
    if (_isLoading) {
      return;
    }

    final accountNo = _userData['accountno'] ?? '';
    final email = _userData['email'] ?? '';

    if (accountNo.isNotEmpty && email.isNotEmpty) {
      context.read<OnboardingAgreementsBloc>().add(
        LoadOnboardingAgreements(accountNo: accountNo, email: email),
      );
    } else {
      // If user data not loaded yet, load it first then load agreements
      _loadUserData().then((_) {
        final accountNo = _userData['accountno'] ?? '';
        final email = _userData['email'] ?? '';
        if (accountNo.isNotEmpty &&
            email.isNotEmpty &&
            mounted &&
            !_isLoading) {
          context.read<OnboardingAgreementsBloc>().add(
            LoadOnboardingAgreements(accountNo: accountNo, email: email),
          );
        }
      });
    }
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
  // Check if all skippable steps are skipped
  bool _areAllSkippableStepsSkipped() {
    for (int i = 0; i < _stepNames.length; i++) {
      final stepName = _stepNames[i];
      final config = _onboardingSettings[stepName];
      final allowSkip = (config['allowSkip'] as int) == 1;
      final isSkipped = (config['isSkipped'] as int? ?? 0) == 1;
      final isFilled = (config['isFilled'] as int) == 1;

      // If step is skippable but not skipped and not filled, return false
      if (allowSkip && !isSkipped && !isFilled) {
        return false;
      }
    }
    return true;
  }

  void _skipStep(int stepIndex) {
    final stepName = _stepNames[stepIndex];
    final config = _onboardingSettings[stepName];
    final isLastStep = stepIndex == _stepNames.length - 1;

    setState(() {
      // Mark current step as skipped
      config['isSkipped'] = 1;

      // Move to next step if available
      if (!isLastStep) {
        _currentStep = stepIndex + 1;
      }
    });

    // If it's the last step, check if all skippable steps are skipped
    if (isLastStep) {
      if (_areAllSkippableStepsSkipped()) {
        // All skippable steps are skipped, trigger completion flow
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _completeOnboarding();
        });
        return;
      }
    }

    // Smoothly scroll to the new step if not last
    if (!isLastStep) {
      _scrollToStep(_currentStep);
    }
  }

  // Smoothly scroll to a specific step
  void _scrollToStep(int stepIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _stepKeys[stepIndex];
      final context = key?.currentContext;
      if (context != null && _scrollController.hasClients) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.1, // Scroll to show step near top
        );
      }
    });
  }

  // Move to next step without marking current step as completed
  void _moveToNextStep(int stepIndex) {
    if (stepIndex < _stepNames.length - 1) {
      setState(() {
        // Move to next step
        _currentStep = stepIndex + 1;
      });

      // Smoothly scroll to the new step
      _scrollToStep(_currentStep);
    }

    // Check completion after setState completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndCompleteOnboarding();
    });
  }

  // Check if all steps are completed and navigate to dashboard
  void _checkAndCompleteOnboarding() {
    // Recalculate progress to ensure accuracy
    final completedCount =
        _stepCompleted.where((completed) => completed).length;
    _progress = completedCount;

    // If all steps are completed, navigate to dashboard
    if (_progress >= _totalSteps) {
      _completeOnboarding();
    }
  }

  // Mark step as complete and move to next or finish
  void _completeStep(int stepIndex) {
    setState(() {
      // Only mark as completed and increment progress if not already completed
      if (!_stepCompleted[stepIndex]) {
        _stepCompleted[stepIndex] = true;
        _progress++;
      }

      // Update the config
      final stepName = _stepNames[stepIndex];
      _onboardingSettings[stepName]['isFilled'] = 1;

      // Move to next step if available
      if (stepIndex < _stepNames.length - 1) {
        _currentStep = stepIndex + 1;
      }
    });

    // Smoothly scroll to the new step
    if (stepIndex < _stepNames.length - 1) {
      _scrollToStep(_currentStep);
    }

    // Check completion after setState completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndCompleteOnboarding();
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
          // TextButton(
          //   onPressed: _completeOnboarding,
          //   child: const Text('Skip', style: TextStyle(color: Colors.white)),
          // ),
        ],
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 8.0,
              ), // Reduced horizontal padding
              child: _CustomStepper(
                steps: _stepper(),
                currentStep: _currentStep,
                stepCompleted: _stepCompleted,
                scrollController: _scrollController,
                stepKeys: _stepKeys,
                onStepTapped: (step) {
                  setState(() {
                    _currentStep = step;
                  });
                  // Smoothly scroll to the tapped step
                  _scrollToStep(step);
                },
              ),
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
      final formToken = config['form_token'] as String? ?? '';
      final allowSkip = (config['allowSkip'] as int) == 1;
      final allowMultiple =
          (config['allow_multiple'] as int? ?? 0) == 1 &&
          (config['isFilled'] as int? ?? 0) == 1;
      final isFilled = (config['isFilled'] as int) == 1;
      print("allowMultiple: $allowMultiple");
      Widget stepContent;

      // Determine content based on step type
      switch (stepType) {
        case 'basic':
          stepContent = Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _buildBasicDetailsStep(),
          );
          break;
        case 'agreement':
          stepContent = Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _buildAgreementsStep(),
          );
          break;
        case 'form':
          stepContent = Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _buildFormStep(
              formId,
              formToken,
              stepName,
              i,
              isFilled,
              allowMultiple,
            ),
          );
          break;
        default:
          stepContent = Center(child: Text('Unknown step type: $stepType'));
      }

      // Build subtitle with skip option if allowed
      Widget? subtitle;
      Widget? skipButton;
      if (_stepCompleted[i]) {
        subtitle = steperSubtitleStyle();
      }
      if (allowSkip && _currentStep == i && !isFilled) {
        skipButton = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () => _skipStep(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: HexColor("#136FD4").withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HexColor("#136FD4"), width: 1),
                ),
                child: Text(
                  'SKIP',
                  style: TextStyle(
                    fontSize: 12,
                    color: HexColor("#136FD4"),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      } else if (_currentStep == i) {
        skipButton = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () => _moveToNextStep(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: HexColor("#136FD4").withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HexColor("#136FD4"), width: 1),
                ),
                child: Text(
                  'NEXT',
                  style: TextStyle(
                    fontSize: 12,
                    color: HexColor("#136FD4"),
                    fontWeight: FontWeight.w600,
                  ),
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
              child: Column(
                children: [
                  stepContent,
                  // skipButton != null
                  //     ? Padding(
                  //       padding: const EdgeInsets.only(top: 16, right: 24),
                  //       child: skipButton,
                  //     )
                  //     : SizedBox.shrink(),
                  Padding(
                    padding: const EdgeInsets.only(top: 16, right: 24),
                    child: skipButton,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return steps;
  }

  Widget _buildBasicDetailsStep() {
    return SizedBox(
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
    );
  }

  steperSubtitleStyle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: HexColor("##25C196").withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text('Completed', style: TextStyle(color: Colors.black)),
    );
  }

  Widget _buildAgreementsStep() {
    return BlocConsumer<OnboardingAgreementsBloc, OnboardingAgreementsState>(
      listener: (context, state) {
        if (state.status == OnboardingAgreementsStatus.loaded) {
          setState(() {
            _onboardingSignedAgreements = state.signedAgreements;
            _onboardingOptionalAgreements = state.optionalAgreements;
            _isLoading = false;
            _agreementsLoaded = true; // Mark as loaded
          });
        } else if (state.status == OnboardingAgreementsStatus.loading) {
          setState(() {
            _isLoading = true;
          });
        } else if (state.status == OnboardingAgreementsStatus.error) {
          setState(() {
            _isLoading = false;
            _agreementsLoaded = false; // Reset flag on error to allow retry
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to load agreements'),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  _agreementsLoaded = false; // Reset flag for retry
                  _loadOnboardingAgreements();
                },
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        // Load agreements when step is shown if state is initial (never loaded)
        // This will trigger on first build of the step
        if (state.status == OnboardingAgreementsStatus.initial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Double-check state hasn't changed
              final currentState =
                  context.read<OnboardingAgreementsBloc>().state.status;
              if (currentState == OnboardingAgreementsStatus.initial) {
                _loadOnboardingAgreements();
              }
            }
          });
        }

        if (state.status == OnboardingAgreementsStatus.loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show agreements list from API
        // Use bloc state data directly
        return _buildOnboardingAgreementsList(
          state.signedAgreements,
          state.optionalAgreements,
        );
      },
    );
  }

  Widget _buildOnboardingAgreementsList(
    List<OnboardingSignedAgreementModel> signedAgreements,
    List<OnboardingOptionalAgreementModel> optionalAgreements,
  ) {
    // Combine signed and optional agreements for display
    final allAgreements = <Map<String, dynamic>>[];

    // Add signed agreements
    for (var agreement in signedAgreements) {
      allAgreements.add({
        'id': agreement.title.hashCode,
        'title': agreement.title,
        'signee': agreement.signeeName,
        'date':
            agreement.signedDate != null
                ? _formatDate(agreement.signedDate!)
                : 'N/A',
        'email': agreement.signeeEmail,
        'isSigned': agreement.isSigned,
        'pdfPath': agreement.pdfPath,
      });
    }

    // Add unsigned optional agreements
    for (var agreement in optionalAgreements) {
      if (!agreement.isSigned) {
        allAgreements.add({
          'id': agreement.agreementId,
          'agreement_accountno': agreement.agreementAccountNo,
          'agreement_id': agreement.agreementId,
          'agreement_title': agreement.title,
          'is_mandatory': agreement.isMandatory,
          'agreement_type': agreement.agreementType,
          'agreement_instructions': agreement.agreementInstructions,
          'agreement_content': agreement.agreementContent,
          'signatory_details': agreement.signatoryDetails,
          'title': agreement.title,
          'description':
              agreement.agreementInstructions.isNotEmpty
                  ? agreement.agreementInstructions
                  : 'No description available',
          'isSigned': false,
        });
      }
    }

    //     var agreementModel = AgreementModel(
    //   agreementAccountNo: agreement['agreement_accountno'],
    //   id: agreement['agreement_id'],
    //   title: agreement['agreement_title'],

    //   isMandatory: agreement['is_mandatory'],

    //   type: agreement['agreement_type'],
    //   description: agreement['agreement_instructions'],
    //   content: agreement['agreement_content'],
    //   status: AgreementStatus.pending,
    //   signatoryDetails: agreement['signatory_details'],
    // );

    final signedCount =
        allAgreements.where((a) => a['isSigned'] == true).length;
    final unsignedCount =
        allAgreements.where((a) => a['isSigned'] == false).length;

    if (allAgreements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No agreements available',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with counts
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
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
                    '${signedCount.toString().padLeft(2, '0')} Signed',
                    style: TextStyle(
                      color: HexColor("#25C196"),
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
                    '${unsignedCount.toString().padLeft(2, '0')} Unsigned',
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
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: allAgreements.length,
            itemBuilder: (context, index) {
              final agreement = allAgreements[index];
              if (agreement['isSigned'] == true) {
                return _buildSignedAgreementCardHorizontal(agreement);
              } else {
                return _buildUnsignedAgreementCardHorizontal(agreement);
              }
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day} ${date.year}';
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
          mainAxisAlignment: MainAxisAlignment.end,
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
        SizedBox(
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
      ],
    );
  }

  Widget _buildUnsignedAgreementCardHorizontal(Map<String, dynamic> agreement) {
    final title = agreement['title'] as String? ?? '';
    final description =
        agreement['description'] as String? ?? 'No description available';

    var agreementModel = AgreementModel(
      agreementAccountNo: agreement['agreement_accountno'],
      id: agreement['agreement_id'],
      title: agreement['agreement_title'],

      isMandatory: agreement['is_mandatory'],

      type: agreement['agreement_type'],
      description: agreement['agreement_instructions'],
      content: agreement['agreement_content'],
      status: AgreementStatus.pending,
      signatoryDetails: {},
    );
    return Align(
      alignment: Alignment.topLeft,
      child: InkWell(
        onTap: () {
          _navigateToAgreementSignedDetail(agreementModel);
        },
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
                  maxLines: 1,
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
                          onPressed: () {
                            context.push(
                              AppRoutes.sendToSignee,
                              extra: {
                                'agreement': agreementModel,
                                'comeFrom': 'optional',
                                'onSuccess': () {
                                  // Refresh the agreements list if needed
                                  // context.read<AgreementsBloc>().add(
                                  //   const LoadAgreements(),
                                  // );
                                },
                              },
                            );
                          },
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
                        onPressed: () {
                          _navigateToAgreementSignedDetail(agreementModel);
                        },
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
      ),
    );
  }

  void _navigateToAgreementSignedDetail(AgreementModel agreement) {
    // Get the bloc instance before navigation
    // final agreementsBloc = context.read<AgreementsBloc>();

    // // Add the event to go to the specific agreement
    // agreementsBloc.add(GoToAgreement(index));

    // // Check if this is the last agreement
    // final isLastAgreement = index == agreementsBloc.state.agreements.length - 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AgreementDetailScreen(
              agreement: agreement,
              isLastAgreement: false,
              onComplete: () {},
              comeFrom: 'optional',
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
        child: InkWell(
          onTap:
              agreement['pdfPath'] != null && agreement['pdfPath'].isNotEmpty
                  ? () {
                    if (agreement['pdfPath'] != null &&
                        agreement['pdfPath'].isNotEmpty) {
                      _navigateToAgreementDetail(
                        agreement['pdfPath'] as String,
                        agreement['title'] as String,
                      );
                    }
                  }
                  : () {},
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
                        maxLines: 1,
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
                          onPressed:
                              agreement['pdfPath'] != null &&
                                      agreement['pdfPath'].isNotEmpty
                                  ? () {
                                    if (agreement['pdfPath'] != null &&
                                        agreement['pdfPath'].isNotEmpty) {
                                      _navigateToAgreementDetail(
                                        agreement['pdfPath'] as String,
                                        agreement['title'] as String,
                                      );
                                    }
                                  }
                                  : null,
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
      ),
    );
  }

  void _navigateToAgreementDetail(pdfPath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomPdfViewer(url: pdfPath, title: title),
      ),
    );
  }

  Widget _buildFormStep(
    String formId,
    String formToken,
    String stepName,
    int stepIndex,
    isFilled,
    allowMultiple,
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
    return _buildFormCard(
      submission,
      formId,
      formToken,
      stepIndex,
      isFilled,
      allowMultiple,
    );
  }

  Map<String, dynamic> updateFormData(
    Map<String, dynamic> form,
    String formId,
    String formToken,
    bool allowMultiple,
  ) {
    form['form_id'] = formId;
    form['form_token'] = formToken;
    form['allow_multiple'] = allowMultiple;
    return form;
  }

  Widget _buildFormCard(
    Map<String, dynamic> form,
    formId,
    formToken,
    int stepIndex,
    isFilled,
    allowMultiple,
  ) {
    final title = form['title'] as String;
    Map<String, dynamic> updatedForm = updateFormData(
      form,
      formId,
      formToken,
      allowMultiple,
    );

    return Container(
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
                      ? _buildFilledFormContent(updatedForm)
                      : _buildUnfilledFormContent(updatedForm, stepIndex),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilledFormContent(Map<String, dynamic> form) {
    // final signee = form['signee'] as String? ?? 'N/A';
    // final email = form['email'] as String? ?? 'N/A';
    // final status = form['status'] as String? ?? 'N/A';

    final signee = _userData['name'] as String? ?? 'N/A';
    final email = _userData['email'] as String? ?? 'N/A';
    final status = "Submitted";

    bool isAllowMultiple = form['allow_multiple'];

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
            if (isAllowMultiple)
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      _navigateToForm(
                        form['form_id'] as String,
                        form['form_token'] as String,
                      );
                    },
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
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    _handleSubmissionsNavigation(
                      form['form_id'] as String,
                      form['title'] as String,
                      context,
                    );
                  },
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

  _handleSubmissionsNavigation(
    String formAccountNo,
    String formTitle,

    BuildContext context,
  ) {
    if (formAccountNo != '' && formTitle != '') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FormSubmissionsScreen(
                formAccountNo: formAccountNo,
                formTitle: formTitle,
              ),
        ),
      );
    }
  }

  Widget _buildUnfilledFormContent(Map<String, dynamic> form, int stepIndex) {
    final description =
        form['description'] as String? ?? 'No description available';

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
                // _completeStep(stepIndex);
                _navigateToForm(
                  form['form_id'] as String,
                  form['form_token'] as String,
                );
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

// Custom Stepper Widget - Fixes padding and connector color issues
class _CustomStepper extends StatelessWidget {
  final List<Step> steps;
  final int currentStep;
  final List<bool> stepCompleted;
  final Function(int) onStepTapped;
  final ScrollController scrollController;
  final Map<int, GlobalKey> stepKeys;

  const _CustomStepper({
    required this.steps,
    required this.currentStep,
    required this.stepCompleted,
    required this.onStepTapped,
    required this.scrollController,
    required this.stepKeys,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.zero, // No padding - full control
      clipBehavior: Clip.none, // Allow shadows to extend beyond bounds
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        final isCompleted =
            index < stepCompleted.length && stepCompleted[index];
        final isCurrent = currentStep == index;

        // Ensure key exists for this step
        if (!stepKeys.containsKey(index)) {
          stepKeys[index] = GlobalKey();
        }

        return _buildStepItem(
          context,
          step,
          index,
          isLast,
          isCompleted,
          isCurrent,
        );
      },
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    Step step,
    int index,
    bool isLast,
    bool isCompleted,
    bool isCurrent,
  ) {
    return Container(
      key: stepKeys[index],
      clipBehavior: Clip.none, // Allow shadows to extend beyond bounds
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Icon Column with padding for shadow
            Padding(
              padding: const EdgeInsets.only(left: 2, right: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step Icon
                  GestureDetector(
                    onTap: () => onStepTapped(index),
                    child: _buildStepIcon(index, isCompleted, isCurrent),
                  ),
                  // Connector Line (only if not last step)
                  if (!isLast)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Container(
                          width: 2,
                          constraints: const BoxConstraints(
                            minHeight:
                                34, // Minimum height for connector visibility
                          ),
                          // Fixed connector color logic - only green if step is completed
                          color:
                              isCompleted
                                  ? const Color(
                                    0xFF25C196,
                                  ) // Green for completed
                                  : Colors
                                      .grey
                                      .shade300, // Grey for not completed
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4), // Spacing between icon and content
            // Step Content - Splash effect only on title/subtitle area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Allow column to shrink
                children: [
                  // Step Title with splash effect and animation - full width
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onStepTapped(index),
                      borderRadius: BorderRadius.circular(4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.all(isCurrent ? 4.0 : 0.0),
                        child: SizedBox(
                          width: double.infinity, // Full width
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Step Title
                              step.title,
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Step Subtitle (Completed status) - no splash effect
                  if (step.subtitle != null) step.subtitle!,
                  if (step.subtitle != null) const SizedBox(height: 8),
                  // Only show content for current step with beautiful animation
                  if (isCurrent)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.topLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [step.content],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIcon(int stepIndex, bool isCompleted, bool isCurrent) {
    Color bgColor;
    Widget iconChild;
    double scale = 1.0;

    if (isCompleted) {
      bgColor = const Color(0xFF25C196);
      iconChild = _AnimatedCheckmark(key: ValueKey('check_$stepIndex'));
      scale = 1.0;
    } else if (isCurrent) {
      bgColor = const Color(0xFF007BFF);
      scale = 1.1; // Slightly larger when current
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
      bgColor = Colors.grey.shade400;
      scale = 1.0;
      iconChild = Center(
        child: Text(
          '${stepIndex + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: scale),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  isCurrent
                      ? Border.all(color: bgColor, width: 2.5)
                      : Border.all(color: Colors.transparent, width: 2.5),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: iconChild,
              ),
            ),
          ),
        );
      },
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
