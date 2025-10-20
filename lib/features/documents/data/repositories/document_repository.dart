import 'package:voicealerts_obs/features/documents/data/services/document_service.dart';
import 'package:voicealerts_obs/features/documents/domain/models/document_model.dart';

class DocumentRepository {
  final DocumentService _documentService = DocumentService();

  Future<List<DocumentModel>> getDocuments() async {
    try {
      return await _documentService.getDocuments();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> submitDocument(int documentId, String filePath) async {
    try {
      return await _documentService.submitDocument(documentId, filePath);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadDocumentFile(String filePath) async {
    try {
      return await _documentService.uploadDocumentFile(filePath);
    } catch (e) {
      rethrow;
    }
  }
}
