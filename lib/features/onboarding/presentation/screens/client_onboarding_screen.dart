// Source - https://stackoverflow.com/q
// Posted by MohammedAli Kadiwal, modified by community. See post 'Timeline' for change history
// Retrieved 2025-12-18, License - CC BY-SA 4.0

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hexcolor/hexcolor.dart';
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
  int _currentStep = 1;
  StepperType stepperType = StepperType.vertical;
  bool _isLoading = false;
  List<SignedAgreementModel> _signedAgreements = [];
  Map<String, String> _userData = {};

  // Track which steps are completed (first 2 steps are completed by default)
  final List<bool> _stepCompleted = [true, true, false, false];

  @override
  void initState() {
    super.initState();
    _loadSignedAgreements();
    _loadUserData();
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

  // Complete onboarding and navigate to home
  // This is used by the Skip button (currently commented out but kept for future use)
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('client_onboarding_complete', true);
    if (mounted) {
      context.go(AppRoutes.home);
    }
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
        title: const Text('Client Onboarding'),
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
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: const Color(
                    0xFF007BFF,
                  ), // Blue for current uncompleted
                  onPrimary: Colors.white,
                  // Use secondary color for completed steps
                  secondary: const Color(0xFF25C196), // Green for completed
                  onSecondary: Colors.white,
                ),
              ),
              child: Stepper(
                margin: const EdgeInsets.all(0),
                steps: _stepper(),
                type: stepperType,
                currentStep: _currentStep,
                // Custom connector color based on step state
                connectorColor: MaterialStateProperty.resolveWith<Color>((
                  Set<MaterialState> states,
                ) {
                  if (states.contains(MaterialState.disabled)) {
                    return Colors.grey.shade300;
                  }
                  // Check if this is a completed step
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xFF25C196); // Green for completed
                  }
                  return const Color(0xFF007BFF); // Blue for current
                }),
                // Custom step icon builder to control individual step colors
                stepIconBuilder: (stepIndex, stepState) {
                  // Determine color and icon based on step completion and selection
                  final bool isCompleted = _stepCompleted[stepIndex] == true;
                  final bool isCurrent = _currentStep == stepIndex;

                  Color bgColor;
                  Widget iconChild;

                  if (isCompleted) {
                    // Completed step - show green checkmark (always green if completed)
                    bgColor = const Color(0xFF25C196);
                    iconChild = const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
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

                  return Container(
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
    );
  }

  steperTitleStyle() {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    );
  }

  List<Step> _stepper() {
    List<Step> _steps = [
      Step(
        title: Text('Basic Details', style: steperTitleStyle()),
        subtitle: _stepCompleted[0] ? steperSubtitleStyle() : null,
        isActive: _currentStep >= 0,
        state: _getStepState(0),
        content: SizedBox(
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
                                builder:
                                    (context) => const ClientProfileScreen(),
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
      ),
      Step(
        title: Text('Agreements', style: steperTitleStyle()),
        subtitle:
            _stepCompleted[1]
                ? steperSubtitleStyle()
                : (_signedAgreements.isNotEmpty
                    ? Text('${_signedAgreements.length} Signed')
                    : null),
        content: _buildAgreementsStep(),
        isActive: _currentStep >= 1,
        state: _getStepState(1),
      ),
      Step(
        title: Text('Kyc', style: steperTitleStyle()),
        subtitle: _stepCompleted[2] ? steperSubtitleStyle() : null,
        content: _buildKycStep(),
        isActive: _currentStep >= 2,
        state: _getStepState(2),
      ),
      Step(
        title: Text('Interop', style: steperTitleStyle()),
        subtitle: _stepCompleted[3] ? steperSubtitleStyle() : null,
        content: _buildInteropStep(),
        isActive: _currentStep >= 3,
        state: _getStepState(3),
      ),
    ];
    return _steps;
  }

  steperSubtitleStyle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),

      child: const Text('Completed'),
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
        'title': 'Mailer Service Agreement',
        'signee': 'James Smith',
        'date': 'June 14 2025',
        'email': 'James@tcpaas.com',
        'isSigned': true,
      },
      {
        'title': 'Service Level Agreement',
        'signee': 'John Doe',
        'date': 'June 10 2025',
        'email': 'john@tcpaas.com',
        'isSigned': true,
      },
      {
        'title': 'Privacy Policy Agreement',
        'signee': 'Jane Smith',
        'date': 'June 12 2025',
        'email': 'jane@tcpaas.com',
        'isSigned': true,
      },
      {
        'title': 'Terms of Service',
        'signee': 'Bob Wilson',
        'date': 'June 08 2025',
        'email': 'bob@tcpaas.com',
        'isSigned': true,
      },
      {
        'title': 'Data Processing Agreement',
        'signee': 'Alice Brown',
        'date': 'June 15 2025',
        'email': 'alice@tcpaas.com',
        'isSigned': true,
      },
    ];

    final signedCount =
        dummyAgreements.where((a) => a['isSigned'] == true).length;

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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '0$signedCount Signed',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 12,
                //     vertical: 4,
                //   ),
                //   decoration: BoxDecoration(
                //     color: Colors.red.shade50,
                //     borderRadius: BorderRadius.circular(20),
                //   ),
                //   child: Text(
                //     '0$unsignedCount Unsigned',
                //     style: TextStyle(
                //       color: Colors.red.shade400,
                //       fontWeight: FontWeight.w600,
                //       fontSize: 11,
                //     ),
                //   ),
                // ),
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
              return _buildAgreementCardHorizontal(agreement);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgreementCardHorizontal(Map<String, dynamic> agreement) {
    final isSigned = agreement['isSigned'] as bool;

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.768,
        margin: const EdgeInsets.only(right: 12, left: 0),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSigned ? Colors.green : Colors.grey.shade300,
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 35,
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 35,
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

  Widget _buildKycStep() {
    // Dummy KYC forms data
    final dummyKycForms = [
      {
        'title': 'Know Your Customers',
        'signee': 'James Smith',
        'date': 'June 14 2025',
        'email': 'James@tcpaas.com',
        'status': 'Submitted',
        'isFilled': true,
      },
      {
        'title': 'Know Your Customers',
        'description':
            'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown Lorem Ipsum has been the industry\'s standard dummy',
        'isFilled': false,
      },
      {
        'title': 'Know Your Customers',
        'signee': 'Alice Johnson',
        'date': 'June 16 2025',
        'email': 'alice@tcpaas.com',
        'status': 'Submitted',
        'isFilled': true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal scrollable list of cards
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: dummyKycForms.length,
            itemBuilder: (context, index) {
              final form = dummyKycForms[index];
              return _buildKycCard(form);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKycCard(Map<String, dynamic> form) {
    final isFilled = form['isFilled'] as bool;
    final title = form['title'] as String;

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.768,
        margin: const EdgeInsets.only(right: 12, left: 0),
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
          padding: const EdgeInsets.all(16),
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
              ),
              const SizedBox(height: 16),
              // Content based on filled status
              if (isFilled) ...[
                _buildFilledKycContent(form),
              ] else ...[
                _buildUnfilledKycContent(form),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilledKycContent(Map<String, dynamic> form) {
    final signee = form['signee'] as String;
    final date = form['date'] as String;
    final email = form['email'] as String;
    final status = form['status'] as String;

    // Determine status color
    Color statusColor = status == 'Completed' ? Colors.green : Colors.blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Date
        Row(
          children: [
            const Text(
              'Date: ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            Text(
              date,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Buttons
        Row(
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

  Widget _buildUnfilledKycContent(Map<String, dynamic> form) {
    final description = form['description'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description with gradient fade effect
        Stack(
          children: [
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              maxLines: 5,
              overflow: TextOverflow.clip,
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
        const SizedBox(height: 20),
        // Start button
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {},
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

  Widget _buildInteropStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.sync_alt, size: 60, color: Colors.purple.shade300),
            const SizedBox(height: 20),
            Text(
              'Interop Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Configure integration settings to connect with your existing systems.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings),
              label: const Text('Configure Interop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appButtonColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
