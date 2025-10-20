import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custom_back_button.dart';
import 'package:voicealerts_obs/core/widgets/custom_error_dialog.dart';
import 'package:voicealerts_obs/features/agreements/domain/models/agreement_model.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/dashboard_shimmer.dart';
import 'package:voicealerts_obs/features/reports/domain/models/reports_model.dart';
import 'package:voicealerts_obs/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:voicealerts_obs/features/reports/presentation/screens/report_webview_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(LoadReportsData());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Reports'),
        // leading: CustomBackButton(
        //   onTap: () {
        //     Navigator.pop(context); // Go back
        //   },
        // ),
      ),
      body: BlocConsumer<ReportsBloc, ReportsState>(
        listener: (context, state) {
          if (state is ReportsError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              CustomErrorDialog.show(
                context: context,
                onRetry: () {
                  // Your retry logic here
                  Navigator.pop(context);
                  context.read<ReportsBloc>().add(LoadReportsData());
                },
              );
            });
          }

          if (state is ReportUrlLoaded) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        ReportWebViewScreen(url: state.url, title: state.title),
              ),
            );
          }

          if (state is ReportUrlError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // Show loading indicator
          if (state is ReportsLoading) {
            return const DashboardShimmer();
          }

          // Show URL loading indicator but keep the list visible in background
          if (state is ReportUrlLoading) {
            if (state.reportsData.isNotEmpty) {
              return Stack(
                children: [
                  _buildUnsignedAgreementsList(state.reportsData),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }
            // return const DashboardShimmer();
          }

          // Show error message
          if (state is ReportsError) {
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

          // Display reports data from any state that has it
          if (state.reportsData.isNotEmpty) {
            return _buildUnsignedAgreementsList(state.reportsData);
          }

          // Fallback if no reports are available
          return const Center(child: Text('No reports found'));
        },
      ),
    );
  }

  Widget _buildUnsignedAgreementsList(List<ReportsModel> reports) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildAgreementCard(report, index);
      },
    );
  }

  Widget _buildAgreementCard(ReportsModel report, int index) {
    String createdAt = DateFormat(
      'MMMM d yyyy',
    ).format(report.createdAt);

    String publishedAt = DateFormat(
      'MMMM d yyyy',
    ).format(report.publishedAt);
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
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
                  children: [
                    Image.asset(
                      'assets/icons/ic_report.png',
                      width: 20,
                      height: 20,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        //  agreement.title,
                        report.title,
                        style: const TextStyle(
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
                  'Created Date:',
                  createdAt,
                  AppColors.primaryColor,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Published Date:',
                  publishedAt,
                  AppColors.primaryColor,
                ),
                // const SizedBox(height: 8),
                // _buildDescription(agreement.description),
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
                    _buildActionButton(
                      icon: null,
                      labelColor: Colors.white,
                      label: capitalize(report.status),
                      fillColor: Colors.green,
                      color:
                          report.status == 'processed'
                              ? Colors.green
                              : Colors.orange,
                      onPressed: () {},
                    ),

                    _buildActionButton(
                      icon: null,
                      labelColor: Colors.white,
                      fillColor: Colors.green,
                      label:
                          report.reportStatus == 1
                              ? 'Published'
                              : 'Unpublished',
                      color:
                          report.reportStatus == 1
                              ? Colors.green
                              : Colors.orange,
                      onPressed: () {},
                    ),

                    _buildActionButton(
                      icon: Icons.visibility,
                      labelColor: Colors.black,
                      fillColor: Colors.transparent,
                      label: 'View',
                      color: AppColors.agreementCardViewBtnColor,
                      onPressed:
                          report.status == 'processed' &&
                                  report.reportStatus == 1
                              ? () {
                                context.read<ReportsBloc>().add(
                                  GetReportUrl(reportId: report.id),
                                );
                              }
                              : null,
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

  String capitalize(String value) {
    if (value.isEmpty) {
      return value; // Return the empty string if it's empty
    }
    return "${value[0].toUpperCase()}${value.substring(1)}";
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade700,
      ),
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
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
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
    required IconData? icon,
    required String label,
    required Color color,
    required Color labelColor,
    required Color fillColor,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            icon != null
                ? Icon(icon, size: 16, color: AppColors.primaryColor)
                : const SizedBox(),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: labelColor,
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'processed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'processed':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
