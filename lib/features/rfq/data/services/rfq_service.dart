import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/constants/network_urls.dart';
import 'package:voicealerts_obs/core/network/api_client.dart';
import 'package:voicealerts_obs/core/network/api_endpoints.dart';
import 'package:voicealerts_obs/core/services/token_service.dart';
import 'package:voicealerts_obs/features/rfq/data/utils/rfq_payload_builder.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_detail_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_product_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_submission_model.dart';

/// Service for RFQ API calls
class RfqService {
  final ApiClient _apiClient = ApiClient();
  final TokenService _tokenService = TokenService();

  // Keys for shared preferences
  static const String _accountNoKey = 'client_acn__';
  static const String _emailKey = 'client_eml__';

  /// Get user email from shared preferences
  Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? '';
  }

  /// Get account number from shared preferences
  Future<String> getAccountNo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accountNoKey) ?? '';
  }

  /// Get RFQ submissions list
  Future<List<RfqSubmission>> getRfqSubmissions() async {
    try {
      final email = await getUserEmail();
      final accountNo = await getAccountNo();

      final response = await _apiClient.post(ApiEndpoints.getRfqSubmissions, {
        'email': email,
        'accountno': accountNo,
      });

      if (kDebugMode) {
        print('RFQ Submissions Response: ${response.data}');
      }

      // Handle 404 with "no_record" - return empty list
      if (response.statusCode == 404 ||
          (response.data['status'] == 404 &&
              (response.data['errors'] == 'no_record' ||
                  response.data['message'] == 'no_record'))) {
        if (kDebugMode) {
          print('No RFQ submissions found - returning empty list');
        }
        return [];
      }

      if (response.statusCode == 200 && response.data['status'] == 200) {
        final List<dynamic> submissionsData =
            response.data['data'] as List? ?? [];
        return submissionsData
            .map((item) => RfqSubmission.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get RFQ submissions',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching RFQ submissions: $e');
      }
      throw Exception(
        'An error occurred while fetching RFQ submissions: ${e.toString()}',
      );
    }
  }

  /// Get RFQ form data from API
  Future<RfqFormDefinition> getRfqFormData() async {
    try {
      final email = await getUserEmail();
      final accountNo = await getAccountNo();

      final response = await _apiClient.post(
        ApiEndpoints.getRfqInitialDetails,
        {'email': email, 'accountno': accountNo},
      );

      if (kDebugMode) {
        print('RFQ Initial Details Response: ${response.data}');
      }

      if (response.statusCode == 200 && response.data['status'] == 200) {
        // Parse API response into RfqFormDefinition
        return RfqFormDefinition.fromApiResponse(response.data);
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get RFQ initial details',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching RFQ form data: $e');
      }
      throw Exception(
        'An error occurred while fetching RFQ form data: ${e.toString()}',
      );
    }
  }

  /// Get RFQ form data for editing (pre-filled with existing answers)
  /// Returns a map with formDefinition and pre-filled data
  Future<Map<String, dynamic>> getRfqFormDataForEdit(
    String rfqAccountNo,
  ) async {
    try {
      final email = await getUserEmail();
      final accountNo = await getAccountNo();

      final response = await _apiClient.post(ApiEndpoints.getRfqEditDetails, {
        'email': email,
        'accountno': accountNo,
        'rfq_accountno': rfqAccountNo,
      });

      if (kDebugMode) {
        print('RFQ Edit Details Response: ${response.data}');
      }

      if (response.statusCode == 200 && response.data['status'] == 200) {
        // Parse API response into RfqFormDefinition
        final formDefinition = RfqFormDefinition.fromApiResponse(response.data);

        // Extract pre-filled answers from questions
        final Map<String, dynamic> preFilledAnswers = {};
        final List<int> preFilledProductIds = [];
        String? preFilledRequirementDescription;
        String? preFilledAttachment;

        // Parse answers from rfqQuestionsListing (using answer_id field)
        final questionsList =
            response.data['rfqQuestionsListing'] as List? ?? [];
        for (final questionJson in questionsList) {
          final questionMap = questionJson as Map<String, dynamic>;
          final questionId = (questionMap['id'] ?? '').toString();
          final answerId = questionMap['answer_id'];

          // Check if answer_id exists and is not empty
          if (answerId != null && answerId.toString().isNotEmpty) {
            final questionType =
                (questionMap['question_type'] ?? '').toString();

            // Handle different question types
            if (questionType == 'checkbox') {
              // Checkbox answers are JSON array strings like "[\"Option 1\", \"Option 2\"]"
              if (answerId is String) {
                try {
                  final List<dynamic> answerList = jsonDecode(answerId);
                  // Convert to List<String> for checkbox fields
                  preFilledAnswers[questionId] =
                      answerList.map((e) => e.toString()).toList();
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      'Error parsing checkbox answer for question $questionId: $e',
                    );
                  }
                  // If parsing fails, store as empty list
                  preFilledAnswers[questionId] = [];
                }
              } else if (answerId is List) {
                preFilledAnswers[questionId] =
                    answerId.map((e) => e.toString()).toList();
              } else {
                preFilledAnswers[questionId] = [];
              }
            } else {
              // For other question types (textfield, textarea, dropdown, radio, fileinput)
              // Store the answer_id directly
              preFilledAnswers[questionId] = answerId.toString();
            }
          }
        }

        // Extract selected products/services from rfqServices array
        final rfqServicesList = response.data['rfqServices'] as List? ?? [];
        for (final service in rfqServicesList) {
          if (service is Map<String, dynamic>) {
            // Check for 'id' field (service ID)
            final serviceId = service['id'] as int?;
            if (serviceId != null) {
              preFilledProductIds.add(serviceId);
            }
            // Also check for 'service_id' or 'product_id' as fallback
            final productId =
                service['product_id'] as int? ?? service['service_id'] as int?;
            if (productId != null && !preFilledProductIds.contains(productId)) {
              preFilledProductIds.add(productId);
            }
          } else if (service is int) {
            preFilledProductIds.add(service);
          }
        }

        // Extract requirement description and attachment from rfqDetails array
        final rfqDetailsList = response.data['rfqDetails'] as List? ?? [];
        if (rfqDetailsList.isNotEmpty) {
          final rfqDetail = rfqDetailsList[0] as Map<String, dynamic>;
          preFilledRequirementDescription =
              rfqDetail['rfq_comments']?.toString();
          preFilledAttachment = rfqDetail['rfq_attachement']?.toString();
        }

        if (kDebugMode) {
          print('Pre-filled Answers: $preFilledAnswers');
          print('Pre-filled Product IDs: $preFilledProductIds');
          print('Pre-filled Requirement: $preFilledRequirementDescription');
          print('Pre-filled Attachment: $preFilledAttachment');
        }

        return {
          'formDefinition': formDefinition,
          'answers': preFilledAnswers,
          'selectedProductIds': preFilledProductIds,
          'requirementDescription': preFilledRequirementDescription,
          'attachmentFile': preFilledAttachment,
        };
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get RFQ edit details',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching RFQ edit form data: $e');
      }
      throw Exception(
        'An error occurred while fetching RFQ edit form data: ${e.toString()}',
      );
    }
  }

  /// Get available products/services for RFQ
  Future<List<RfqProduct>> getRfqProducts() async {
    try {
      final email = await getUserEmail();
      final accountNo = await getAccountNo();

      final response = await _apiClient.post(
        ApiEndpoints.getRfqInitialDetails,
        {'email': email, 'accountno': accountNo},
      );

      if (kDebugMode) {
        print('RFQ Products Response: ${response.data}');
      }

      if (response.statusCode == 200 && response.data['status'] == 200) {
        // Extract products from servicesListing in the API response
        // This uses the actual servicesListing array from the API, not dummy data
        final servicesList = response.data['servicesListing'] as List? ?? [];

        if (kDebugMode && servicesList.isEmpty) {
          print('Warning: servicesListing is empty in API response');
        }

        final products =
            servicesList
                .map(
                  (service) =>
                      RfqProduct.fromJson(service as Map<String, dynamic>),
                )
                .toList();

        if (kDebugMode) {
          print('Parsed ${products.length} products from servicesListing');
        }

        return products;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get RFQ products',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching RFQ products: $e');
      }
      // Return empty list on error to prevent UI breaking
      return [];
    }
  }

  /// Submit RFQ form as FormData (multipart/form-data)
  Future<bool> submitRfqForm({
    required RfqFormDefinition formDefinition,
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
    required List<int> selectedProductIds,
    required List<RfqProduct> allProducts,
    String? requirementDescription,
    String? attachmentFile,
    String? fileName,
  }) async {
    try {
      final accountNo = await getAccountNo();
      final token = await _tokenService.getAccessToken();

      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Fetch all products if not provided (fallback)
      final products =
          allProducts.isNotEmpty ? allProducts : await getRfqProducts();

      // Build the payload data using the payload builder
      final payloadData = RfqPayloadBuilder.buildSubmitPayload(
        accountNo: accountNo,
        answers: answers,
        formDefinition: formDefinition,
        selectedProductIds: selectedProductIds,
        allProducts: products,
        requirementDescription: requirementDescription,
        attachmentFile: attachmentFile,
        fileName: fileName,
      );

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.submitRfqForm),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add form fields
      request.fields['token'] = NetworkUrls.reactAppApiToken;
      request.fields['api_accountno'] = NetworkUrls.reactAppApiACCOUNTNO;
      request.fields['accountno'] = accountNo;
      request.fields['rfq_comments'] =
          (requirementDescription?.isEmpty ?? true)
              ? " "
              : requirementDescription!;
      request.fields['rfq_accountno'] = payloadData['rfq_accountno'] as String;

      // Add JSON stringified arrays
      request.fields['rfq_questions_rows'] = jsonEncode(
        payloadData['rfq_questions_rows'],
      );
      request.fields['services_rows'] = jsonEncode(
        payloadData['services_rows'],
      );

      // Handle file attachment
      if (attachmentFile != null && attachmentFile.isNotEmpty) {
        try {
          // Decode base64 to bytes
          Uint8List fileBytes;
          String processedBase64 = attachmentFile;

          // Remove data URL prefix if present (e.g., "data:image/png;base64,")
          if (attachmentFile.contains(',')) {
            processedBase64 = attachmentFile.split(',')[1];
          }

          fileBytes = base64Decode(processedBase64);

          // Use fileName if provided, otherwise use a default name
          final fileFieldName = fileName ?? 'attachment';

          // Add file as multipart file
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              fileBytes,
              filename: fileFieldName,
            ),
          );

          // Add fileName field
          if (fileName != null && fileName.isNotEmpty) {
            request.fields['fileName'] = fileName;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing file attachment: $e');
          }
          // Continue without file if there's an error
        }
      }

      if (kDebugMode) {
        print('Submit RFQ Form - Sending FormData');
        print('Fields: ${request.fields}');
        print('Files: ${request.files.length}');
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('Submit RFQ Form Response Status: ${response.statusCode}');
        print('Submit RFQ Form Response Body: ${response.body}');
      }

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 200) {
        return true;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to submit RFQ form');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting RFQ form: $e');
      }
      throw Exception(
        'An error occurred while submitting RFQ form: ${e.toString()}',
      );
    }
  }

  /// Upload RFQ file and get URL
  Future<String> uploadRfqFile(Uint8List fileBytes, String fileName) async {
    try {
      final accountNo = await getAccountNo();
      final token = await _tokenService.getAccessToken();

      if (token == null) {
        throw Exception('Authentication token not available.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.rfqFileResponse),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add account number
      request.fields['accountno'] = accountNo;

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      if (kDebugMode) {
        print('Upload RFQ File URL: ${ApiEndpoints.rfqFileResponse}');
        print('Upload RFQ File Filename: $fileName');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('Upload RFQ File Response Status: ${response.statusCode}');
        print('Upload RFQ File Response Body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 200) {
        final fileName = responseData['default'] as String? ?? '';
        if (fileName.isEmpty) {
          throw Exception('File upload failed: No filename returned');
        }
        // Return only the filename (without base URL)
        return fileName;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to upload file');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading RFQ file: $e');
      }
      throw Exception(
        'An error occurred while uploading file: ${e.toString()}',
      );
    }
  }

  /// Get single RFQ details
  Future<RfqDetail> getSingleRfq(String rfqAccountNo) async {
    try {
      final accountNo = await getAccountNo();

      final response = await _apiClient.post(ApiEndpoints.getSingleRfq, {
        'accountno': accountNo,
        'rfq_accountno': rfqAccountNo,
      });

      if (kDebugMode) {
        print('Get Single RFQ Response: ${response.data}');
      }

      if (response.statusCode == 200 && response.data['status'] == 200) {
        final List<dynamic> dataList = response.data['data'] as List? ?? [];
        if (dataList.isEmpty) {
          throw Exception('No RFQ details found');
        }
        return RfqDetail.fromJson(dataList[0] as Map<String, dynamic>);
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get RFQ details',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching single RFQ: $e');
      }
      throw Exception(
        'An error occurred while fetching RFQ details: ${e.toString()}',
      );
    }
  }

  /// Save RFQ form as draft
  Future<bool> saveRfqFormAsDraft({
    required Map<String, dynamic> answers,
    required int currentStep,
    required int totalSteps,
    List<int>? selectedProductIds,
    String? requirementDescription,
    String? attachmentFile,
  }) async {
    try {
      final email = await getUserEmail();
      final accountNo = await getAccountNo();

      final response = await _apiClient.post(ApiEndpoints.saveRfqFormAsDraft, {
        'email': email,
        'accountno': accountNo,
        'answers': answers,
        'currentStep': currentStep,
        'totalSteps': totalSteps,
        if (selectedProductIds != null)
          'selectedProductIds': selectedProductIds,
        if (requirementDescription != null)
          'requirementDescription': requirementDescription,
        if (attachmentFile != null) 'attachmentFile': attachmentFile,
      });

      if (kDebugMode) {
        print('Save RFQ Form Draft Response: ${response.data}');
      }

      if (response.statusCode == 200 && response.data['status'] == 200) {
        return true;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to save RFQ form as draft',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving RFQ form draft: $e');
      }
      throw Exception(
        'An error occurred while saving RFQ form draft: ${e.toString()}',
      );
    }
  }
}
