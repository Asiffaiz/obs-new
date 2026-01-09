import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../../config/routes.dart';
import 'agreements_screen.dart';

class AgreementsWrapperScreen extends StatelessWidget {
  const AgreementsWrapperScreen({super.key});

  Future<void> _navigateAfterAgreementsComplete(BuildContext context) async {
    // Check onboarding status before navigating
    final authService = AuthService();
    final onboardingStatus = await authService.getOnboardingStatus();

    if (context.mounted) {
      if (onboardingStatus != 'complete') {
        // Navigate to onboarding if not completed
        context.go(AppRoutes.clientOnboarding);
      } else {
        // Navigate to home if onboarding is complete
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) {
          // Only listen when user is authenticated and mandatory agreements status changes
          // Don't react to state changes during logout (unauthenticated or loading)
          return current.status != AuthStatus.unauthenticated &&
              current.status != AuthStatus.loading;
        },
        listener: (context, state) {
          // If agreements are no longer mandatory AND user is still authenticated
          // Navigate to appropriate screen based on onboarding status
          // This prevents navigation to home during logout
          if (!state.isHasMandatoryAgreements &&
              state.status != AuthStatus.unauthenticated) {
            _navigateAfterAgreementsComplete(context);
          }
        },
        child: AgreementsScreen(
          onComplete: () {
            // Mark agreements as completed in the auth bloc
            context.read<AuthBloc>().add(const AgreementsCompleted());
          },
        ),
      ),
    );
  }
}
