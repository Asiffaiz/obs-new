import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/constants/shared_prefence_keys.dart';
import 'package:voicealerts_obs/core/widgets/voice_alerts_logo.dart';
import '../../../../config/routes.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _animationComplete = false;
  bool _timeoutReached = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    // Start animation
    _animationController.forward().then((_) {
      // Mark animation as complete
      if (mounted) {
        setState(() {
          _animationComplete = true;
        });

        // Explicitly trigger auth check
        context.read<AuthBloc>().add(const AuthCheckRequested());

        // Set a timeout to prevent getting stuck on splash screen
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _timeoutReached = true;
            });
            _proceedWithNavigation(context, context.read<AuthBloc>().state);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _proceedWithNavigation(BuildContext context, AuthState state) async {
    if (!_animationComplete) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (!onboardingComplete && mounted) {
      // First time launch, go to onboarding
      context.go(AppRoutes.onboarding);
    } else if (mounted) {
      // Not first time, check auth state
      print("Mera Auth State==>$state");
      print("Is Authenticated: ${state.isAuthenticated}");
      print("Auth Status: ${state.status}");
      // print("Has Mandatory Agreements: ${state.hasMandatoryAgreements}");

      // Check if there's a token in SharedPreferences as a fallback
      final token = await _checkTokenExists();
      final isAuthenticated = state.isAuthenticated || token;
      print("Is Authenticated: $isAuthenticated");
      if (isAuthenticated) {
        // Mark agreements as completed to avoid the redirect to agreements screen
        // context.read<AuthBloc>().add(
        //   const CheckMandatoryAgreementsBeforeLogin(),
        // );
        // ignore: use_build_context_synchronously
        final isAllAgreementsSigned =
            await context
                .read<AuthBloc>()
                .handleCheckMandatoryAgreementsBeforeLogin();
        // Wait a short moment for the state to update
        await Future.delayed(const Duration(milliseconds: 100));

        // Navigate to home
        if (mounted) {
          //commented for testing
          if (isAllAgreementsSigned == false) {
            context.go(AppRoutes.unsignedAgreements);
          } else {
            context.go(AppRoutes.home);
          }
        }
      } else {
        context.go(AppRoutes.signIn);
      }
    }
  }

  Future<bool> _checkTokenExists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('client_tkn__');
      final accountNo = prefs.getString(SharedPreferenceKeys.accountNoKey);
      return token != null && token.isNotEmpty ||
          accountNo != null && accountNo.isNotEmpty && accountNo != 'null';
    } catch (e) {
      print("Error checking token: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
      final screenSize = MediaQuery.of(context).size;
    final logoSize =
        screenSize.width * 0.65 > 280 ? 280.0 : screenSize.width * 0.65;
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        // Only proceed when animation is complete and auth state has changed
        return _animationComplete &&
            !_timeoutReached &&
            (previous.isAuthenticated != current.isAuthenticated ||
                previous.status != current.status);
      },
      listener: (context, state) {
        _proceedWithNavigation(context, state);
      },
      child: Scaffold(
        body:  AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animations
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: VoiceAlertsLogo(
                        size: logoSize,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 20),
                  // App name with fade animation
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          "Fraud Prevention",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenSize.width < 400 ? 22 : 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        // const SizedBox(height: 8),
                        // Text(
                        //   "CLEAN CALLS",
                        //   style: TextStyle(
                        //     color: Colors.white,
                        //     fontSize: screenSize.width < 400 ? 14 : 18,
                        //     fontWeight: FontWeight.w600,
                        //     letterSpacing: 1.2,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tagline with delayed fade
                  Opacity(
                    opacity: _animationController.value,
                    child: Text(
                      "Intelligent AI-Driven Solutions for Carriers and Enterprises",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: screenSize.width < 400 ? 14 : 16,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // const SizedBox(height: 80),
                  // Loading indicator - commented out
                  // if (_animationController.value > 0.7)
                  //   const SizedBox(
                  //     width: 40,
                  //     height: 40,
                  //     child: CircularProgressIndicator(
                  //       color: Colors.white,
                  //       strokeWidth: 3,
                  //     ),
                  //   ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}
