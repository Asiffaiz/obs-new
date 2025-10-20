import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/config/dependency_injection.dart';

import 'package:voicealerts_obs/core/network/api_client.dart';
import 'package:voicealerts_obs/core/network/api_endpoints.dart';
import 'package:voicealerts_obs/features/auth/data/services/auth_service.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();
  static const String _accountNoKey = 'client_acn__';
  static const String _emailKey = 'client_eml__';
  final AuthService _authService = getIt.get<AuthService>();
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profile,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_emailKey) ?? '';
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient.post(ApiEndpoints.updateClientProfile, {
        'accountno': accountNo,
        ...profile,
      });
      print(response.data);
      if (response.statusCode == 200) {
        if (response.data['status'] == 200 && response.data['data'] != null) {
          _authService.saveUserDataOnUpdateProfile(response.data['data'][0]);
          return response.data['data'][0];
        }
      }

      throw Exception('Failed to update profile');
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
}
