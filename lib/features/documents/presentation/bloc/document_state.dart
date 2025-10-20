import 'package:equatable/equatable.dart';
import 'package:voicealerts_obs/features/documents/domain/models/document_model.dart';

enum DocumentStatus { initial, loading, loaded, error, uploading, uploaded }

class DocumentState extends Equatable {
  final List<DocumentModel> documents;
  final DocumentStatus status;
  final String? errorMessage;
  final bool isUploading;
  final bool uploadSuccess;

  const DocumentState({
    this.documents = const [],
    this.status = DocumentStatus.initial,
    this.errorMessage,
    this.isUploading = false,
    this.uploadSuccess = false,
  });

  DocumentState copyWith({
    List<DocumentModel>? documents,
    DocumentStatus? status,
    String? errorMessage,
    bool? isUploading,
    bool? uploadSuccess,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isUploading: isUploading ?? this.isUploading,
      uploadSuccess: uploadSuccess ?? this.uploadSuccess,
    );
  }

  @override
  List<Object?> get props => [
    documents,
    status,
    errorMessage,
    isUploading,
    uploadSuccess,
  ];
}
