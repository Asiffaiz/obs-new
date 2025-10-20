import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custom_error_dialog.dart';
import 'package:voicealerts_obs/core/widgets/custome_pdf_viewer.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/dashboard_shimmer.dart';
import 'package:voicealerts_obs/features/forms/domain/models/form_submission_model.dart';
import 'package:voicealerts_obs/features/forms/presentation/bloc/forms_bloc.dart';
import 'package:intl/intl.dart';

class FormSubmissionsScreen extends StatefulWidget {
  final String formAccountNo;
  final String formTitle;

  const FormSubmissionsScreen({
    super.key,
    required this.formAccountNo,
    required this.formTitle,
  });

  @override
  State<FormSubmissionsScreen> createState() => _FormSubmissionsScreenState();
}

class _FormSubmissionsScreenState extends State<FormSubmissionsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FormsBloc>().add(
      LoadFormSubmissions(formAccountNo: widget.formAccountNo),
    );
  }

  void _navigateToFormSubmissionDetail(FormSubmissionModel submission) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CustomPdfViewer(
              url: submission.pdfName!,
              title: submission.formTitle,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.formTitle}')),
      body: BlocConsumer<FormsBloc, FormsState>(
        listener: (context, state) {
          if (state is FormSubmissionsError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              CustomErrorDialog.show(
                context: context,
                onRetry: () {
                  // Your retry logic here
                  Navigator.pop(context);
                  context.read<FormsBloc>().add(
                    LoadFormSubmissions(formAccountNo: widget.formAccountNo),
                  );
                },
              );
            });
          }
        },
        builder: (context, state) {
          if (state is FormSubmissionsLoading) {
            return const DashboardShimmer();
          } else if (state is FormSubmissionsLoaded) {
            return _buildSubmissionsList(state.formSubmissions);
          } else if (state is FormSubmissionsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Something went wrong Please try again',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSubmissionsList(List<FormSubmissionModel> submissions) {
    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No submissions found',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        return _buildSubmissionCard(submissions[index]);
      },
    );
  }

  Widget _buildSubmissionCard(FormSubmissionModel submission) {
    // Parse progress percentage
    double progressValue = 0.0;
    try {
      // Check if progress is in format like "1/7"
      if (submission.progress.contains('/')) {
        List<String> parts = submission.progress.split('/');
        if (parts.length == 2) {
          int current = int.tryParse(parts[0]) ?? 0;
          int total = int.tryParse(parts[1]) ?? 1;
          progressValue = current / total;
        }
      } else {
        // Handle percentage format
        String progressStr = submission.progress.replaceAll('%', '');
        progressValue = double.parse(progressStr) / 100;
      }
    } catch (e) {
      progressValue = 0.0;
    }

    // Ensure progress value is valid
    progressValue = progressValue.clamp(0.0, 1.0);
    if (progressValue.isNaN) progressValue = 0.0;

    // Format date
    String formattedSentDate = '';
    try {
      if (submission.sentOn.isNotEmpty) {
        DateTime sentDate = DateTime.parse(submission.sentOn);
        formattedSentDate = DateFormat('MMM dd, yyyy').format(sentDate);
      }
    } catch (e) {
      formattedSentDate = submission.sentOn;
    }

    String formattedSubmittedDate = '';
    if (submission.submittedOn != null && submission.submittedOn!.isNotEmpty) {
      try {
        DateTime submittedDate = DateTime.parse(submission.submittedOn!);
        formattedSubmittedDate = DateFormat(
          'MMM dd, yyyy',
        ).format(submittedDate);
      } catch (e) {
        formattedSubmittedDate = submission.submittedOn!;
      }
    } else {
      formattedSubmittedDate = 'Not submitted yet';
    }

    // return Card(
    //   margin: const EdgeInsets.only(bottom: 16),
    //   elevation: 0,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(12),
    //     side: BorderSide(color: Colors.grey.shade300),
    //   ),
    //   child: Padding(
    //     padding: const EdgeInsets.all(16),
    //     child: Column(children: []),
    //   ),
    // );

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              submission.formTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Progress indicator
            LayoutBuilder(
              builder: (context, constraints) {
                return LinearPercentIndicator(
                  lineHeight: 10,
                  percent: progressValue,
                  backgroundColor: Colors.grey[200],
                  progressColor: AppColors.primaryColor,
                  barRadius: const Radius.circular(5),
                  padding: EdgeInsets.zero,
                  width: constraints.maxWidth,
                  animation: false,
                  animationDuration: 1000,
                  alignment: MainAxisAlignment.start,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              // Convert fraction to percentage
              'Progress: ${_formatProgressAsPercentage(submission.progress)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow('Submitter', submission.submitterName),
            _buildDetailRow('Email', submission.submitterEmail),
            _buildDetailRow('Sent On', formattedSentDate),
            _buildDetailRow('Submitted', submission.submitted ? 'Yes' : 'No'),
            if (submission.submitted)
              _buildDetailRow('Submitted On', formattedSubmittedDate),
            _buildDetailRow('Status', submission.status),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (submission.pdfName != null)
                  SizedBox(
                    // width:
                    //     MediaQuery.of(context).size.width *
                    //     0.2, // set your desired width
                    height: 30, // optional height
                    child: _buildActionButton(
                      icon: Icons.visibility,
                      label: 'View',
                      onPressed: () {
                        _navigateToFormSubmissionDetail(submission);
                      },
                    ),
                  ),
                const SizedBox(width: 8),
                // if (submission.pdfName != null)
                //   SizedBox(
                //     // width:
                //     //     MediaQuery.of(context).size.width *
                //     //     0.2, // set your desired width
                //     height: 30, // optional height
                //     child: _buildActionButton(
                //       icon: Icons.download,
                //       label: 'Download',
                //       onPressed: () {
                //         // TODO: Implement download functionality
                //       },
                //     ),
                //   ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildDetailRow(String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 8),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Expanded(
  //           flex: 2,
  //           child: Text(
  //             label,
  //             style: TextStyle(
  //               fontSize: 14,
  //               color: Colors.grey[700],
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           flex: 3,
  //           child: Text(
  //             value,
  //             style: TextStyle(fontSize: 14, color: Colors.grey[900]),
  //             maxLines: 2,
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,

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

  String _formatProgressAsPercentage(String progress) {
    try {
      // Check if progress is in format like "1/7"
      if (progress.contains('/')) {
        List<String> parts = progress.split('/');
        if (parts.length == 2) {
          int current = int.tryParse(parts[0]) ?? 0;
          int total = int.tryParse(parts[1]) ?? 1;
          double percentage = (current / total) * 100;
          return '${percentage.toStringAsFixed(0)}%';
        }
      }
      // If already percentage or other format, return as is
      return progress;
    } catch (e) {
      return progress;
    }
  }
}
