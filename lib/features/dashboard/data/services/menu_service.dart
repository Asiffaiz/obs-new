import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/constants/network_urls.dart';
import 'package:voicealerts_obs/core/services/token_service.dart';
import 'package:voicealerts_obs/core/utils/http_interceptor.dart';
import '../../domain/models/api_menu_item_model.dart';
import '../../domain/models/menu_item_model.dart';

class MenuService {
  late final TokenService _tokenService;

  MenuService() {
    try {
      _tokenService = GetIt.instance<TokenService>();
    } catch (_) {
      _tokenService = TokenService();
    }
  }

  static const String _baseUrl = NetworkUrls.apiBaseUrl;
  static const String _menuEndpoint = '/appApis/get_client_menu';

  static const String _accountNoKey = 'client_acn__';
  static const String _emailKey = 'client_eml__';
  // Fetch menu items from API
  Future<List<MenuItemModel>> fetchMenuItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await _tokenService.getAccessToken();
      if (token == null) {
        throw Exception('No auth token available');
      }

      var response = await http.post(
        Uri.parse('$_baseUrl$_menuEndpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          "email": prefs.getString(_emailKey),
          "accountno": prefs.getString(_accountNoKey),
        }),
      );
      response = await HttpInterceptor.handleResponse(response);
      print(response.body);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 200 && jsonData['data'] != null) {
          List<dynamic> menuData = jsonData['data'];
          List<ApiMenuItemModel> apiMenuItems =
              menuData.map((item) => ApiMenuItemModel.fromJson(item)).toList();

          // Convert API menu items to app's MenuItemModel
          List<MenuItemModel> menuItems =
              apiMenuItems.map((apiItem) => apiItem.toMenuItemModel()).toList();

          // Make sure we have the essential menu items
          _ensureEssentialMenuItems(menuItems);

          return menuItems;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load menu items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching menu items: $e');
      // Return fallback menu items in case of error
      return _getFallbackMenuItems();
    }
  }

  // Ensure essential menu items are included
  void _ensureEssentialMenuItems(List<MenuItemModel> menuItems) {
    // Make sure we have a dashboard item
    if (!menuItems.any((item) => item.id == 'dashboard')) {
      menuItems.insert(
        0,
        MenuItemModel(
          id: 'dashboard',
          title: 'Dashboard',
          icon: Icons.dashboard,
        ),
      );
    }

    // Make sure we have agreements
    if (!menuItems.any((item) => item.id == 'agreements')) {
      menuItems.add(
        MenuItemModel(
          id: 'agreements',
          title: 'Agreements',
          icon: Icons.description,
          children: [
            MenuItemModel(
              id: 'signed_agreements',
              title: 'Signed Agreements',
              icon: Icons.check_circle_outline,
              url: null,
            ),
            MenuItemModel(
              id: 'unsigned_agreements',
              title: 'Unsigned Agreements',
              icon: Icons.assignment,
              url: null,
            ),
          ],
        ),
      );
    } else {
      // Make sure agreements has both signed and unsigned
      MenuItemModel agreements = menuItems.firstWhere(
        (item) => item.id == 'agreements',
      );
      if (!agreements.children.any(
        (child) => child.id == 'signed_agreements',
      )) {
        agreements.children.add(
          MenuItemModel(
            id: 'signed_agreements',
            title: 'Signed Agreements',
            icon: Icons.check_circle_outline,
            url: null,
          ),
        );
      }
      if (!agreements.children.any(
        (child) => child.id == 'unsigned_agreements',
      )) {
        agreements.children.add(
          MenuItemModel(
            id: 'unsigned_agreements',
            title: 'Unsigned Agreements',
            icon: Icons.assignment,
            url: null,
          ),
        );
      }
    }

    // Make sure we have reports
    if (!menuItems.any((item) => item.id == 'reports')) {
      menuItems.add(
        MenuItemModel(
          id: 'reports',
          title: 'Reports',
          icon: Icons.bar_chart,
          url: null,
        ),
      );
    }

    // Make sure we have client assigned forms
    if (!menuItems.any((item) => item.id == 'client_assigned_forms')) {
      menuItems.add(
        MenuItemModel(
          id: 'client_assigned_forms',
          title: 'Client Assigned Forms',
          icon: Icons.assignment,
          url: null,
        ),
      );
    }
  }
}

// Get token from SharedPreferences
Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('client_tkn__');
}

// Fallback menu items in case API fails
List<MenuItemModel> _getFallbackMenuItems() {
  return [
    MenuItemModel(id: 'dashboard', title: 'Dashboard', icon: Icons.dashboard),
    MenuItemModel(
      id: 'agreements',
      title: 'Agreements',
      icon: Icons.description,
      children: [
        MenuItemModel(
          id: 'signed_agreements',
          title: 'Signed Agreements',
          icon: Icons.check_circle_outline,
          url: null,
        ),
        MenuItemModel(
          id: 'unsigned_agreements',
          title: 'Unsigned Agreements',
          icon: Icons.assignment,
          url: null,
        ),
      ],
    ),
    MenuItemModel(
      id: 'reports',
      title: 'Reports',
      icon: Icons.bar_chart,
      url: null,
    ),
    MenuItemModel(
      id: 'documents',
      title: 'Documents',
      icon: Icons.folder,
      // url: 'https://dev-agents.onboardsoft.me/client/documents',
    ),
    MenuItemModel(
      id: 'forms',
      title: 'Forms',
      icon: Icons.assignment,
      url: null,
    ),
  ];
}
