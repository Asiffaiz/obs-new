import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:voicealerts_obs/features/agreements/data/services/agreements_service.dart';
import 'package:voicealerts_obs/features/agreements/presentation/screens/unsigned_agreements_screen.dart';
import 'package:voicealerts_obs/features/auth/data/services/auth_service.dart';
import '../bloc/agreements_bloc.dart';
import '../bloc/agreements_state.dart';
import '../../data/repositories/mock_agreements_repository_impl.dart';
import 'signed_agreements_main_screen.dart';

class AgreementsScreen extends StatelessWidget {
  final VoidCallback? onComplete;

  const AgreementsScreen({super.key, this.onComplete});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => AgreementsBloc(
            agreementsRepository: MockAgreementsRepositoryImpl(
              agreementsService: GetIt.instance<AgreementService>(),
            ),
          ),
      child: AgreementsScreenContent(onComplete: onComplete),
    );
  }
}

class AgreementsScreenContent extends StatelessWidget {
  final VoidCallback? onComplete;

  const AgreementsScreenContent({super.key, this.onComplete});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgreementsBloc, AgreementsState>(
      builder: (context, state) {
        switch (state.viewMode) {
          case AgreementViewMode.list:
            return UnsignedAgreementsScreen(onComplete: onComplete);
          case AgreementViewMode.detail:
          case AgreementViewMode.sign:
          case AgreementViewMode.sendToSignee:
            if (state.currentAgreement != null) {
              // The navigation to detail screen is handled in the list screen
              // This is just a fallback in case we're starting directly in detail mode
              return UnsignedAgreementsScreen(onComplete: onComplete);
            } else {
              return UnsignedAgreementsScreen(onComplete: onComplete);
            }
          default:
            return UnsignedAgreementsScreen(onComplete: onComplete);
        }
      },
    );
  }
}
