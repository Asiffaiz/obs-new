import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../config/routes.dart';
import 'agreements_screen.dart';

class AgreementsWrapperScreen extends StatelessWidget {
  const AgreementsWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
       //   If agreements are no longer mandatory, navigate to home
          if (!state.isHasMandatoryAgreements) {
            context.go(AppRoutes.home);
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
