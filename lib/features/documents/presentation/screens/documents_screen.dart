import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custom_error_dialog.dart';
import 'package:voicealerts_obs/core/widgets/custome_pdf_viewer.dart';
import 'package:voicealerts_obs/features/dashboard/presentation/widgets/dashboard_shimmer.dart';
import 'package:voicealerts_obs/features/documents/domain/models/document_model.dart';
import 'package:voicealerts_obs/features/documents/presentation/bloc/document_bloc.dart';
import 'package:voicealerts_obs/features/documents/presentation/bloc/document_event.dart';
import 'package:voicealerts_obs/features/documents/presentation/bloc/document_state.dart';
import 'package:voicealerts_obs/features/documents/presentation/screens/document_detail_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DocumentBloc>().add(const LoadDocuments());
  }

  void _navigateToDocumentDetail(DocumentModel document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailScreen(document: document),
      ),
    ).then((result) {
      // Reload documents when returning from detail screen if needed
      if (result == true) {
        context.read<DocumentBloc>().add(const LoadDocuments());
      }
    });
  }

  void _navigateToAgreementDetail(DocumentModel document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CustomPdfViewer(
              url: document.filePath!,
              title: document.documentTitle,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: BlocConsumer<DocumentBloc, DocumentState>(
        listener: (context, state) {
          if (state.status == DocumentStatus.error &&
              state.errorMessage != null) {
            CustomErrorDialog.show(
              context: context,

              onRetry: () {
                Navigator.pop(context);
                context.read<DocumentBloc>().add(const LoadDocuments());
              },
            );
          }
        },
        builder: (context, state) {
          if (state.status == DocumentStatus.loading) {
            return const DashboardShimmer();
          }

          if (state.status == DocumentStatus.error) {
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
                          context.read<DocumentBloc>().add(
                            const LoadDocuments(),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.documents.isEmpty) {
            return const Center(
              child: Text(
                'No documents available',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DocumentBloc>().add(const LoadDocuments());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.documents.length,
              itemBuilder: (context, index) {
                return _buildDocumentCard(state.documents[index], index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document, int index) {
    String formattedDate = DateFormat('MMMM d yyyy').format(document.addedOn);
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
                        document.documentTitle,
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
                      'Date Added:',
                      formattedDate,
                      AppColors.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoRowWithBtn(
                      'View/Download',
                      formattedDate,
                      AppColors.primaryColor,
                      _buildActionButton(
                        icon: Icons.visibility,
                        label: 'View',
                        color: AppColors.agreementCardViewBtnColor,
                        isViewSubmissionsBtn: false,
                        onPressed: () => _navigateToAgreementDetail(document),
                      ),
                    ),
                    // const SizedBox(width: 16),
                    // _buildInfoRowWithBtn(
                    //   'Submitted',
                    //   formattedDate,
                    //   AppColors.primaryColor,
                    //   _buildActionButton(
                    //     icon: Icons.upload,
                    //     label: 'Upload',
                    //     color: AppColors.agreementCardViewBtnColor,
                    //     isViewSubmissionsBtn: false,
                    //     onPressed:
                    //         document.allowDocumentSubmission
                    //             ? () => () {}
                    //             : null,
                    //   ),
                    // ),
                  ],
                ),

                const SizedBox(height: 16),
                _buildSubmissionsActionButton(
                  icon: null,
                  label: 'View Submissions',
                  color: AppColors.agreementCardViewBtnColor,
                  isViewSubmissionsBtn: true,
                  onPressed: document.submissionSubmitted ? () => () {} : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoRowWithBtn(
    String label,
    String value,
    Color color,
    Widget? btn,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 4),

        btn ?? const SizedBox.shrink(),
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
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData? icon,
    required String label,
    required Color color,
    required bool isViewSubmissionsBtn,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding:
            isViewSubmissionsBtn
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            icon != null
                ? Icon(
                  icon,
                  size: 16,
                  color:
                      onPressed != null ? AppColors.primaryColor : Colors.grey,
                )
                : const SizedBox.shrink(),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isViewSubmissionsBtn ? 14 : 12,
                color: onPressed != null ? Colors.black : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsActionButton({
    required IconData? icon,
    required String label,
    required Color color,
    required bool isViewSubmissionsBtn,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 40,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(label, style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
