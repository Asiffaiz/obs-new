import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/domain/models/menu_item_model.dart';

class DashboardSideMenu extends StatelessWidget {
  final String userName;
  final String userEmail;
  final List<MenuItemModel> menuItems;
  final String selectedMenuId;
  final Function(MenuItemModel) onMenuItemTap;
  final bool isLoading;

  const DashboardSideMenu({
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
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(1, 0),
          ),
        ],
      ),
      child: _buildMenuItems(),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        // User profile section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          decoration: BoxDecoration(color: AppColors.primaryColor),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Menu items
        Expanded(
          child:
              isLoading
                  ? _buildLoadingIndicator()
                  : ListView.separated(
                    itemCount: menuItems.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox.shrink(); // No divider
                    },
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      return _buildMenuItem(item);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading menu...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItemModel item) {
    final isSelected =
        selectedMenuId == item.id || selectedMenuId.startsWith('${item.id}_');
    final Color selectedColor = AppTheme.primaryColor;

    if (item.hasChildren) {
      return Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    item.isExpanded
                        ? selectedColor.withOpacity(0.1)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.isExpanded ? selectedColor : Colors.black87,
              ),
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight:
                    item.isExpanded ? FontWeight.bold : FontWeight.normal,
                color: item.isExpanded ? selectedColor : Colors.black87,
              ),
            ),
            trailing: Container(
              decoration: BoxDecoration(
                color:
                    item.isExpanded
                        ? selectedColor.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(
                item.isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: item.isExpanded ? selectedColor : Colors.black54,
              ),
            ),
            onTap: () => onMenuItemTap(item),
          ),
          if (item.isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  left: BorderSide(
                    color: selectedColor.withOpacity(0.3),
                    width: 4,
                  ),
                ),
              ),
              child: Column(
                children:
                    item.children.map((child) {
                      final isChildSelected = selectedMenuId == child.id;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                isChildSelected
                                    ? selectedColor.withOpacity(0.1)
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            child.icon,
                            size: 20,
                            color:
                                isChildSelected
                                    ? selectedColor
                                    : Colors.black54,
                          ),
                        ),
                        title: Text(
                          child.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isChildSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                isChildSelected
                                    ? selectedColor
                                    : Colors.black87,
                          ),
                        ),
                        selected: isChildSelected,
                        selectedTileColor: selectedColor.withOpacity(0.1),
                        onTap: () => onMenuItemTap(child),
                      );
                    }).toList(),
              ),
            ),
        ],
      );
    } else {
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? selectedColor.withOpacity(0.1)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.icon,
            color: isSelected ? selectedColor : Colors.black87,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? selectedColor : Colors.black87,
          ),
        ),
        selected: isSelected,
        selectedTileColor: selectedColor.withOpacity(0.1),
        trailing:
            isSelected
                ? Container(
                  width: 8,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                  ),
                )
                : null,
        onTap: () => onMenuItemTap(item),
      );
    }
  }
}
