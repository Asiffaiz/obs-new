import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:voicealerts_obs/config/routes.dart';
import 'package:voicealerts_obs/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voicealerts_obs/features/auth/presentation/bloc/auth_event.dart';
import 'package:voicealerts_obs/main.dart';

/// HTTP Interceptor for handling authentication and error responses
class HttpInterceptor {
  static bool _isNavigatingToLogin = false;

  /// Process HTTP response and handle authentication errors
  static Future<http.Response> handleResponse(http.Response response) async {
    try {
      // Check if response is valid JSON
      if (response.body.isEmpty) {
        return response;
      }

      final jsonData = json.decode(response.body);

      // Check for token expiration or authentication errors
      if (response.statusCode == 401 && jsonData['errors'] == 'jwt expired') {
        // Prevent multiple navigation attempts
        if (_isNavigatingToLogin) {
          return response;
        }

        _isNavigatingToLogin = true;

        if (kDebugMode) {
          print("Token expired or auth error detected: ${response.body}");
        }

        // Access AuthBloc from GetIt and dispatch logout events
        try {
          final authBloc = GetIt.I<AuthBloc>();
          authBloc.add(const ApiLogoutRequested());
          authBloc.add(const SignOutRequested());
          if (kDebugMode) {
            print("Auth events dispatched");
          }
        } catch (e) {
          if (kDebugMode) {
            print("Error dispatching auth events: $e");
          }
        }

        // Navigate to login screen using GoRouter
        try {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final router = GetIt.I<GoRouter>();
            router.go(AppRoutes.signIn);
            if (kDebugMode) {
              print("Navigation to sign-in requested via GoRouter");
            }
            _isNavigatingToLogin = false;
          });
        } catch (e) {
          if (kDebugMode) {
            print("Error navigating with GoRouter: $e");
          }

          // Fallback to using navigatorKey
          if (rootNavigatorKey?.currentContext != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(
                rootNavigatorKey!.currentContext!,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil('/sign-in', (_) => false);
              if (kDebugMode) {
                print("Navigation to sign-in requested via Navigator");
              }
              _isNavigatingToLogin = false;
            });
          }
        }

        throw Exception("Session expired. Please sign in again.");
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print("Error in HTTP interceptor: $e");
      }
      return response;
    }
  }
}
