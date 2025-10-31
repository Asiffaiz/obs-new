import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/constants/shared_prefence_keys.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<void> saveIsShowMandatoryDialog(bool isShowMandatoryDialog) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('is_show_mandatory_dialog', isShowMandatoryDialog);
  }

  Future<bool> getIsShowMandatoryDialog() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_show_mandatory_dialog') ?? true;
  }

  // Save user data to shared preferences
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(SharedPreferenceKeys.tokenKey, userData['token'] ?? '');
    prefs.setString(
      SharedPreferenceKeys.accountNoKey,
      userData['accountno'] ?? '',
    );
    prefs.setString(SharedPreferenceKeys.emailKey, userData['email'] ?? '');
    prefs.setString(
      SharedPreferenceKeys.companyNameKey,
      userData['comp_name'] ?? '',
    );
    // prefs.setString(_userTypeKey, userData['user_type'] ?? '');
    // prefs.setString(_parentAccountNoKey, userData['parent_accountno'] ?? '');
    prefs.setString(SharedPreferenceKeys.nameKey, userData['name'] ?? '');
    prefs.setString(SharedPreferenceKeys.phoneKey, userData['phone'] ?? '');
    prefs.setString(SharedPreferenceKeys.addressKey, userData['address'] ?? '');
    prefs.setString(
      SharedPreferenceKeys.address2Key,
      userData['address2'] ?? '',
    );
    prefs.setString(SharedPreferenceKeys.titleKey, userData['title'] ?? '');
    prefs.setString(SharedPreferenceKeys.cityKey, userData['city'] ?? '');
    prefs.setString(SharedPreferenceKeys.stateKey, userData['state'] ?? '');
    prefs.setString(SharedPreferenceKeys.zipKey, userData['zip'] ?? '');
    prefs.setString(SharedPreferenceKeys.countryKey, userData['country'] ?? '');
  }

  Future<void> saveUserDataOnUpdateProfile(
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // prefs.setString(SharedPreferenceKeys.emailKey, userData['email'] ?? '');
    prefs.setString(
      SharedPreferenceKeys.companyNameKey,
      userData['comp_name'] ?? '',
    );
    prefs.setString(SharedPreferenceKeys.nameKey, userData['name'] ?? '');
    prefs.setString(SharedPreferenceKeys.phoneKey, userData['phone'] ?? '');
    prefs.setString(SharedPreferenceKeys.addressKey, userData['address'] ?? '');
    prefs.setString(SharedPreferenceKeys.titleKey, userData['title'] ?? '');
    prefs.setString(SharedPreferenceKeys.cityKey, userData['city'] ?? '');
    prefs.setString(SharedPreferenceKeys.stateKey, userData['state'] ?? '');
    prefs.setString(SharedPreferenceKeys.zipKey, userData['zip'] ?? '');
    prefs.setString(SharedPreferenceKeys.countryKey, userData['country'] ?? '');
  }

  Future<void> saveUserDataOnRegisterProfile(
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(
      SharedPreferenceKeys.accountNoKey,
      userData['accountno'] ?? '',
    );
    prefs.setString(SharedPreferenceKeys.emailKey, userData['email'] ?? '');
    prefs.setString(
      SharedPreferenceKeys.companyNameKey,
      userData['company_name'] ?? '',
    );
    prefs.setString(SharedPreferenceKeys.nameKey, userData['full_name'] ?? '');
    prefs.setString(SharedPreferenceKeys.phoneKey, userData['phone'] ?? '');
    prefs.setString(SharedPreferenceKeys.addressKey, userData['address'] ?? '');
    prefs.setString(SharedPreferenceKeys.titleKey, userData['title'] ?? '');
    prefs.setString(SharedPreferenceKeys.cityKey, userData['city'] ?? '');
    prefs.setString(SharedPreferenceKeys.stateKey, userData['state'] ?? '');
    prefs.setString(SharedPreferenceKeys.zipKey, userData['zip'] ?? '');
    prefs.setString(SharedPreferenceKeys.countryKey, userData['country'] ?? '');
  }

  // Get user data from shared preferences
  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> userData = {};

    final token = prefs.getString(SharedPreferenceKeys.tokenKey);
    // if (token == null || token.isEmpty) {
    //   return {};
    // }

    userData['token'] = prefs.getString(SharedPreferenceKeys.tokenKey) ?? '';
    userData['accountno'] =
        prefs.getString(SharedPreferenceKeys.accountNoKey) ?? '';
    userData['email'] = prefs.getString(SharedPreferenceKeys.emailKey) ?? '';
    userData['comp_name'] =
        prefs.getString(SharedPreferenceKeys.companyNameKey) ?? '';
    // userData['user_type'] = prefs.getString(_userTypeKey) ?? '';
    // userData['parent_accountno'] = prefs.getString(_parentAccountNoKey) ?? '';
    userData['name'] = prefs.getString(SharedPreferenceKeys.nameKey) ?? '';
    userData['phone'] = prefs.getString(SharedPreferenceKeys.phoneKey) ?? '';
    userData['address'] =
        prefs.getString(SharedPreferenceKeys.addressKey) ?? '';
    userData['address2'] =
        prefs.getString(SharedPreferenceKeys.address2Key) ?? '';
    userData['title'] = prefs.getString(SharedPreferenceKeys.titleKey) ?? '';
    userData['city'] = prefs.getString(SharedPreferenceKeys.cityKey) ?? '';
    userData['state'] = prefs.getString(SharedPreferenceKeys.stateKey) ?? '';
    userData['zip'] = prefs.getString(SharedPreferenceKeys.zipKey) ?? '';
    userData['country'] =
        prefs.getString(SharedPreferenceKeys.countryKey) ?? '';

    return userData;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SharedPreferenceKeys.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedPreferenceKeys.tokenKey);
    await prefs.remove(SharedPreferenceKeys.accountNoKey);
    await prefs.remove(SharedPreferenceKeys.emailKey);
    await prefs.remove(SharedPreferenceKeys.companyNameKey);
    await prefs.remove(SharedPreferenceKeys.userTypeKey);
    await prefs.remove(SharedPreferenceKeys.parentAccountNoKey);
    await prefs.remove(SharedPreferenceKeys.nameKey);
    await prefs.remove(SharedPreferenceKeys.phoneKey);
    await prefs.remove(SharedPreferenceKeys.addressKey);
    await prefs.remove(SharedPreferenceKeys.address2Key);
    await prefs.remove(SharedPreferenceKeys.titleKey);
    await prefs.remove(SharedPreferenceKeys.cityKey);
    await prefs.remove(SharedPreferenceKeys.stateKey);
    await prefs.remove(SharedPreferenceKeys.zipKey);
    await prefs.remove(SharedPreferenceKeys.countryKey);
  }

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
      } else if (response.statusCode == 200 &&
          response.data['status'] == 404 &&
          response.data['errors'] == 'Invalid Email OR Password') {
        // Invalid credentials
        return {'success': false, 'message': 'Invalid Email OR Password'};
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
  Future<Map<String, dynamic>> checkUserExists(
    String email,
    String idToken,
  ) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.checkUser, {
        'authToken': idToken,
      });

      if (response.statusCode == 200 && response.data['message'] == 'success') {
        // Success, save user data
        final userData = response.data as Map<String, dynamic>;
        if (response.data['requestType'] == "user_login") {
          await _saveUserData(userData);
        }

        return {
          'success': true,
          'message': 'User check completed.',
          'data': userData,
          'requestType': response.data['requestType'],
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

        if (response.data != null) {
          var userDataToSave = userData;
          userDataToSave['accountno'] = response.data['accountno'];
          await saveUserDataOnRegisterProfile(userDataToSave);
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

  Future<Map<String, dynamic>> sendVerifyRegisterCode(String email) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sendVerifyRegisterCode,
        {'email': email},
      );

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
