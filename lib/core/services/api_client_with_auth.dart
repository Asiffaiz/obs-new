import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'dart:async';

import '../network/api_client.dart' as central;
import 'token_service.dart';

// Keep the same response format for backward compatibility
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
}

/// @deprecated Use the centralized ApiClient instead
/// This class is maintained for backward compatibility
class ApiClientWithAuth {
  late final central.ApiClient _centralClient;

  ApiClientWithAuth() {
    // Use the centralized API client
    try {
      _centralClient = GetIt.instance<central.ApiClient>();
    } catch (_) {
      _centralClient = central.ApiClient();
    }
  }

  // GET request with auth token
  Future<ApiResponse> get(String url) async {
    final response = await _centralClient.get(url);
    return ApiResponse(
      statusCode: response.statusCode,
      data: response.data,
      errorMessage: response.errorMessage,
    );
  }

  // POST request with auth token
  Future<ApiResponse> post(String url, dynamic body) async {
    final response = await _centralClient.post(url, body);
    return ApiResponse(
      statusCode: response.statusCode,
      data: response.data,
      errorMessage: response.errorMessage,
    );
  }
}
