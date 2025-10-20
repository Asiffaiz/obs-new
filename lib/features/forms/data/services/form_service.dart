import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/network/api_client.dart';
import 'package:voicealerts_obs/core/network/api_endpoints.dart';


class FormsService {
  final ApiClient _apiClient = ApiClient();

  // Keys for shared preferences
  static const String _tokenKey = 'client_tkn__';
  static const String _accountNoKey = 'client_acn__';
  static const String _emailKey = 'client_eml__';
  static const String _companyNameKey = 'client_comp_nme__';
  static const String _userTypeKey = 'client_user_type__';
  static const String _parentAccountNoKey = 'client_parent_accountno__';
  static const String _nameKey = 'client_name__';
  static const String _phoneKey = 'client_phone__';
  static const String _addressKey = 'client_adress__';
  static const String _titleKey = 'client_title__';
  static const String _accessTokenKey = 'api_access_token';
  static const String _tokenExpiryKey = 'api_token_expiry';

  // Get user data from shared preferences
  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> userData = {};

    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return {};
    }

    userData['token'] = prefs.getString(_tokenKey) ?? '';
    userData['accountno'] = prefs.getString(_accountNoKey) ?? '';
    userData['email'] = prefs.getString(_emailKey) ?? '';
    userData['comp_name'] = prefs.getString(_companyNameKey) ?? '';
    // userData['user_type'] = prefs.getString(_userTypeKey) ?? '';
    // userData['parent_accountno'] = prefs.getString(_parentAccountNoKey) ?? '';
    userData['name'] = prefs.getString(_nameKey) ?? '';
    userData['phone'] = prefs.getString(_phoneKey) ?? '';
    userData['address'] = prefs.getString(_addressKey) ?? '';
    userData['title'] = prefs.getString(_titleKey) ?? '';

    return userData;
  }

  // Get token from shared preferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get user email from shared preferences
  Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? '';
  }

  Future<List<dynamic>> getFormsData(
    String formAccountNo,
    String formToken,
  ) async {
    try {
      final email = await getUserEmail();
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient
          .post(ApiEndpoints.getSingleFormToSubmit, {
            'email': email,
            'accountno': accountNo,
            'form_accountno': formAccountNo,
            'form_token': formToken,
          });
      if (kDebugMode) {
        print(response.data);
      }

      if (response.statusCode == 200 && response.data['status'] == 200) {
        // Parse API response into ApiAgreementModel objects
        List<dynamic> formsData = response.data['data'] ?? [];
        if (response.data.containsKey('draft_response')) {
          final String draftResponse = response.data['draft_response'] ?? [];
          formsData[0]['draft_response'] = draftResponse;
        }
        if (response.data.containsKey('form_media_path')) {
          final String formMediaPath = response.data['form_media_path'] ?? '';
          formsData[0]['form_media_path'] = formMediaPath;
        }
           if (response.data.containsKey('progress')) {
          final String progress = response.data['progress'] ?? '0';
          formsData[0]['progress'] = progress;
        }
        if (kDebugMode) {
          print(formsData);
        }
        // Convert API models to domain models
        return formsData;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get dashboard data',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while fetching dashboard data: ${e.toString()}',
      );
    }
  }

  Future<List<dynamic>> getClientAssignedForms() async {
    try {
      final email = await getUserEmail();
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient.post(
        ApiEndpoints.getClientAssignedForms,
        {'email': email, 'accountno': accountNo},
      );

      if (kDebugMode) {
        print(response.data);
      }
      if (response.statusCode == 200 && response.data['status'] == 200) {
        // Parse API response into ApiAgreementModel objects
        final List<dynamic> formsData = response.data['data'] ?? [];

        // Convert API models to domain models
        return formsData;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get client assigned forms',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while fetching client assigned forms: ${e.toString()}',
      );
    }
  }

  Future<List<dynamic>> getFormSubmissions(String formAccountNo) async {
    try {
      final email = await getUserEmail();
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient.post(ApiEndpoints.getFormSubmissions, {
        'email': email,
        'accountno': accountNo,
        'form_accountno': formAccountNo,
      });
      print(response.data);
      if (response.statusCode == 200 && response.data['status'] == 200) {
        final List<dynamic> submissionsData = response.data['data'] ?? [];
        return submissionsData;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get form submissions',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while fetching form submissions: ${e.toString()}',
      );
    }
  }

  Future<bool> saveFormAsDraft({
    required String formAccountNo,
    required String formToken,
    required List<dynamic> formContent,
    required String formTitle,
    required String formDesc,
    required int submittedStep,
    required int totalSteps,
    required Map<String, dynamic> answers,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';
      final email = await getUserEmail();

      // Create a deep copy of the form content to modify
      final List<dynamic> formResponseData = getFormatedContent(formContent[0]);
      print(formResponseData);
      // Add answers to the form questions
      for (var block in formResponseData) {
        if (kDebugMode) {
          print(block);
        }
        if (block['questions'] != null && block['questions'] is List) {
          final questions = block['questions'] as List;
          for (var i = 0; i < questions.length; i++) {
            final question = questions[i];
            final questionId = question['id'];
            if (answers.containsKey(questionId)) {
              // Add the answer to the question
              questions[i] = {...question, 'answer': answers[questionId]};
            }
          }
        }
      }

      if (kDebugMode) {
        print(formResponseData);
      }

      final response = await _apiClient.post(ApiEndpoints.saveFormAsDraft, {
        'accountno': accountNo,
        'email': email,
        'form_accountno': formAccountNo,
        'form_token': formToken,
        'form_response': jsonEncode(formResponseData),
        'form_title': formTitle,
        'form_desc': formDesc,
        'submittedStep': submittedStep,
        'totalSteps': totalSteps,
      });
      if (kDebugMode) {
        print(response.data);
      }
      if (response.statusCode == 200 && response.data['status'] == 200) {
        return true;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to save form as draft',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while saving form as draft: ${e.toString()}',
      );
    }
  }

  Future<bool> saveForm({
    required String formAccountNo,
    required String formToken,
    required List<dynamic> formContent,
    required String formTitle,
    required String formDesc,
    required int submittedStep,
    required int totalSteps,
    required Map<String, dynamic> answers,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';
      final email = await getUserEmail();

      // Create a deep copy of the form content to modify
      final List<dynamic> formResponseData = getFormatedContent(formContent[0]);
      if (kDebugMode) {
        print(formResponseData);
      }
      // Add answers to the form questions
      for (var block in formResponseData) {
        if (kDebugMode) {
          print(block);
        }
        if (block['questions'] != null && block['questions'] is List) {
          final questions = block['questions'] as List;
          for (var i = 0; i < questions.length; i++) {
            final question = questions[i];
            final questionId = question['id'];
            if (answers.containsKey(questionId)) {
              // Add the answer to the question
              questions[i] = {...question, 'answer': answers[questionId]};
            }
          }
        }
      }

      // print(formResponseData);

      final response = await _apiClient.post(ApiEndpoints.saveForm, {
        'accountno': accountNo,
        'email': email,
        'form_accountno': formAccountNo,
        'form_token': formToken,
        'form_response': jsonEncode(formResponseData),
        // 'form_response': formResponseData,
        'form_title': formTitle,
        'form_desc': formDesc,
        'submittedStep': submittedStep,
        'totalSteps': totalSteps,
      });
      if (kDebugMode) {
        print(response.data);
      }
      if (response.statusCode == 200 && response.data['status'] == 200) {
        return true;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to save form',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while saving form: ${e.toString()}',
      );
    }
  }

  Future<String> saveFormMedia({

   
    required String base64Data,
    required String fileName,
    required String fileType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Create a temporary file from base64 data
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');

      // Process base64 data if needed
      final processedBase64 =
          base64Data.contains(',') ? base64Data.split(',')[1] : base64Data;

      // Write decoded base64 to the temp file
      await tempFile.writeAsBytes(base64Decode(processedBase64));

      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.saveFormMedia),
      );

      // Add file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // field name for the file
          tempFile.path,
        ),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Delete the temporary file
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }

      // Process the response
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 200) {
        // Return the file URL from the response
        return responseData['file_name'] ?? '';
      } else {
        throw Exception(responseData['message'] ?? 'Failed to upload file');
      }
    } catch (e) {
      throw Exception(
        'An error occurred while uploading file: ${e.toString()}',
      );
    }
  }

  getFormatedContent(String formContentStr) {
    var content = [];
    try {
      if (formContentStr.startsWith('') && formContentStr.endsWith('')) {
        formContentStr = formContentStr.substring(0, formContentStr.length - 0);
      }
      content = jsonDecode(formContentStr) as List;
    } catch (e) {
      content = const [];
    }
    return content;
  }
}
