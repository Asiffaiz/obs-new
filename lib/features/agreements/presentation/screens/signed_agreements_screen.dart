import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custom_error_dialog.dart';
import 'package:voicealerts_obs/core/widgets/custome_pdf_viewer.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/screens/webview_content_screen.dart';
import '../../domain/models/agreement_model.dart';
import '../../domain/models/signed_agreement_model.dart';
import '../bloc/agreements_bloc.dart';
import '../bloc/agreements_event.dart';
import '../bloc/agreements_state.dart';
import 'agreement_detail_screen.dart';

class SignedAgreementsScreen extends StatefulWidget {
  const SignedAgreementsScreen({super.key});

  @override
  State<SignedAgreementsScreen> createState() => _SignedAgreementsScreenState();
}

class _SignedAgreementsScreenState extends State<SignedAgreementsScreen> {
  @override
  void initState() {
    super.initState();

    context.read<AgreementsBloc>().add(const LoadSignedAgreements());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToAgreementDetail(SignedAgreementModel agreement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                CustomPdfViewer(url: agreement.pdfPath, title: agreement.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<AgreementsBloc, AgreementsState>(
              listener: (context, state) {
                // Handle any state changes if needed
                if (state.status == AgreementsStatus.error) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    CustomErrorDialog.show(
                      context: context,
                      onRetry: () {
                        // Your retry logic here
                        Navigator.pop(context);
                        context.read<AgreementsBloc>().add(
                          const LoadSignedAgreements(),
                        );
                      },
                    );
                  });
                }
              },
              builder: (context, state) {
                if (state.status == AgreementsStatus.loadingSignedAgreements) {
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
                      ],
                    ),
                  );
                }

                if (state.signedAgreements.isEmpty) {
                  return const Center(
                    child: Text('No signed agreements found'),
                  );
                }

                return _buildSignedAgreementsList(state.signedAgreements);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedAgreementsList(List<SignedAgreementModel> agreements) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agreements.length,
      itemBuilder: (context, index) {
        final agreement = agreements[index];
        return _buildAgreementCard(agreement, index);
      },
    );
  }

  Widget _buildAgreementCard(SignedAgreementModel agreement, int index) {
    String formattedDate = DateFormat(
      'MMM d, yyyy',
    ).format(agreement.signedDate);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.agreementCardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        agreement.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2, // or more if you want
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoRow(
                      'Signee:',
                      agreement.signeeName,
                      AppColors.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Date:',
                      formattedDate,
                      AppColors.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Email:',
                  agreement.signeeEmail,
                  AppColors.primaryColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusColumn(
                      title: 'Status',
                      value: agreement.isSigned ? 'Signed' : 'Pending',
                      icon: Icons.check_circle_outline,
                      color: agreement.isSigned ? Colors.green : Colors.orange,
                    ),
                    _buildStatusColumn(
                      title: 'Approved',
                      value: agreement.isApproved ? 'Yes' : 'No',
                      icon: agreement.isApproved ? Icons.check : Icons.close,
                      color:
                          agreement.isApproved ? Colors.orange : Colors.orange,
                    ),
                    _buildStatusColumn(
                      title: 'Mandatory',
                      value: agreement.isMandatory ? 'Yes' : 'No',
                      icon:
                          agreement.isMandatory
                              ? Icons.priority_high
                              : Icons.check_circle_outline,
                      color:
                          agreement.isMandatory ? Colors.orange : Colors.orange,
                    ),
                    _buildActionButton(
                      icon: Icons.visibility,
                      label: 'View',
                      color: AppColors.agreementCardViewBtnColor,
                      onPressed: () => _navigateToAgreementDetail(agreement),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusColumn({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon(icon, size: 14, color: color),
            // const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
