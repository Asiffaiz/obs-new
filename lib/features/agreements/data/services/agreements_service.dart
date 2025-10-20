import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/features/agreements/domain/models/archived_agreement_modal.dart';
import '../../domain/models/api_agreement_model.dart';
import '../../domain/models/agreement_model.dart';
import '../../domain/models/signed_agreement_model.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class AgreementService {
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

  // Fetch mandatory agreements from API
  Future<List<AgreementModel>> getMandatoryAgreements() async {
    try {
      final email = await getUserEmail();
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient.post(
        ApiEndpoints.getMandatoryAgreements,
        {'email': email, 'accountno': accountNo},
      );
      print(response);
      if (response.statusCode == 200 && response.data['status'] == 200) {
        // Parse API response into ApiAgreementModel objects
        final List<dynamic> agreementsData = response.data['data'] ?? [];
        final List<ApiAgreementModel> apiAgreements =
            agreementsData
                .map((item) => ApiAgreementModel.fromJson(item))
                .toList();

        // Convert API models to domain models
        return apiAgreements
            .map((apiAgreement) => apiAgreement.toDomainModel())
            .toList();
      } else if (response.statusCode == 200 && response.data['status'] == 404) {
        return [];
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get mandatory agreements',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while fetching mandatory agreements: ${e.toString()}',
      );
    }
  }

  // Sign an agreement
  Future<bool> signAgreement(
    String agreementId,
    String signature,
    String signMethod, [
    Map<String, dynamic>? payload,
  ]) async {
    try {
      final userData = await getUserData();

      // Use the complete payload if provided, otherwise use the basic one
      final Map<String, dynamic> requestData = payload!;
      // print(payload);

      final response = await _apiClient.post(
        signMethod == 'draw'
            ? ApiEndpoints.signAgreementWithDraw
            : signMethod == 'choose'
            ? ApiEndpoints.signAgreementWithDraw
            : ApiEndpoints.signAgreementWithChose,
        requestData,
      );
      print(response);
      return response.statusCode == 200 && response.data['status'] == 200;

      // Future.delayed(const Duration(milliseconds: 1000));
      // return true;
      // return false;
    } catch (e) {
      if (kDebugMode) print('Error signing agreement: $e');
      return false;
    }
  }

  Future<List<ArchivedAgreementModel>> getArchivedAgreements() async {
    try {
      final email = await getUserEmail();
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient.post(
        ApiEndpoints.getArchivedAgreements,
        {'email': email, 'accountno': accountNo},
      );
      //  print(response);
      if (response.statusCode == 200 && response.data['status'] == 200) {
        // Parse API response into SignedAgreementModel objects
        final List<dynamic> agreementsData = response.data['data'] ?? [];
        final List<ArchivedAgreementModel> archivedAgreements =
            agreementsData
                .map((item) => ArchivedAgreementModel.fromJson(item))
                .toList();

        return archivedAgreements;
      } else if (response.statusCode == 200 && response.data['status'] == 404) {
        return [];
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get archived agreements',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while fetching archived agreements: ${e.toString()}',
      );
    }
  }

  // Fetch signed agreements from API
  Future<List<SignedAgreementModel>> getSignedAgreements() async {
    try {
      final email = await getUserEmail();
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient.post(ApiEndpoints.getSignedAgreements, {
        'email': email,
        'accountno': accountNo,
      });
      //  print(response);
      if (response.statusCode == 200 && response.data['status'] == 200) {
        // Parse API response into SignedAgreementModel objects
        final List<dynamic> agreementsData = response.data['data'] ?? [];
        final List<SignedAgreementModel> signedAgreements =
            agreementsData
                .map((item) => SignedAgreementModel.fromJson(item))
                .toList();

        return signedAgreements;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get signed agreements',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while fetching signed agreements: ${e.toString()}',
      );
    }
  }

  // Fetch optional agreements from API
  Future<List<AgreementModel>> getOptionalAgreements() async {
    try {
      final email = await getUserEmail();
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient.post(
        ApiEndpoints.getOptionalAgreements,
        {'email': email, 'accountno': accountNo},
      );

      if (response.statusCode == 200 && response.data['status'] == 200) {
        // Parse API response into ApiAgreementModel objects
        final List<dynamic> agreementsData = response.data['data'] ?? [];
        final List<ApiAgreementModel> apiAgreements =
            agreementsData
                .map((item) => ApiAgreementModel.fromJson(item))
                .toList();

        // Convert API models to domain models
        return apiAgreements
            .map((apiAgreement) => apiAgreement.toDomainModel())
            .toList();
      } else if (response.data['status'] == 404 ||
          response.data['message'] == "No required unsigned agreement.") {
        return [];
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get optional agreements',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while fetching optional agreements: ${e.toString()}',
      );
    }
  }

  // Send agreement to signee
  Future<bool> sendToSignee(
    String agreementId,
    String name,
    String email,
    String? title,
    String? message,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';
      final userEmail = prefs.getString(_emailKey) ?? '';

      final response = await _apiClient.post(ApiEndpoints.sendToSignee, {
        'accountno': accountNo,
        'email': userEmail,
        'agreement_id': agreementId,
        'signee_name': name,
        'signee_email': email,
        'comments': message ?? 'Please sign this agreement',
        'agreement_service_type': 'main',
      });
      if (kDebugMode) print(response);
      return response.statusCode == 200 && response.data['status'] == 200;
    } catch (e) {
      if (kDebugMode) print('Error sending agreement to signee: $e');
      return false;
    }
  }
}
