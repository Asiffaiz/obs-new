import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../data/repositories/mock_agreements_repository_impl.dart';
import '../../data/services/agreements_service.dart';
import '../bloc/agreements_bloc.dart';
import 'optional_unsigned_agreements_screen.dart';

class OptionalAgreementsWrapperScreen extends StatelessWidget {
  const OptionalAgreementsWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create:
            (context) => AgreementsBloc(
              agreementsRepository: MockAgreementsRepositoryImpl(
                agreementsService: GetIt.instance<AgreementService>(),
              ),
            ),
        child: const OptionalUnsignedAgreementsScreen(),
      ),
    );
  }
}
