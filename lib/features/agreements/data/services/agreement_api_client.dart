// This file is kept for backward compatibility
// It redirects all calls to the centralized API client

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:voicealerts_obs/core/constants/network_urls.dart';

import 'package:voicealerts_obs/core/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart' as central;
import '../../../../core/network/api_endpoints.dart';

// Re-export ApiResponse from the centralized client for backward compatibility
export '../../../../core/network/api_client.dart' show ApiResponse;

/// @deprecated Use the centralized ApiClient instead
/// This class is maintained for backward compatibility
class ApiClient {
  final _centralClient = central.ApiClient();

  Future<String?> getAccessToken() async {
    return await _centralClient.getAccessToken();
  }

  Future<central.ApiResponse> getMandatoryAgreements(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final accountNo = prefs.getString('client_acn__') ?? '';

    return await _centralClient.post(ApiEndpoints.getMandatoryAgreements, {
      'email': email,
      'accountno': accountNo,
    });
  }
}
