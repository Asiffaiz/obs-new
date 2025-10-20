import 'package:flutter/material.dart';
import 'package:voicealerts_obs/core/constants/network_urls.dart';
import 'menu_item_model.dart';

class ApiMenuItemModel {
  final String tabImage;
  final String alt;
  final String link;
  final bool isNativeScreen;
  final List<ApiSubmenuItemModel> submenu;
  final bool isExpanded;

  ApiMenuItemModel({
    required this.tabImage,
    required this.alt,
    required this.link,
    required this.isNativeScreen,
    required this.submenu,
    this.isExpanded = false,
  });

  factory ApiMenuItemModel.fromJson(Map<String, dynamic> json) {
    List<ApiSubmenuItemModel> submenuItems = [];

    if (json['submenu'] != null) {
      submenuItems = List<ApiSubmenuItemModel>.from(
        json['submenu'].map((item) => ApiSubmenuItemModel.fromJson(item)),
      );
    }

    return ApiMenuItemModel(
      tabImage: json['tabimage'] ?? '',
      alt: json['alt'] ?? '',
      link: json['link'] ?? '',
      isNativeScreen: json['is_native_screen'] == 1,
      submenu: submenuItems,
    );
  }

  ApiMenuItemModel copyWith({
    String? tabImage,
    String? alt,
    String? link,
    bool? isNativeScreen,
    List<ApiSubmenuItemModel>? submenu,
    bool? isExpanded,
  }) {
    return ApiMenuItemModel(
      tabImage: tabImage ?? this.tabImage,
      alt: alt ?? this.alt,
      link: link ?? this.link,
      isNativeScreen: isNativeScreen ?? this.isNativeScreen,
      submenu: submenu ?? this.submenu,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  // Helper method to convert API menu item to app's MenuItemModel
  MenuItemModel toMenuItemModel() {
    // Convert submenu items
    List<MenuItemModel> children =
        submenu.map((item) => item.toMenuItemModel()).toList();

    // Get icon based on the alt text (menu title)
    IconData icon = _getIconForMenu(alt);

    // Generate ID from alt text (lowercase and replace spaces with underscores)
    String id = alt.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_');

    // For native screens that need special handling
    if (isNativeScreen) {
      if (alt == "Agreements") {
        // For the Agreements menu, we need to add the Unsigned Agreements option
        // if it doesn't already exist in the submenu
        bool hasUnsignedAgreements = submenu.any(
          (item) => item.alt.toLowerCase() == 'unsigned agreements',
        );

        if (!hasUnsignedAgreements) {
          children.add(
            MenuItemModel(
              id: 'unsigned_agreements',
              title: 'Unsigned Agreements',
              icon: Icons.assignment,
              url: null,
            ),
          );
        }

        return MenuItemModel(
          id: id,
          title: alt,
          icon: icon,
          url: link == "#" ? null : link,
          children: children,
        );
      }
    }

    if (alt == "Forms") {
      return MenuItemModel(
        id: 'client_assigned_forms',
        title: alt,
        icon: icon,
        url: null,
      );
    }

    if (alt == "Documents") {
      return MenuItemModel(id: 'documents', title: alt, icon: icon, url: null);
    }

    if (alt == "Product & Services") {
      return MenuItemModel(
        id: 'products_services',
        title: alt,
        icon: icon,
        url: null,
      );
    }

    if (alt == "Support") {
      return MenuItemModel(
        id: 'support',
        title: alt,
        icon: icon,
        url: NetworkUrls.webBaseUrl + '/pages/need-help',
      );
    }
    // For regular menu items
    return MenuItemModel(
      id: id,
      title: alt,
      icon: icon,
      url: link == "#" ? null : link,
      children: children.isEmpty ? [] : children,
    );
  }

  // Helper method to get icon based on menu title
  IconData _getIconForMenu(String menuTitle) {
    switch (menuTitle.toLowerCase()) {
      case 'dashboard':
        return Icons.dashboard;
      case 'agreements':
        return Icons.description;
      case 'signed agreements':
        return Icons.check_circle_outline;
      case 'client email':
        return Icons.email;
      case 'orders':
        return Icons.shopping_cart;
      case 'quotations':
        return Icons.request_quote;
      case 'manage quotations':
        return Icons.list_alt;
      case 'manage rfq\'s':
        return Icons.receipt_long;
      case 'product & services':
        return Icons.inventory;
      case 'sub users':
        return Icons.people;
      case 'documents':
        return Icons.folder;
      case 'forms':
        return Icons.assignment;
      case 'support':
        return Icons.help;
      case 'client dashboard':
        return Icons.dashboard_customize;
      case 'reports':
        return Icons.bar_chart;
      case 'api key':
        return Icons.key;
      default:
        return Icons.circle;
    }
  }
}

class ApiSubmenuItemModel {
  final String tabImage;
  final String alt;
  final String link;
  final bool isNativeScreen;

  ApiSubmenuItemModel({
    required this.tabImage,
    required this.alt,
    required this.link,
    required this.isNativeScreen,
  });

  factory ApiSubmenuItemModel.fromJson(Map<String, dynamic> json) {
    return ApiSubmenuItemModel(
      tabImage: json['tabimage'] ?? '',
      alt: json['alt'] ?? '',
      link: json['link'] ?? '',
      isNativeScreen: json['is_native_screen'] == 1,
    );
  }

  // Helper method to convert API submenu item to app's MenuItemModel
  MenuItemModel toMenuItemModel() {
    // Get icon based on the alt text (menu title)
    IconData icon = _getIconForMenu(alt);

    // Generate ID from alt text (lowercase and replace spaces with underscores)
    String id = alt
        .toLowerCase()
        .replaceAll(' & ', '_')
        .replaceAll(' ', '_')
        .replaceAll('\'', '');

    // Special handling for native screens
    if (isNativeScreen) {
      if (alt == "Signed Agreements") {
        return MenuItemModel(
          id: 'signed_agreements',
          title: alt,
          icon: icon,
          url: null,
        );
      }
    }

    // Special handling for Reports
    if (alt == "Reports" || id == "reports") {
      return MenuItemModel(id: 'reports', title: alt, icon: icon, url: null);
    }

    return MenuItemModel(id: id, title: alt, icon: icon, url: link);
  }

  // Helper method to get icon based on menu title
  IconData _getIconForMenu(String menuTitle) {
    switch (menuTitle.toLowerCase()) {
      case 'dashboard':
        return Icons.dashboard;
      case 'agreements':
        return Icons.description;
      case 'signed agreements':
        return Icons.check_circle_outline;
      case 'client email':
        return Icons.email;
      case 'orders':
        return Icons.shopping_cart;
      case 'quotations':
        return Icons.request_quote;
      case 'manage quotations':
        return Icons.list_alt;
      case 'manage rfq\'s':
        return Icons.receipt_long;
      case 'product & services':
        return Icons.inventory;
      case 'sub users':
        return Icons.people;
      case 'documents':
        return Icons.folder;
      case 'forms':
        return Icons.assignment;
      case 'support':
        return Icons.help;
      case 'client dashboard':
        return Icons.dashboard_customize;
      case 'reports':
        return Icons.bar_chart;
      case 'api key':
        return Icons.key;
      default:
        return Icons.circle;
    }
  }
}
