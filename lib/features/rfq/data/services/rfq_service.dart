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
  static const String _rfqAttachmentBaseUrl =
      'https://dev-agents.onboardsoft.me/files_data/rfq/';

  /// Normalizes attachment value coming from API/UI.
  /// - If it's already a full URL, returns just the filename.
  /// - If it's already a filename, returns it.
  /// - If empty/null, returns null.
  String? _normalizeRfqAttachmentToFileName(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    // If backend accidentally stores double-prefixed URLs, taking last segment
    // still yields the actual filename.
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        final seg = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        return seg.isEmpty ? null : seg;
      } catch (_) {
        // Fallback: take last portion after '/'
        final seg = trimmed.split('/').last;
        return seg.isEmpty ? null : seg;
      }
    }

    // If it's already a path (not full URL), also reduce to last segment.
    final seg = trimmed.split('/').last;
    return seg.isEmpty ? null : seg;
  }

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
          preFilledAttachment = _normalizeRfqAttachmentToFileName(
            rfqDetail['rfq_attachement']?.toString(),
          );
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

  /// Update RFQ form as FormData (multipart/form-data) - for edit mode
  Future<bool> updateRfqForm({
    required String rfqAccountNo,
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

      ////////////
      /// Build services_rows from selected products
      List<Map<String, dynamic>> buildServicesRows({
        required List<int> selectedProductIds,
        required List<RfqProduct> allProducts,
      }) {
        final servicesRows = <Map<String, dynamic>>[];

        for (final productId in selectedProductIds) {
          final product = allProducts.firstWhere(
            (p) => p.id == productId,
            orElse:
                () =>
                    RfqProduct(id: productId, serviceTitle: 'Unknown Product'),
          );

          servicesRows.add({
            'service_checked': true,
            'service_id': product.id,
            'service_title': product.serviceTitle,
            'service_price': 0, // Default to 0, API might update this
            'service_quantity': 1,
            'service_unit': '',
            'service_sub_total': 0, // Default to 0, API might update this
            'service_sku': product.sku ?? '',
          });
        }

        return servicesRows;
      }

      ///////////
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
        Uri.parse(ApiEndpoints.updateRfq),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      ///////////
      /// Add services_rows to the payload
      ////////////
      final servicesRows = buildServicesRows(
        selectedProductIds: selectedProductIds,
        allProducts: allProducts,
      );

      payloadData['services_rows'] = servicesRows;

      // Add form fields
      request.fields['token'] = NetworkUrls.reactAppApiToken;
      request.fields['api_accountno'] = NetworkUrls.reactAppApiACCOUNTNO;
      request.fields['accountno'] = accountNo;
      request.fields['rfq_accountno'] =
          rfqAccountNo; // Use existing rfq_accountno for update
      request.fields['rfq_comments'] =
          (requirementDescription?.isEmpty ?? true)
              ? " "
              : requirementDescription!;

      // Add JSON stringified arrays
      request.fields['rfq_questions_rows'] = jsonEncode(
        payloadData['rfq_questions_rows'],
      );
      request.fields['services_rows'] = jsonEncode(
        payloadData['services_rows'],
      );

      // request.fields['services_rows'] = jsonEncode([
      //   {
      //     'service_checked': true,
      //     "service_id": 116,
      //     "service_name": "Channel Partner Portal License (MRC)",
      //     "quantity": 1,
      //     "service_unit": "",
      //     "sku": "00003",
      //     "dateAdded": "2026-01-28T18:42:36.000Z",
      //     "dateUpdated": null,
      //   },
      // ]);

      // Handle file attachment - always include file and fileName keys
      // The file is already uploaded via rfq_file_response API, so we only send the filename
      // file is always null (file already uploaded), fileName contains the uploaded filename
      final normalizedAttachment = _normalizeRfqAttachmentToFileName(
        attachmentFile,
      );
      request.fields['file'] =
          (normalizedAttachment != null && normalizedAttachment.isNotEmpty)
              ? '$_rfqAttachmentBaseUrl$normalizedAttachment'
              : '';
      request.fields['fileName'] =
          (normalizedAttachment != null && normalizedAttachment.isNotEmpty)
              ? normalizedAttachment
              : '';

      if (kDebugMode) {
        print('Update RFQ Form - Sending FormData');
        print('Fields: ${request.fields}');
        print('Files: ${request.files.length}');
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('Update RFQ Form Response Status: ${response.statusCode}');
        print('Update RFQ Form Response Body: ${response.body}');
      }

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 200) {
        return true;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update RFQ form');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating RFQ form: $e');
      }
      throw Exception(
        'An error occurred while updating RFQ form: ${e.toString()}',
      );
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

      ////////////
      /// Build services_rows from selected products
      List<Map<String, dynamic>> buildServicesRows({
        required List<int> selectedProductIds,
        required List<RfqProduct> allProducts,
      }) {
        final servicesRows = <Map<String, dynamic>>[];

        for (final productId in selectedProductIds) {
          final product = allProducts.firstWhere(
            (p) => p.id == productId,
            orElse:
                () =>
                    RfqProduct(id: productId, serviceTitle: 'Unknown Product'),
          );

          servicesRows.add({
            'service_checked': true,
            'service_id': product.id,
            'service_title': product.serviceTitle,
            'service_price': 0, // Default to 0, API might update this
            'service_quantity': 1,
            'service_unit': '',
            'service_sub_total': 0, // Default to 0, API might update this
            'service_sku': product.sku ?? '',
          });
        }

        return servicesRows;
      }

      ///////////

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

      final servicesRows = buildServicesRows(
        selectedProductIds: selectedProductIds,
        allProducts: allProducts,
      );

      payloadData['services_rows'] = servicesRows;

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

      // Handle file attachment - always include file and fileName keys
      // The file is already uploaded via rfq_file_response API, so we only send the filename
      // file is always null (file already uploaded), fileName contains the uploaded filename
      // request.fields['file'] =
      //     attachmentFile ??
      //     ''; // Always null/empty since file is already uploaded
      // request.fields['fileName'] =
      //     attachmentFile ?? ''; // Filename from uploadRfqFile API or empty

      request.fields['file'] =
          (() {
            final normalizedAttachment = _normalizeRfqAttachmentToFileName(
              attachmentFile,
            );
            return (normalizedAttachment != null &&
                    normalizedAttachment.isNotEmpty)
                ? '$_rfqAttachmentBaseUrl$normalizedAttachment'
                : '';
          })();
      request.fields['fileName'] =
          (() {
            final normalizedAttachment = _normalizeRfqAttachmentToFileName(
              attachmentFile,
            );
            return (normalizedAttachment != null &&
                    normalizedAttachment.isNotEmpty)
                ? normalizedAttachment
                : '';
          })();

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
