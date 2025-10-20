import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';
import 'package:voicealerts_obs/core/theme/app_theme.dart';

import '../../../../config/routes.dart';

class WelcomeMenuScreen extends StatelessWidget {
  const WelcomeMenuScreen({super.key});

  Future<void> _markWelcomeMenuShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_menu_shown', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background covering the full screen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.47,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                // gradient: LinearGradient(
                //   begin: Alignment.topCenter,
                //   end: Alignment.bottomCenter,
                //   colors: [HexColor('#1372F0'), HexColor('#6FADFF')],
                // ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top section with logo and welcome text
                Padding(
                  padding: const EdgeInsets.only(top: 25, bottom: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/logo_white.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Welcome text
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose how you\'d like to get started\nwith our platform',

                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom section with option cards
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Book Demo option
                            _buildOptionCard(
                              context,
                              svgPath: 'assets/icons/ic_book_demo.svg',
                              iconColor: AppColors.welcomeMenuIconColor,
                              title: 'Book a free demo',
                              description: 'Schedule a free demo',
                              onTap: () {
                                _markWelcomeMenuShown();
                                context.push(AppRoutes.bookDemo);
                              },
                            ),

                            const SizedBox(height: 16),
                            // Request Quote option
                            _buildOptionCard(
                              context,
                              svgPath: 'assets/icons/ic_rfq.svg',
                              iconColor: AppColors.welcomeMenuIconColor,
                              title: 'Request for quote',
                              description: 'Get a custom quote for your needs',
                              onTap: () {
                                _markWelcomeMenuShown();
                                context.push(AppRoutes.requestQuote);
                              },
                            ),
                            const SizedBox(height: 16),
                            // Login option
                            _buildOptionCard(
                              context,
                              svgPath: 'assets/icons/ic_login.svg',
                              iconColor: AppColors.welcomeMenuIconColor,
                              title: 'Login',
                              description:
                                  'Already have an account? Sign in here',
                              onTap: () {
                                _markWelcomeMenuShown();
                                context.go(AppRoutes.signIn);
                              },
                            ),
                            const SizedBox(height: 16),
                            // Sign Up option
                            _buildOptionCard(
                              context,
                              svgPath: 'assets/icons/ic_signup.svg',
                              iconColor: AppColors.welcomeMenuIconColor,
                              title: 'Sign Up',
                              description:
                                  'Create a new account to get started',
                              onTap: () {
                                _markWelcomeMenuShown();
                                context.go(AppRoutes.signUp);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String svgPath, // <-- changed from IconData to String
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Row(
          children: [
            // SVG Icon circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.welcomeMenuCircleColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgPath,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.welcomeMenuTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.welcomeMenuTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
