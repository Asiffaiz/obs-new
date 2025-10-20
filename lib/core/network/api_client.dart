import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'dart:async';

import '../constants/network_urls.dart';
import '../services/token_service.dart';
import 'api_endpoints.dart';

/// A unified API response format for all API calls
class ApiResponse {
  final int statusCode;
  final dynamic data;
  final String? errorMessage;

  ApiResponse({
    required this.statusCode,
    required this.data,
    this.errorMessage,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isUnauthorized => statusCode == 401;

  // For legacy code compatibility
  int get status => statusCode;
}

/// Centralized API client for the entire application
class ApiClient {
  final http.Client _client = http.Client();
  late final TokenService _tokenService;

  // Singleton instance
  static final ApiClient _instance = ApiClient._internal();

  // Factory constructor to return the singleton instance
  factory ApiClient() {
    return _instance;
  }

  // Private constructor
  ApiClient._internal() {
    try {
      _tokenService = GetIt.instance<TokenService>();
    } catch (_) {
      _tokenService = TokenService();
    }
  }

  // GET request with auth token
  Future<ApiResponse> get(String url) async {
    return _executeRequest(() async {
      final token = await _tokenService.getAccessToken();
      if (token == null) {
        return _createErrorResponse(401, 'No authentication token available');
      }

      try {
        final response = await _client.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            // Removed keep-alive header to use fresh connections
          },
        );

        return _processResponse(response);
      } on http.ClientException catch (e) {
        if (kDebugMode) {
          print('HTTP Client Exception: $e');
        }
        // Let the _executeRequest method handle retries
        rethrow;
      } catch (e) {
        if (kDebugMode) {
          print('Error during GET request: $e');
        }
        return _createErrorResponse(500, 'Request failed: $e');
      }
    });
  }

  // POST request with auth token
  Future<ApiResponse> post(String url, dynamic body) async {
    return _executeRequest(() async {
      final token = await _tokenService.getAccessToken();
      if (token == null) {
        return _createErrorResponse(401, 'No authentication token available');
      }

      try {
        final response = await _client.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            // Removed keep-alive header to use fresh connections
          },
          body: jsonEncode(body),
        );

        if (kDebugMode) {
          print('Response body: ${response.body}');
        }
        return _processResponse(response);
      } on http.ClientException catch (e) {
        if (kDebugMode) {
          print('HTTP Client Exception: $e');
        }
        // Let the _executeRequest method handle retries
        rethrow;
      } catch (e) {
        if (kDebugMode) {
          print('Error during POST request: $e');
        }
        return _createErrorResponse(500, 'Request failed: $e');
      }
    });
  }

  // Process HTTP response
  ApiResponse _processResponse(http.Response response) {
    try {
      // Handle empty responses
      if (response.body.isEmpty) {
        return ApiResponse(
          statusCode: response.statusCode,
          data: null,
          errorMessage:
              response.statusCode >= 400 ? 'Empty response body' : null,
        );
      }

      final data = jsonDecode(response.body);

      if (kDebugMode) {
        print('Response data: $data');
      }

      if (response.statusCode == 401 &&
          data is Map &&
          data['errors'] == 'jwt expired') {
        return _createErrorResponse(401, 'Authentication token expired');
      }

      return ApiResponse(
        statusCode: response.statusCode,
        data: data,
        errorMessage:
            response.statusCode >= 400 ? _extractErrorMessage(data) : null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error processing response: $e');
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      return _createErrorResponse(
        response.statusCode,
        'Failed to process response: ${response.body}',
      );
    }
  }

  // Extract error message from response data
  String _extractErrorMessage(dynamic data) {
    if (data is Map) {
      // Try different common error message fields
      return data['message'] ??
          data['error'] ??
          data['errors'] ??
          data['errorMessage'] ??
          'Unknown error';
    }
    return 'Unknown error format';
  }

  // Create error response
  ApiResponse _createErrorResponse(int statusCode, String message) {
    return ApiResponse(
      statusCode: statusCode,
      data: null,
      errorMessage: message,
    );
  }

  // Execute request with token refresh logic and retry mechanism
  Future<ApiResponse> _executeRequest(
    Future<ApiResponse> Function() requestFn,
  ) async {
    int retryCount = 0;
    const maxRetries = 2; // Try up to 3 times total (original + 2 retries)

    while (true) {
      try {
        // Execute the request
        final response = await requestFn();

        // If unauthorized due to expired token, refresh token and retry once
        if (response.isUnauthorized) {
          final newToken = await _tokenService.refreshToken();
          if (newToken != null) {
            // Retry the request with the new token
            return await requestFn();
          }
        }

        return response;
      } on http.ClientException catch (e) {
        // Only retry for connection issues, not for other types of errors
        if (retryCount < maxRetries &&
            (e.toString().contains("Connection closed before full header") ||
                e.toString().contains("Connection reset by peer") ||
                e.toString().contains("Connection refused") ||
                e.toString().contains("Connection timed out"))) {
          retryCount++;
          if (kDebugMode) {
            print(
              'Retrying request after connection error (attempt $retryCount): $e',
            );
          }
          // Add exponential backoff delay before retrying
          await Future.delayed(Duration(milliseconds: 500 * (1 << retryCount)));
          continue; // Retry the request
        }

        // If we've exhausted retries or it's not a retryable error, return error response
        return _createErrorResponse(
          503,
          'Connection error after $retryCount retries: ${e.message}. Please check your internet connection.',
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error in _executeRequest: $e');
        }
        // For other types of errors, don't retry
        return _createErrorResponse(500, 'Request failed: $e');
      }
    }
  }

  // Helper method to get access token
  Future<String?> getAccessToken() async {
    try {
      final token = await _tokenService.getAccessToken();
      return token;
    } catch (e) {
      return null;
    }
  }
}
