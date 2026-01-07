import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/onboarding_settings_response_model.dart';

class OnboardingSettingsService {
  final ApiClient _apiClient = ApiClient();
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

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

  /// Get onboarding settings with retry logic
  Future<OnboardingSettingsResponseModel> getOnboardingSettings({
    required String accountNo,
    required String email,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < _maxRetries) {
      try {
        final response = await _apiClient.post(ApiEndpoints.getOnboardingUser, {
          'accountno': accountNo,
          'email': email,
        });

        if (response.statusCode == 200 &&
            response.data['status'] == 'success' &&
            response.data['data'] != null) {
          return OnboardingSettingsResponseModel.fromJson(response.data);
        } else {
          throw Exception(
            response.data['message']?.toString() ??
                'Failed to get onboarding settings',
          );
        }
      } catch (e) {
        lastException =
            e is Exception
                ? e
                : Exception('Error fetching onboarding settings: $e');
        retryCount++;

        if (retryCount < _maxRetries) {
          if (kDebugMode) {
            print(
              'Retrying onboarding settings fetch (attempt $retryCount/$_maxRetries)...',
            );
          }
          await Future.delayed(_retryDelay);
        } else {
          if (kDebugMode) {
            print(
              'Failed to fetch onboarding settings after $_maxRetries attempts',
            );
          }
          throw lastException;
        }
      }
    }

    throw lastException ?? Exception('Unknown error occurred');
  }

  /// Update onboarding step with retry logic
  Future<void> updateOnboardingStep({
    required String accountNo,
    required String type,
    required String title,
    required String form,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < _maxRetries) {
      try {
        final response = await _apiClient.post(
          ApiEndpoints.updateOnboardingStep,
          {'accountno': accountNo, 'type': type, 'title': title, 'form': form},
        );
        print(response.data);
        if (response.statusCode == 200 &&
            response.data['status'] == 'success') {
          if (kDebugMode) {
            print('Successfully updated onboarding step: $title');
          }
          return; // Success, exit the method
        } else {
          throw Exception(
            response.data['message']?.toString() ??
                'Failed to update onboarding step',
          );
        }
      } catch (e) {
        lastException =
            e is Exception
                ? e
                : Exception('Error updating onboarding step: $e');
        retryCount++;

        if (retryCount < _maxRetries) {
          if (kDebugMode) {
            print(
              'Retrying onboarding step update (attempt $retryCount/$_maxRetries)...',
            );
          }
          await Future.delayed(_retryDelay);
        } else {
          if (kDebugMode) {
            print(
              'Failed to update onboarding step after $_maxRetries attempts',
            );
          }
          throw lastException;
        }
      }
    }

    throw lastException ?? Exception('Unknown error occurred');
  }

  /// Skip onboarding step with retry logic
  Future<void> skipOnboardingStep({
    required String accountNo,
    required String type,
    required String title,
    required String form,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < _maxRetries) {
      try {
        final response = await _apiClient.post(
          ApiEndpoints.updateOnboardingStep,
          {
            'accountno': accountNo,
            'type': type,
            'isSkipped': 1,
            'title': title,
            'form': form,
          },
        );
        if (kDebugMode) {
          print('Skip API response: ${response.data}');
        }
        if (response.statusCode == 200 &&
            response.data['status'] == 'success') {
          if (kDebugMode) {
            print('Successfully skipped onboarding step: $title');
          }
          return; // Success, exit the method
        } else {
          throw Exception(
            response.data['message']?.toString() ??
                'Failed to skip onboarding step',
          );
        }
      } catch (e) {
        lastException =
            e is Exception
                ? e
                : Exception('Error skipping onboarding step: $e');
        retryCount++;

        if (retryCount < _maxRetries) {
          if (kDebugMode) {
            print(
              'Retrying onboarding step skip (attempt $retryCount/$_maxRetries)...',
            );
          }
          await Future.delayed(_retryDelay);
        } else {
          if (kDebugMode) {
            print('Failed to skip onboarding step after $_maxRetries attempts');
          }
          throw lastException;
        }
      }
    }

    throw lastException ?? Exception('Unknown error occurred');
  }
}
