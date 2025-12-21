import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/network_urls.dart';

class TokenService {
  static const String _accessTokenKey = 'api_access_token';
  static const String _tokenExpiryKey = 'api_token_expiry';

  // API credentials (should be moved to secure storage in production)
  static const String _username = "6ff1e963-9d1d-4053-a143-51201d48be3a";
  static const String _password =
      "88b974ec343af71c7ac1b3e63f004ef9c8044ab5ca06f37716ebc1feb991b453";

  // Get access token - either from cache or generate a new one
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    final expiryString = prefs.getString(_tokenExpiryKey);

    // If no token exists or token has expired, generate a new one
    if (token == null ||
        expiryString == null ||
        _isTokenExpired(expiryString)) {
      return await _generateNewToken();
    }

    return token;
  }

  // Check if token has expired
  bool _isTokenExpired(String expiryString) {
    try {
      final expiry = DateTime.parse(expiryString);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      // If we can't parse the date, assume token is expired
      return true;
    }
  }

  // Generate new access token
  Future<String?> _generateNewToken() async {
    try {
      // Try multiple server endpoints to handle connection issues
      final endpoints = ['${NetworkUrls.apiBaseUrl}/auth/auth_token'];

      String? token;
      Exception? lastError;

      // Try each endpoint
      for (final endpoint in endpoints) {
        try {
          final response = await http
              .post(
                Uri.parse(endpoint),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'Connection': 'keep-alive',
                },
                body: jsonEncode({
                  'username': _username,
                  'password': _password,
                }),
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw TimeoutException('Token request timed out');
                },
              );
          if (kDebugMode) {
            print('Token response status: ${response.statusCode}');
            print('Token response body: ${response.body}');
          }

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            token = responseData['access_token'];

            if (token != null) {
              // Set expiry to 1 hour from now (adjust based on actual token expiry)
              final expiry = DateTime.now().add(const Duration(hours: 1));

              // Save token and expiry
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_accessTokenKey, token);
              await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());

              if (kDebugMode) {
                print('Successfully generated token');
              }
              return token;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error with endpoint $endpoint: $e');
          }
          lastError = e as Exception;
          // Continue to next endpoint
        }
      }

      // All endpoints failed
      if (kDebugMode) {
        print('All token endpoints failed. Last error: $lastError');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Fatal error generating token: $e');
      }
      return null;
    }
  }

  // Force token refresh (used when a 401 is received)
  Future<String?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_tokenExpiryKey);
    return await _generateNewToken();
  }
}
