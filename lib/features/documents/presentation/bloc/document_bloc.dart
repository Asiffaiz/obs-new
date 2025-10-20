import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicealerts_obs/features/documents/data/repositories/document_repository.dart';
import 'package:voicealerts_obs/features/documents/presentation/bloc/document_event.dart';
import 'package:voicealerts_obs/features/documents/presentation/bloc/document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final DocumentRepository documentRepository;

  DocumentBloc({required this.documentRepository})
    : super(const DocumentState()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<UploadDocument>(_onUploadDocument);
    on<ClearDocumentError>(_onClearDocumentError);
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    emit(state.copyWith(status: DocumentStatus.loading, errorMessage: null));

    try {
      final documents = await documentRepository.getDocuments();
      emit(state.copyWith(documents: documents, status: DocumentStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          status: DocumentStatus.error,
          errorMessage: 'Failed to load documents: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onUploadDocument(
    UploadDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(
      state.copyWith(
        isUploading: true,
        uploadSuccess: false,
        errorMessage: null,
      ),
    );

    try {
      // First upload the file
      final uploadedFilePath = await documentRepository.uploadDocumentFile(
        event.filePath,
      );

      if (uploadedFilePath == null) {
        throw Exception('Failed to upload file');
      }

      // Then submit the document with the uploaded file path
      final success = await documentRepository.submitDocument(
        event.documentId,
        uploadedFilePath,
      );

      if (success) {
        emit(state.copyWith(isUploading: false, uploadSuccess: true));

        // Reload documents to get the updated list
        add(const LoadDocuments());
      } else {
        throw Exception('Failed to submit document');
      }
    } catch (e) {
      emit(
        state.copyWith(
          isUploading: false,
          uploadSuccess: false,
          errorMessage: 'Failed to upload document: ${e.toString()}',
        ),
      );
    }
  }

  void _onClearDocumentError(
    ClearDocumentError event,
    Emitter<DocumentState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }
}
