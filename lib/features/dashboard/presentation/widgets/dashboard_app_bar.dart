import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final bool isMainDashboard;
  final bool isDesktop;
  final String pageTitle;
  final VoidCallback onMenuTap;
  final VoidCallback? onBackTap;

  const DashboardAppBar({
    super.key,
    required this.userName,
    required this.isMainDashboard,
    required this.isDesktop,
    required this.pageTitle,
    required this.onMenuTap,
    this.onBackTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(isMainDashboard ? 130 : 56);

  @override
  Widget build(BuildContext context) {
    if (isMainDashboard) {
      return _buildMainAppBar(context);
    } else {
      return _buildSubPageAppBar();
    }
  }

  AppBar _buildMainAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.primaryColor,
      toolbarHeight: 130, // Increased height for more spacing
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
      centerTitle: true,
      leading:
          isDesktop
              ? null
              : IconButton(
                icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
                onPressed: onMenuTap,
              ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            // Handle notifications
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: OutlinedButton.icon(
                    icon: SvgPicture.asset(
                      'assets/icons/agreements.svg',
                      width: 20,
                      height: 20,

                      colorFilter: ColorFilter.mode(
                        AppColors.welcomeMenuTextColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: const Text(
                      'Reports',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      context.push(AppRoutes.reports);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: OutlinedButton.icon(
                    icon: SvgPicture.asset(
                      'assets/icons/ic_dashboard_submitrfq.svg',
                      width: 18,
                      height: 18,
                    ),
                    label: const Text(
                      'Request For Quote',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      // context.push(AppRoutes.requestQuote);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildSubPageAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        pageTitle,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon:
            Platform.isIOS
                ? const Icon(Icons.arrow_back_ios_new_rounded)
                : const Icon(Icons.arrow_back),
        onPressed: onBackTap,
      ),
    );
  }
}
