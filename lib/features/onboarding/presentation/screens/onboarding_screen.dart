import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/theme/app_colors.dart';

import '../../../../config/routes.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/widgets/svg_helper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const _totalPages = 3;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: 'Enhancing Operations Through AI-Driven Insights',
      description:
          "At VoiceAlerts, we're committed to amplifying your telecom security with cutting-edge AI tools, seamless integration, and unparalleled support",
      image: 'assets/images/onboard_1.svg',
    ),
    const OnboardingPage(
      title: 'Advanced Communication',
      description:
          "At VoiceAlerts, we're committed to amplifying your telecom security with cutting-edge AI tools, seamless integration, and unparalleled support",
      image: 'assets/images/onboard_1.svg',
    ),

    const OnboardingPage(
      title: 'Powerful Analytics',
      description:
          "At VoiceAlerts, we're committed to amplifying your telecom security with cutting-edge AI tools, seamless integration, and unparalleled support",
      image: 'assets/images/onboard_1.svg',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  void _goToNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _markOnboardingComplete();
      context.go(AppRoutes.signIn);
    }
  }

  void _goToSignIn() {
    _markOnboardingComplete();
    context.go(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Image.asset('assets/images/launch_icon.png', height: 40),
                  if (_currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _goToSignIn,
                      child: const Text('Skip'),
                    )
                  else
                    TextButton(
                      onPressed: null,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.transparent),
                      ),
                    ), // Placeholder for alignment
                ],
              ),
            ),

            // Page content (takes remaining space)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) => _pages[index],
              ),
            ),

            // Bottom navigation section
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators
                  SizedBox(
                    width: 100,
                    child: Row(
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color:
                                _currentPage == index
                                    // ? Theme.of(context).primaryColor
                                    ? AppColors.appButtonColor
                                    : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Next button
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _goToNext,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: AppColors.appButtonColor,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Icon(
                        _currentPage < _totalPages - 1
                            ? Icons.arrow_forward
                            : Icons.check,
                      ),
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

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const OnboardingPage({
    Key? key,
    required this.title,
    required this.description,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // SVG illustration takes available space
          Expanded(flex: 2, child: Center(child: _buildIllustration())),
          const SizedBox(height: 24),
          // Text content with fixed height
          Expanded(
            flex: 2,
            child: SizedBox(
              // height: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.start,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    // Keep SVG code as comment for future reference
    /*
    return SizedBox(
      width: 300,
      height: 200,
      child: SvgHelper.svgOrFallback(
        svgPath: image,
        fallbackImagePath: 'assets/images/launch_icon.png',
        fit: BoxFit.contain,
      ),
    );
    */

    // Use PNG image instead
    return SizedBox(
      // width: 300,
      // height: 200,
      child: Image.asset(
        'assets/images/convoso_onboard.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
