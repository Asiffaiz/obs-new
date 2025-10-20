import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/widgets/custom_error_dialog.dart';
import 'package:voicealerts_obs/features/documents/domain/models/document_model.dart';
import 'package:voicealerts_obs/features/documents/presentation/bloc/document_bloc.dart';
import 'package:voicealerts_obs/features/documents/presentation/bloc/document_event.dart';
import 'package:voicealerts_obs/features/documents/presentation/bloc/document_state.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentModel document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  String? _selectedFilePath;
  String? _selectedFileName;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _selectedFilePath = file.path;
            _selectedFileName = file.name;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  void _submitDocument() {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    context.read<DocumentBloc>().add(
      UploadDocument(
        filePath: _selectedFilePath!,
        documentId: widget.document.documentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Details')),
      body: BlocConsumer<DocumentBloc, DocumentState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            CustomErrorDialog.show(
              context: context,
              message: 'Failed to submit document',
              subMessage: state.errorMessage!,
              onRetry: _submitDocument,
            );
            context.read<DocumentBloc>().add(const ClearDocumentError());
          }

          if (state.uploadSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document submitted successfully')),
            );

            // Go back to previous screen after a short delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context, true); // Return true to indicate success
              }
            });
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDocumentInfoCard(),
                const SizedBox(height: 24),
                if (widget.document.allowDocumentSubmission &&
                    !widget.document.submissionSubmitted)
                  _buildSubmissionSection(state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentInfoCard() {
    String formattedDate = DateFormat(
      'MMMM d, yyyy',
    ).format(widget.document.addedOn);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.document.documentTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoItem('Document ID', '#${widget.document.documentId}'),
            _buildInfoItem('File Name', widget.document.documentFile),
            _buildInfoItem('Added On', formattedDate),
            _buildInfoItem(
              'Submission Allowed',
              widget.document.allowDocumentSubmission ? 'Yes' : 'No',
            ),
            _buildInfoItem(
              'Submission Status',
              widget.document.submissionSubmitted
                  ? 'Submitted'
                  : 'Not Submitted',
            ),
            _buildInfoItem(
              'Approval Status',
              widget.document.isApproved == null
                  ? 'Pending Review'
                  : (widget.document.isApproved! ? 'Approved' : 'Rejected'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Implement document viewing functionality
                // This would typically open a PDF viewer or download the document
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening document...')),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('View Document'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionSection(DocumentState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit Document',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please upload the required document for submission',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),

            // File selection area
            InkWell(
              onTap: state.isUploading ? null : _pickFile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedFilePath != null
                          ? Icons.check_circle
                          : Icons.upload_file,
                      color:
                          _selectedFilePath != null
                              ? Colors.green
                              : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedFileName ?? 'Select a file to upload',
                        style: TextStyle(
                          color:
                              _selectedFilePath != null
                                  ? Colors.black
                                  : Colors.grey[600],
                          fontWeight:
                              _selectedFilePath != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.attach_file, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accepted formats: PDF, DOC, DOCX',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    state.isUploading || _selectedFilePath == null
                        ? null
                        : _submitDocument,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                ),
                child:
                    state.isUploading
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Uploading...'),
                          ],
                        )
                        : const Text('Submit Document'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
