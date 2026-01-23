import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custom_error_dialog.dart';
import 'package:voicealerts_obs/core/widgets/custome_pdf_viewer.dart';
import 'package:voicealerts_obs/features/auth/data/services/auth_service.dart';
import '../../domain/models/agreement_model.dart';
import '../bloc/agreements_bloc.dart';
import '../bloc/agreements_event.dart';
import '../bloc/agreements_state.dart';
import 'package:voicealerts_obs/features/onboarding/domain/models/onboarding_optional_agreement_model.dart';
import 'agreement_detail_screen.dart';
import 'send_to_signee_screen.dart';

class SignedAgreementsScreen extends StatefulWidget {
  const SignedAgreementsScreen({super.key});

  @override
  State<SignedAgreementsScreen> createState() => _SignedAgreementsScreenState();
}

class _SignedAgreementsScreenState extends State<SignedAgreementsScreen> {
  Map<String, String> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) {
      _loadAllAgreements();
    });
  }

  @override
  void dispose() {
    super.dispose();
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

  void _loadAllAgreements() {
    final accountNo = _userData['accountno'] ?? '';
    final email = _userData['email'] ?? '';

    if (accountNo.isNotEmpty && email.isNotEmpty) {
      context.read<AgreementsBloc>().add(
        LoadAllAgreements(accountNo: accountNo, email: email),
      );
    } else {
      _loadUserData().then((_) {
        final accountNo = _userData['accountno'] ?? '';
        final email = _userData['email'] ?? '';
        if (accountNo.isNotEmpty && email.isNotEmpty && mounted) {
          context.read<AgreementsBloc>().add(
            LoadAllAgreements(accountNo: accountNo, email: email),
          );
        }
      });
    }
  }

  void _navigateToAgreementDetail(String pdfPath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomPdfViewer(url: pdfPath, title: title),
      ),
    );
  }

  void _navigateToUnsignedAgreementDetail(
    OnboardingOptionalAgreementModel agreement,
  ) {
    final agreementModel = AgreementModel(
      agreementAccountNo: agreement.agreementAccountNo,
      id: agreement.agreementId,
      title: agreement.title,
      isMandatory: agreement.isMandatory,
      type: agreement.agreementType,
      description: agreement.agreementInstructions,
      content: agreement.agreementContent,
      status: AgreementStatus.pending,
      signatoryDetails:
          agreement.signatoryDetails.isNotEmpty
              ? agreement.signatoryDetails.first
              : {},
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AgreementDetailScreen(
              agreement: agreementModel,
              isLastAgreement: false,
              comeFrom: 'signed_agreements',
              onRefreshOptionalAgreements: _loadAllAgreements,
            ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AgreementsBloc, AgreementsState>(
        listener: (context, state) {
          if (state.status == AgreementsStatus.error) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              CustomErrorDialog.show(
                context: context,
                onRetry: () {
                  Navigator.pop(context);
                  _loadAllAgreements();
                },
              );
            });
          }
        },
        builder: (context, state) {
          // Load agreements when state is initial (never loaded)
          if (state.status == AgreementsStatus.initial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final currentState =
                    context.read<AgreementsBloc>().state.status;
                if (currentState == AgreementsStatus.initial) {
                  _loadAllAgreements();
                }
              }
            });
          }

          if (state.status == AgreementsStatus.loadingAllAgreements) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == AgreementsStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Something went wrong Please try again',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _loadAllAgreements();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.status == AgreementsStatus.loadedAllAgreements) {
            final allAgreements = <Map<String, dynamic>>[];

            // Add signed agreements
            for (var agreement in state.allSignedAgreements) {
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
                'isApproved': agreement.isApproved,
                'isMandatory': agreement.isMandatory,
                'type': 'MSA', // Default type for signed agreements
              });
            }

            // Add unsigned optional agreements
            for (var agreement in state.allOptionalAgreements) {
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
                  'type': agreement.agreementType,
                  'onboardingOptionalAgreement': agreement,
                });
              }
            }

            if (allAgreements.isEmpty) {
              return const Center(child: Text('No agreements found'));
            }

            return _buildAgreementsList(allAgreements, state);
          }

          return const Center(child: Text('No agreements found'));
        },
      ),
    );
  }

  Widget _buildAgreementsList(
    List<Map<String, dynamic>> agreements,
    AgreementsState state,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadAllAgreements();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: agreements.length,
        itemBuilder: (context, index) {
          final agreement = agreements[index];
          final isSigned = agreement['isSigned'] as bool? ?? false;
          if (isSigned) {
            return _buildSignedAgreementCard(agreement);
          } else {
            return _buildUnsignedAgreementCard(agreement);
          }
        },
      ),
    );
  }

  Widget _buildSignedAgreementCard(Map<String, dynamic> agreement) {
    final isSigned = agreement['isSigned'] as bool? ?? false;
    final title = agreement['title'] as String? ?? '';
    final signee = agreement['signee'] as String? ?? '';
    final date = agreement['date'] as String? ?? 'N/A';
    final email = agreement['email'] as String? ?? '';
    final pdfPath = agreement['pdfPath'] as String? ?? '';
    final agreementType = agreement['type'] as String? ?? 'MSA';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            pdfPath.isNotEmpty
                ? () => _navigateToAgreementDetail(pdfPath, title)
                : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Title with check icon and type icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color:
                          isSigned ? HexColor("#25C196") : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSigned ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    _getAgreementTypeIcon(agreementType),
                    color: _getAgreementTypeColor(agreementType),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
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
              // Signee
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
                      signee,
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
                    date,
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
                      email,
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed:
                            pdfPath.isNotEmpty
                                ? () =>
                                    _navigateToAgreementDetail(pdfPath, title)
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
    );
  }

  Widget _buildUnsignedAgreementCard(Map<String, dynamic> agreement) {
    final title = agreement['title'] as String? ?? '';
    final description =
        agreement['description'] as String? ?? 'No description available';
    final agreementType = agreement['type'] as String? ?? 'MSA';
    final optionalAgreement =
        agreement['onboardingOptionalAgreement']
            as OnboardingOptionalAgreementModel?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            optionalAgreement != null
                ? () => _navigateToUnsignedAgreementDetail(optionalAgreement)
                : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Title with type icon
              Row(
                children: [
                  Icon(
                    _getAgreementTypeIcon(agreementType),
                    color: _getAgreementTypeColor(agreementType),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description with gradient fade
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
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          // Convert signed agreement map to AgreementModel
                          final agreementModel =
                              _createAgreementModelFromSigned(agreement);
                          if (agreementModel != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => SendToSigneeScreen(
                                      agreement: agreementModel,
                                      comeFrom: 'signed_agreements',
                                      onSuccess: () {
                                        // Refresh the agreements list if needed
                                        _loadAllAgreements();
                                      },
                                    ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor("#7B7B7B"),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      onPressed:
                          optionalAgreement != null
                              ? () => _navigateToUnsignedAgreementDetail(
                                optionalAgreement,
                              )
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HexColor("#25C196"),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  IconData _getAgreementTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'NDA':
        return Icons.description_outlined;
      case 'MSA':
        return Icons.description_outlined;
      case 'KYC':
        return Icons.description_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Color _getAgreementTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'NDA':
        return Colors.indigo;
      case 'MSA':
        return Colors.indigo;
      case 'KYC':
        return Colors.indigo;
      default:
        return Colors.black;
    }
  }

  AgreementModel? _createAgreementModelFromSigned(
    Map<String, dynamic> agreement,
  ) {
    try {
      // For signed agreements, create AgreementModel from available data
      final title = agreement['title'] as String? ?? '';
      final type = agreement['type'] as String? ?? 'MSA';
      final isMandatory = agreement['isMandatory'] as bool? ?? false;
      final id = agreement['id'] as int? ?? title.hashCode;

      return AgreementModel(
        id: id,
        agreementAccountNo: '', // Not available in signed agreement
        title: title,
        description: '', // Not available in signed agreement
        type: type,
        status: AgreementStatus.signed,
        isMandatory: isMandatory,
        content: '', // Not available in signed agreement
        signatoryDetails: {},
      );
    } catch (e) {
      return null;
    }
  }
}
