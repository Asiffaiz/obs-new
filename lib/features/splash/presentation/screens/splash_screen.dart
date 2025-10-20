import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/constants/shared_prefence_keys.dart';
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background SVG
            SvgPicture.asset(
              'assets/images/splash_background.svg',
              fit: BoxFit.cover,
            ),
            // Logo with animations
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Image.asset(
                        'assets/images/splash_logo.png',
                        width: 220,
                        height: 220,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
