import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:voicealerts_obs/core/network/api_client.dart';
import 'package:voicealerts_obs/core/network/api_endpoints.dart';
import 'package:voicealerts_obs/features/documents/domain/models/document_model.dart';

class DocumentService {
  final ApiClient _apiClient = ApiClient();
  static const String _accountNoKey = 'client_acn__';
  static const String _emailKey = 'client_eml__';

  Future<List<DocumentModel>> getDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_emailKey) ?? '';
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient.post(ApiEndpoints.getClientDocuments, {
        'email': email,
        'accountno': accountNo,
      });
      print(response.data);
      if (response.statusCode == 200) {
        if (response.data['status'] == 200 && response.data['data'] != null) {
          final List<dynamic> documentsData = response.data['data'];
          return documentsData
              .map((data) => DocumentModel.fromJson(data))
              .toList();
        }
      }

      throw Exception('Failed to load documents');
    } catch (e) {
      throw Exception('Error fetching documents: $e');
    }
  }

  Future<bool> submitDocument(int documentId, String filePath) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.submitDocument, {
        'document_id': documentId.toString(),
        'file_path': filePath,
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.data);
        return jsonData['status'] == 200;
      }

      return false;
    } catch (e) {
      throw Exception('Error submitting document: $e');
    }
  }

  Future<String?> uploadDocumentFile(String filePath) async {
    try {
      // Implement file upload logic similar to your existing implementation
      // This is a placeholder that should be replaced with your actual file upload code
      // final response = await _apiClient.uploadFile(
      //   ApiEndpoints.uploadDocument,
      //   filePath: filePath,
      //   fileField: 'document',
      // );

      // if (response.statusCode == 200) {
      //   final jsonData = json.decode(response.body);
      //   if (jsonData['status'] == 200 && jsonData['data'] != null) {
      //     return jsonData['data']['file_path'];
      //   }
      // }

      return null;
    } catch (e) {
      throw Exception('Error uploading document: $e');
    }
  }
}
