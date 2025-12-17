// Source - https://stackoverflow.com/q
// Posted by MohammedAli Kadiwal, modified by community. See post 'Timeline' for change history
// Retrieved 2025-12-18, License - CC BY-SA 4.0

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

  List<Step> _stepper() {
    List<Step> _steps = [
      Step(
        title: const Text('Basic Details'),
        subtitle: _stepCompleted[0] ? const Text('Completed') : null,
        isActive: _currentStep >= 0,
        state: _getStepState(0),
        content: SizedBox(
          height: 400,
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
        title: const Text('Agreements'),
        subtitle:
            _stepCompleted[1]
                ? const Text('Completed')
                : (_signedAgreements.isNotEmpty
                    ? Text('${_signedAgreements.length} Signed')
                    : null),
        content: _buildAgreementsStep(),
        isActive: _currentStep >= 1,
        state: _getStepState(1),
      ),
      Step(
        title: const Text('Kyc'),
        subtitle: _stepCompleted[2] ? const Text('Completed') : null,
        content: _buildKycStep(),
        isActive: _currentStep >= 2,
        state: _getStepState(2),
      ),
      Step(
        title: const Text('Interop'),
        subtitle: _stepCompleted[3] ? const Text('Completed') : null,
        content: _buildInteropStep(),
        isActive: _currentStep >= 3,
        state: _getStepState(3),
      ),
    ];
    return _steps;
  }

  Widget _buildAgreementsStep() {
    return SizedBox(
      height: 300, // Fixed height to prevent infinite constraints
      child: BlocConsumer<AgreementsBloc, AgreementsState>(
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
      ),
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
    final unsignedCount =
        dummyAgreements.where((a) => a['isSigned'] == false).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with counts and arrow
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        Expanded(
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

    return Container(
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
                        backgroundColor: Colors.blue,
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
                        backgroundColor: Colors.grey.shade600,
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
    );
  }

  Widget _buildKycStep() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 60, color: Colors.blue.shade300),
            const SizedBox(height: 20),
            Text(
              'KYC Verification',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Complete your KYC verification to continue using all features of the platform.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Start KYC Process'),
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

  Widget _buildInteropStep() {
    return SizedBox(
      height: 300,
      child: Center(
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
