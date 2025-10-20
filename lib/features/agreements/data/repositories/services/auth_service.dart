import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';

class AuthService {
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

  // Save user data to shared preferences
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(_tokenKey, userData['token'] ?? '');
    prefs.setString(_accountNoKey, userData['accountno'] ?? '');
    prefs.setString(_emailKey, userData['email'] ?? '');
    prefs.setString(_companyNameKey, userData['comp_name'] ?? '');
    // prefs.setString(_userTypeKey, userData['user_type'] ?? '');
    // prefs.setString(_parentAccountNoKey, userData['parent_accountno'] ?? '');
    prefs.setString(_nameKey, userData['name'] ?? '');
    prefs.setString(_phoneKey, userData['phone'] ?? '');
    prefs.setString(_addressKey, userData['address'] ?? '');
    prefs.setString(_titleKey, userData['title'] ?? '');
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_accountNoKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_companyNameKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_addressKey);
    await prefs.remove(_titleKey);

    // await prefs.remove(_accessTokenKey);
    // await prefs.remove(_tokenExpiryKey);

    // Add any other keys you may want to clear
  }

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

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    // final token = await _apiClient.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.login, {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['message'] == 'success') {
        // Success, save user data
        final userData = response.data as Map<String, dynamic>;
        await _saveUserData(userData);

        return {
          'success': true,
          'message': 'Login successful. Redirecting to dashboard.',
          'data': userData,
        };
      } else if (response.statusCode == 404 &&
          response.data['message'] == 'invalid_credentials') {
        // Invalid credentials
        return {'success': false, 'message': 'Invalid credentials'};
      } else {
        // Other errors
        return {'success': false, 'message': response.data['message']};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during login',
        'errors': {'error': e.toString()},
      };
    }
  }

  // Method to handle Google login
  Future<Map<String, dynamic>> loginWithGoogle(
    String email,
    String name,
    String? photoUrl,
  ) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.googleLogin, {
        'email': email,
        'name': name,
        'photo_url': photoUrl,
      });

      if (response.statusCode == 200 && response.data['message'] == 'success') {
        // Success, save user data
        final userData = response.data as Map<String, dynamic>;
        await _saveUserData(userData);

        return {
          'success': true,
          'message': 'Login successful. Redirecting to dashboard.',
          'data': userData,
        };
      } else if (response.statusCode == 404 &&
          response.data['message'] == 'user_not_found') {
        // User not found, return data for registration
        return {
          'success': false,
          'message': 'User not found',
          'data': {'email': email, 'name': name, 'photo_url': photoUrl},
        };
      } else {
        // Other errors
        return {'success': false, 'message': response.data['message']};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during Google login',
        'errors': {'error': e.toString()},
      };
    }
  }

  // Method to check if a user exists
  Future<Map<String, dynamic>> checkUserExists(String email) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.checkUser, {
        'email': email,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'exists': response.data['exists'] ?? false,
          'message': response.data['message'] ?? 'User check completed',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to check user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while checking user',
        'errors': {'error': e.toString()},
      };
    }
  }

  // Method to register a new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.register, userData);

      if (response.statusCode == 200 && response.data['status'] == 200) {
        // Success, save user data if available
        if (response.data['data'] != null) {
          await _saveUserData(response.data['data']);
        }

        return {
          'success': true,
          'message': 'Registration successful',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during registration',
        'errors': {'error': e.toString()},
      };
    }
  }

  // Logout user
  Future<void> logout() async {
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.clear();
    await clearUserData();
  }

  // Method to send PIN code for forgot password
  Future<Map<String, dynamic>> sendForgotPasswordPinCode(String email) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.forgotPassword, {
        'email': email,
      });

      if (response.statusCode == 200 && response.data['status'] == 200) {
        return {'success': true, 'message': 'PIN code sent successfully'};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to send PIN code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while sending PIN code',
        'errors': {'error': e.toString()},
      };
    }
  }

  // Method to verify PIN code
  Future<Map<String, dynamic>> verifyPinCode(
    String email,
    String pincode,
    String pinFor,
  ) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.verifyPinCode, {
        'email': email,
        'pincode': pincode,
        'pin_for': pinFor,
      });

      if (response.statusCode == 200 && response.data['status'] == 200) {
        return {'success': true, 'message': 'PIN code verified successfully'};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to verify PIN code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while verifying PIN code',
        'errors': {'error': e.toString()},
      };
    }
  }

  // Method to set a new password
  Future<Map<String, dynamic>> setNewPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.resetPassword, {
        'email': email,
        'pincode': code,
        'password': newPassword,
      });

      if (response.statusCode == 200 && response.data['status'] == 200) {
        return {'success': true, 'message': 'Password reset successfully'};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while resetting password',
        'errors': {'error': e.toString()},
      };
    }
  }
}
