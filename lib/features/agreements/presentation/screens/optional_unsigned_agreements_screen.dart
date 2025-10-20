import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custom_error_dialog.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/dashboard_shimmer.dart';
import '../../domain/models/agreement_model.dart';
import '../bloc/agreements_bloc.dart';
import '../bloc/agreements_event.dart';
import '../bloc/agreements_state.dart';
import 'agreement_detail_screen.dart';

class OptionalUnsignedAgreementsScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OptionalUnsignedAgreementsScreen({super.key, this.onComplete});

  @override
  State<OptionalUnsignedAgreementsScreen> createState() =>
      _OptionalUnsignedAgreementsScreenState();
}

class _OptionalUnsignedAgreementsScreenState
    extends State<OptionalUnsignedAgreementsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AgreementsBloc>().add(const LoadOptionalAgreements());
  }

  void _refreshOptionalAgreements() {
    context.read<AgreementsBloc>().add(const LoadOptionalAgreements());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToAgreementDetail(AgreementModel agreement, int index) {
    // Get the bloc instance before navigation
    final agreementsBloc = context.read<AgreementsBloc>();

    // Add the event to go to the specific agreement
    agreementsBloc.add(GoToAgreement(index));

    // Check if this is the last agreement
    final isLastAgreement = index == agreementsBloc.state.agreements.length - 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlocProvider.value(
              value: agreementsBloc,
              child: AgreementDetailScreen(
                agreement: agreement,
                isLastAgreement: isLastAgreement,
                onComplete: widget.onComplete,
                comeFrom: 'optional',
                onRefreshOptionalAgreements: _refreshOptionalAgreements,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        centerTitle: true,
        title: const Text('Unsigned Agreements'),
      ),
      body: BlocConsumer<AgreementsBloc, AgreementsState>(
        listener: (context, state) {
          if (state.allMandatoryAgreementsSigned && widget.onComplete != null) {
            widget.onComplete!();
          }
               if (state.status == AgreementsStatus.error) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              CustomErrorDialog.show(
                context: context,
                onRetry: () {
                  // Your retry logic here
                  Navigator.pop(context);
                  context.read<AgreementsBloc>().add(const LoadOptionalAgreements());
                },
              );
            });
          }
        },
        builder: (context, state) {
          if (state.status == AgreementsStatus.loadingOptionalAgreements) {
            return const DashboardShimmer();
          }

          if (state.status == AgreementsStatus.error) {
                 return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Something went wrong please try again',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 200,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                         context.read<AgreementsBloc>().add(const LoadOptionalAgreements());
                        },
                        child: const Text('Retry'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.agreements.isEmpty) {
            return const Center(child: Text('No agreements found'));
          }

          // Calculate progress
          final mandatoryAgreements =
              state.agreements.where((a) => a.isMandatory).toList();
          final signedMandatoryAgreements =
              mandatoryAgreements
                  .where(
                    (a) =>
                        a.status == AgreementStatus.signed ||
                        a.status == AgreementStatus.approved,
                  )
                  .toList();
          final progress =
              mandatoryAgreements.isEmpty
                  ? 1.0
                  : signedMandatoryAgreements.length /
                      mandatoryAgreements.length;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AgreementsBloc>().add(
                const LoadOptionalAgreements(),
              );
            },
            child: Column(
              children: [
                // _buildProgressIndicator(
                //   progress,
                //   signedMandatoryAgreements.length,
                //   mandatoryAgreements.length,
                // ),
                _buildHeaderTitle(),
                Expanded(child: _buildUnsignedAgreementsList(state.agreements)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'These agreements are optional but recommended.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(double progress, int signed, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Optional Agreements Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                '$signed of $total signed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: progress == 1.0 ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: progress == 1.0 ? Colors.green : Colors.blue,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress == 1.0
                ? 'All optional agreements have been signed.'
                : 'These agreements are optional but recommended.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsignedAgreementsList(List<AgreementModel> agreements) {
    // Filter for unsigned agreements (pending status)
    final unsignedAgreements =
        agreements.where((a) => a.status == AgreementStatus.pending).toList();

    if (unsignedAgreements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'All agreements have been signed!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no pending agreements that require your signature.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unsignedAgreements.length,
      itemBuilder: (context, index) {
        final agreement = unsignedAgreements[index];
        return _buildAgreementCard(agreement, index);
      },
    );
  }

  Widget _buildAgreementCard(AgreementModel agreement, int index) {
    return GestureDetector(
      onTap: () => _navigateToAgreementDetail(agreement, index),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _getAgreementTypeIcon(agreement.type),
                        color: _getAgreementTypeColor(agreement.type),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          agreement.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Type:',
                    agreement.type.toUpperCase(),
                    AppColors.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  _buildDescription(agreement.description),
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
                        value: _getStatusText(agreement.status),
                        // icon: _getStatusIcon(agreement.status),
                        color: _getStatusColor(agreement.status),
                      ),
                      // _buildStatusColumn(
                      //   title: 'Type',
                      //   value: _getTypeText(agreement.type),
                      //   icon: _getAgreementTypeIcon(agreement.type),
                      //   color: _getAgreementTypeColor(agreement.type),
                      // ),
                      _buildStatusColumn(
                        title: 'Mandatory',
                        value: agreement.isMandatory ? 'Yes' : 'No',
                        // icon:
                        //     agreement.isMandatory
                        //         ? Icons.priority_high
                        //         : Icons.check_circle_outline,
                        color:
                            agreement.isMandatory ? Colors.red : Colors.orange,
                      ),
                      _buildActionButton(
                        icon: Icons.visibility,
                        label: agreement.type.toUpperCase(),
                        color: AppColors.primaryColor,
                        onPressed:
                            () => _navigateToAgreementDetail(agreement, index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildDescription(String description) {
    return Text(
      description,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildStatusColumn({
    required String title,
    required String value,
    // required IconData icon,
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
            fontWeight: FontWeight.w500,
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
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(AgreementStatus status) {
    switch (status) {
      case AgreementStatus.pending:
        return 'Pending';
      case AgreementStatus.signed:
        return 'Signed';
      case AgreementStatus.approved:
        return 'Approved';
      case AgreementStatus.rejected:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon(AgreementStatus status) {
    switch (status) {
      case AgreementStatus.pending:
        return Icons.hourglass_empty;
      case AgreementStatus.signed:
        return Icons.check_circle_outline;
      case AgreementStatus.approved:
        return Icons.verified;
      case AgreementStatus.rejected:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(AgreementStatus status) {
    switch (status) {
      case AgreementStatus.pending:
        return Colors.orange;
      case AgreementStatus.signed:
        return Colors.green;
      case AgreementStatus.approved:
        return Colors.blue;
      case AgreementStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'NDA':
        return 'NDA';
      case 'MSA':
        return 'MSA';
      case 'KYC':
        return 'KYC';
      default:
        return 'Unknown';
    }
  }

  IconData _getAgreementTypeIcon(String type) {
    switch (type) {
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
    switch (type) {
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
}
