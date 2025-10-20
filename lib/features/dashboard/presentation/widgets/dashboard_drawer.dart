import 'package:flutter/material.dart';

import '../../../dashboard/domain/models/menu_item_model.dart';
import 'dashboard_side_menu.dart';

class DashboardDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final List<MenuItemModel> menuItems;
  final String selectedMenuId;
  final Function(MenuItemModel) onMenuItemTap;
  final bool isLoading;

  const DashboardDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.menuItems,
    required this.selectedMenuId,
    required this.onMenuItemTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 1,
      child: DashboardSideMenu(
        userName: userName,
        userEmail: userEmail,
        menuItems: menuItems,
        selectedMenuId: selectedMenuId,
        onMenuItemTap: onMenuItemTap,
        isLoading: isLoading,
      ),
    );
  }
}
