import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:voicealerts_obs/config/routes.dart';
import 'package:voicealerts_obs/core/constants/breakpoints.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/features/rfq/data/repositories/rfq_repository_impl.dart';
import 'package:voicealerts_obs/features/rfq/data/services/rfq_service.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_submission_model.dart';
import 'package:voicealerts_obs/features/rfq/presentation/bloc/rfq_submissions_bloc.dart';
import 'package:voicealerts_obs/features/rfq/presentation/widgets/rfq_details_bottom_sheet.dart';

/// RFQ Submissions Listing Screen
class RfqSubmissionsScreen extends StatelessWidget {
  final VoidCallback? onNavigateBack;

  const RfqSubmissionsScreen({super.key, this.onNavigateBack});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => RfqSubmissionsBloc(
            rfqRepository: RfqRepositoryImpl(rfqService: RfqService()),
          )..add(const LoadRfqSubmissions()),
      child: _RfqSubmissionsScreenContent(onNavigateBack: onNavigateBack),
    );
  }
}

class _RfqSubmissionsScreenContent extends StatelessWidget {
  final VoidCallback? onNavigateBack;

  const _RfqSubmissionsScreenContent({this.onNavigateBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () {
            if (onNavigateBack != null) {
              onNavigateBack!();
            } else {
              context.pop();
            }
          },
        ),
        title: const Text(
          'Request for Quotation',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<RfqSubmissionsBloc, RfqSubmissionsState>(
        builder: (context, state) {
          if (state.status == RfqSubmissionsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == RfqSubmissionsStatus.error) {
            return _buildErrorState(context, state.errorMessage);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<RfqSubmissionsBloc>().add(
                const RefreshRfqSubmissions(),
              );
            },
            child:
                state.submissions.isEmpty
                    ? _buildEmptyState(context)
                    : _buildSubmissionsList(context, state),
          );
        },
      ),
      floatingActionButton: BlocBuilder<
        RfqSubmissionsBloc,
        RfqSubmissionsState
      >(
        builder: (context, state) {
          // Hide FAB when there are no submissions (empty state has its own button)
          if (state.submissions.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _navigateToRfqForm(context),
            backgroundColor: AppColors.primaryColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'New RFQ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            const SizedBox(height: 16),
            Text(
              'Failed to load submissions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Please try again later',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<RfqSubmissionsBloc>().add(
                  const LoadRfqSubmissions(),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No RFQ Submissions Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first Request for Quotation to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _navigateToRfqForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create New RFQ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionsList(
    BuildContext context,
    RfqSubmissionsState state,
  ) {
    // Check if device is tablet (width >= tablet breakpoint)
    final isTablet = MediaQuery.of(context).size.width >= Breakpoints.tablet;

    if (isTablet) {
      // Grid layout for tablet (2 columns)
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: state.submissions.length,
        itemBuilder: (context, index) {
          final submission = state.submissions[index];
          return _RfqSubmissionCard(
            submission: submission,
            onViewDetails: () {
              RfqDetailsBottomSheet.show(context, submission.rfqAccountNo);
            },
            onEdit: () {
              _navigateToRfqFormForEdit(context, submission.rfqAccountNo);
            },
          );
        },
      );
    } else {
      // List layout for mobile (1 column)
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.submissions.length,
        itemBuilder: (context, index) {
          final submission = state.submissions[index];
          return _RfqSubmissionCard(
            submission: submission,
            onViewDetails: () {
              RfqDetailsBottomSheet.show(context, submission.rfqAccountNo);
            },
            onEdit: () {
              _navigateToRfqFormForEdit(context, submission.rfqAccountNo);
            },
          );
        },
      );
    }
  }

  void _navigateToRfqForm(BuildContext context) {
    context.push(AppRoutes.rfqForm).then((_) {
      // Refresh the list when returning from form
      context.read<RfqSubmissionsBloc>().add(const RefreshRfqSubmissions());
    });
  }

  void _navigateToRfqFormForEdit(BuildContext context, String rfqAccountNo) {
    context.push('${AppRoutes.rfqForm}?rfqAccountNo=$rfqAccountNo').then((_) {
      // Refresh the list when returning from form
      context.read<RfqSubmissionsBloc>().add(const RefreshRfqSubmissions());
    });
  }
}

/// RFQ Submission Card Widget
class _RfqSubmissionCard extends StatelessWidget {
  final RfqSubmission submission;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;

  const _RfqSubmissionCard({
    required this.submission,
    required this.onViewDetails,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // RFQ Account No (ID)
                  Row(
                    children: [
                      Text(
                        'ID: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        submission.rfqAccountNo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  // Status badge
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 16),

              // Created Date
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Created Date',
                value: _formatDate(submission.createdAt),
              ),
              const SizedBox(height: 12),

              // Attachment
              _buildInfoRow(
                icon: Icons.attach_file,
                label: 'Attachment',
                value: submission.hasAttachment ? 'Attached' : 'No Attachment',
                isEmpty: !submission.hasAttachment,
              ),
              const SizedBox(height: 12),

              // Updated At (if available)
              if (submission.dateUpdated != null) ...[
                _buildInfoRow(
                  icon: Icons.update,
                  label: 'Updated At',
                  value: _formatDate(submission.dateUpdated!),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text(
                        'RFQ Details',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: AppColors.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Only show Edit button if status is not completed
                  if (submission.status.toLowerCase() != 'completed') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text(
                          'Edit RFQ',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isEmpty = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isEmpty ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isEmpty ? Colors.grey.shade400 : Colors.black87,
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;

    switch (submission.status.toLowerCase()) {
      case 'submitted':
      case 'completed':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        break;
      case 'pending':
        backgroundColor = Colors.amber.shade50;
        textColor = Colors.amber.shade700;
        break;
      case 'approved':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        submission.displayStatus,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }
}
