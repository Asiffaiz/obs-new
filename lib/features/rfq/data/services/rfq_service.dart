import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/network/api_client.dart';
import 'package:voicealerts_obs/core/network/api_endpoints.dart';
import 'package:voicealerts_obs/features/rfq/data/utils/rfq_payload_builder.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_product_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_submission_model.dart';

/// Service for RFQ API calls
class RfqService {
  final ApiClient _apiClient = ApiClient();

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

  /// Submit RFQ form
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

      // Fetch all products if not provided (fallback)
      final products =
          allProducts.isNotEmpty ? allProducts : await getRfqProducts();

      // Build the payload using the payload builder
      final payload = RfqPayloadBuilder.buildSubmitPayload(
        accountNo: accountNo,
        answers: answers,
        formDefinition: formDefinition,
        selectedProductIds: selectedProductIds,
        allProducts: products,
        requirementDescription: requirementDescription,
        attachmentFile: attachmentFile,
        fileName: fileName,
      );

      if (kDebugMode) {
        print('Submit RFQ Form Payload: ${jsonEncode(payload)}');
      }

      final response = await _apiClient.post(
        ApiEndpoints.submitRfqForm,
        payload,
      );

      if (kDebugMode) {
        print('Submit RFQ Form Response: ${response.data}');
      }

      if (response.statusCode == 200 && response.data['status'] == 200) {
        return true;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to submit RFQ form',
        );
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
