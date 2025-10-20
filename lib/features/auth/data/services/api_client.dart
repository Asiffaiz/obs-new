// This file is kept for backward compatibility
// It redirects all calls to the centralized API client

import '../../../../core/network/api_client.dart' as central;
import '../../../../core/network/api_endpoints.dart';

// Re-export ApiResponse from the centralized client for backward compatibility
export '../../../../core/network/api_client.dart' show ApiResponse;

/// @deprecated Use the centralized ApiClient instead
/// This class is maintained for backward compatibility
class ApiClient {
  final _centralClient = central.ApiClient();

  Future<central.ApiResponse> checkLogin(String email, String password) async {
    return await _centralClient.post(ApiEndpoints.login, {
      'email': email,
      'password': password,
    });
  }

  Future<String?> getAccessToken() async {
    return await _centralClient.getAccessToken();
  }

  Future<central.ApiResponse> registerClient(
    Map<String, dynamic> userData,
  ) async {
    return await _centralClient.post(ApiEndpoints.register, userData);
  }

  Future<central.ApiResponse> loginWithGoogle(
    String email,
    String name,
    String? photoUrl,
  ) async {
    return await _centralClient.post(ApiEndpoints.googleLogin, {
      'email': email,
      'name': name,
      'photo_url': photoUrl,
    });
  }

  Future<central.ApiResponse> checkUserExists(String email) async {
    return await _centralClient.post(ApiEndpoints.checkUser, {'email': email});
  }

  Future<central.ApiResponse> sendForgotPasswordPinCode(String email) async {
    return await _centralClient.post(ApiEndpoints.forgotPassword, {
      'email': email,
    });
  }

  Future<central.ApiResponse> verifyPinCode(
    String email,
    String pincode,
    String pinFor,
  ) async {
    return await _centralClient.post(ApiEndpoints.verifyPinCode, {
      'email': email,
      'pincode': pincode,
      'pin_for': pinFor,
    });
  }

  Future<central.ApiResponse> setNewPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    return await _centralClient.post(ApiEndpoints.resetPassword, {
      'email': email,
      'pincode': code,
      'password': newPassword,
    });
  }
}
