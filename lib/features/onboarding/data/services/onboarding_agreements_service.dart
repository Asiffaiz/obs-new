import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/onboarding_agreements_response_model.dart';

class OnboardingAgreementsService {
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

  /// Get onboarding agreements with retry logic
  Future<OnboardingAgreementsResponseModel> getOnboardingAgreements({
    required String accountNo,
    required String email,
  }) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < _maxRetries) {
      try {
        final response = await _apiClient.post(
          ApiEndpoints.getClientAgreementsListingAll,
          {
            'accountno': accountNo,
            'email': email,
          },
        );

        if (response.statusCode == 200 && response.data['status'] == 200) {
          return OnboardingAgreementsResponseModel.fromJson(response.data);
        } else if (response.statusCode == 200 && response.data['status'] == 404) {
          // Return empty lists if no agreements found
          return const OnboardingAgreementsResponseModel(
            signedAgreements: [],
            optionalAgreements: [],
          );
        } else {
          throw Exception(
            response.data['message']?.toString() ??
                'Failed to get onboarding agreements',
          );
        }
      } catch (e) {
        lastException = e is Exception
            ? e
            : Exception('Error fetching onboarding agreements: $e');
        retryCount++;

        if (retryCount < _maxRetries) {
          if (kDebugMode) {
            print(
              'Retrying onboarding agreements fetch (attempt $retryCount/$_maxRetries)...',
            );
          }
          await Future.delayed(_retryDelay);
        } else {
          if (kDebugMode) {
            print('Failed to fetch onboarding agreements after $_maxRetries attempts');
          }
          throw lastException;
        }
      }
    }

    throw lastException ?? Exception('Unknown error occurred');
  }
}

