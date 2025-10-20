import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voicealerts_obs/features/agreements/presentation/screens/signed_agreements_main_screen.dart';
import 'package:voicealerts_obs/features/agreements/presentation/screens/unsigned_agreements_screen.dart';
import 'package:voicealerts_obs/features/bussiness%20card/presentation/screens/business_card_form_screen.dart';
import 'package:voicealerts_obs/features/bussiness%20card/presentation/screens/business_card_scan_screen.dart';
import 'package:voicealerts_obs/features/forms/presentation/screens/client_assigned_forms_screen.dart';
import 'package:voicealerts_obs/features/reports/presentation/screens/reports_screen.dart';
import 'package:voicealerts_obs/main.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/auth/presentation/screens/sign_up_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/verification_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/profile_completion_screen.dart';
import '../features/auth/presentation/screens/webview_register_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/onboarding/presentation/screens/welcome_screen.dart';
import '../features/onboarding/presentation/screens/welcome_menu_screen.dart';
import '../features/onboarding/presentation/screens/book_demo_screen.dart';
import '../features/onboarding/presentation/screens/request_quote_screen.dart';
import '../features/agreements/presentation/screens/agreements_wrapper_screen.dart';
import '../features/agreements/presentation/screens/signed_agreements_screen.dart';
import '../features/agreements/presentation/screens/optional_agreements_wrapper_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String welcomeMenu = '/welcome-menu';
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String webViewSignUp = '/webview-sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String verification = '/verification';
  static const String resetPassword = '/reset-password';
  static const String profileCompletion = '/profile-completion';
  static const String home = '/home';
  static const String requestQuote = '/request-quote';
  static const String bookDemo = '/book-demo';
  static const String agreements = '/agreements';
  static const String signedAgreements = '/signed-agreements';
  static const String unsignedAgreements = '/unsigned-agreements';
  static const String optionalAgreements = '/optional-agreements';
  static const String reports = '/reports';
  static const String cardForm = '/card/:id/form';
  static const String scan = '/scan';
  static const String clientAssignedForms = '/client-assigned-forms';
}

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    // navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final authState = authBloc.state;

      // Don't redirect splash screen
      if (state.uri.path == AppRoutes.splash) {
        return null;
      }

      // Redirect to profile completion if needed
      if (authState.needsProfileCompletion) {
        if (state.uri.path != AppRoutes.signUp) {
          return AppRoutes.signUp;
        }
      }

      // Yai khud comment kia hay abhi

      // Handle authenticated users
      // if (authState.isAuthenticated || authState.isApiAuthenticated) {
      //   // Don't redirect if already on agreements screen
      //   if (state.uri.path == AppRoutes.agreements) {
      //     return null;
      //   }

      //   // Check for mandatory agreements first
      // if (authState.status == AuthStatus.hasMandatoryAgreements) {
      //   return AppRoutes.agreements;
      // }

      //   // If no mandatory agreements, don't allow access to auth pages
      //   if (state.uri.path == AppRoutes.signIn ||
      //       state.uri.path == AppRoutes.signUp ||
      //       state.uri.path == AppRoutes.forgotPassword ||
      //       state.uri.path == AppRoutes.verification ||
      //       state.uri.path == AppRoutes.resetPassword) {
      //     return AppRoutes.home;
      //   }
      // } else {
      //   // User is not authenticated
      //   // Only allow access to auth pages and onboarding/welcome pages
      //   final isAuthRoute =
      //       state.uri.path == AppRoutes.signIn ||
      //       state.uri.path == AppRoutes.signUp ||
      //       state.uri.path == AppRoutes.webViewSignUp ||
      //       state.uri.path == AppRoutes.forgotPassword ||
      //       state.uri.path == AppRoutes.verification ||
      //       state.uri.path == AppRoutes.resetPassword ||
      //       state.uri.path == AppRoutes.welcome ||
      //       state.uri.path == AppRoutes.welcomeMenu ||
      //       state.uri.path == AppRoutes.onboarding;

      //   // If trying to access protected route while not authenticated, redirect to sign in
      //   if (!isAuthRoute && state.uri.path != AppRoutes.splash) {
      //     return AppRoutes.signIn;
      //   }
      // }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Welcome Screen
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Welcome Menu Screen
      GoRoute(
        path: AppRoutes.welcomeMenu,
        builder: (context, state) => const WelcomeMenuScreen(),
      ),

      // Onboarding Route
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),

      // GoRoute(
      //   path: AppRoutes.signUp,
      //   builder: (context, state) => const SignUpScreen(),
      // ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) {
          // Extract business card data if available
          final businessCardData = state.extra as Map<String, dynamic>?;
          return SignUpScreen(businessCardData: businessCardData);
        },
      ),
      GoRoute(
        path: AppRoutes.webViewSignUp,
        builder: (context, state) => const WebViewRegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verification,
        builder: (context, state) {
          final email = state.extra as String?;
          return VerificationScreen(email: email ?? '');
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          // Extract email and code from extra data if available
          String? email;
          String? code;

          if (state.extra != null) {
            if (state.extra is Map) {
              final Map<String, dynamic> extraData =
                  state.extra as Map<String, dynamic>;
              email = extraData['email'] as String?;
              code = extraData['code'] as String?;
            }
          }

          return ResetPasswordScreen(email: email, code: code);
        },
      ),
      GoRoute(
        path: AppRoutes.profileCompletion,
        builder: (context, state) => const ProfileCompletionScreen(),
      ),

      // Dashboard Route
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const DashboardScreen(),
      ),

      // Request Quote Route
      GoRoute(
        path: AppRoutes.requestQuote,
        builder: (context, state) => const RequestQuoteScreen(),
      ),

      // Book Demo Route
      GoRoute(
        path: AppRoutes.bookDemo,
        builder: (context, state) => const BookDemoScreen(),
      ),

      // Main Agreements Route
      GoRoute(
        path: AppRoutes.agreements,
        builder: (context, state) => const AgreementsWrapperScreen(),
      ),

      // Unsigned Agreements Route
      GoRoute(
        path: AppRoutes.unsignedAgreements,
        builder: (context, state) => const AgreementsWrapperScreen(),
      ),

      // Optional Agreements Route
      GoRoute(
        path: AppRoutes.optionalAgreements,
        builder: (context, state) => const OptionalAgreementsWrapperScreen(),
      ),

      // Signed Agreements Route
      GoRoute(
        path: AppRoutes.signedAgreements,
        builder: (context, state) => const SignedAgreementsMainScreen(),
      ),

      // Reports Route
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsScreen(),
      ),

      // Business Card Form Route
      // GoRoute(
      //   path: AppRoutes.cardForm,
      //   builder: (context, state) {
      //     final id = int.parse(state.pathParameters['id']!);
      //     final imagePath = state.extra as String?;
      //     return BusinessCardFormScreen(cardId: id, imagePath: imagePath);
      //   },
      // ),

      // Business Card Scan Route
      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) => const BusinessCardScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.clientAssignedForms,
        builder:
            (context, state) =>
                const ClientAssignedFormsScreen(title: 'Forms', isFrom: ''),
      ),
    ],
  );
}
