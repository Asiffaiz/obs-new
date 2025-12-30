import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/onboarding_agreements_repository.dart';
import 'onboarding_agreements_event.dart';
import 'onboarding_agreements_state.dart';

class OnboardingAgreementsBloc
    extends Bloc<OnboardingAgreementsEvent, OnboardingAgreementsState> {
  final OnboardingAgreementsRepository _repository;

  OnboardingAgreementsBloc({required OnboardingAgreementsRepository repository})
    : _repository = repository,
      super(const OnboardingAgreementsState()) {
    on<LoadOnboardingAgreements>(_onLoadOnboardingAgreements);
  }

  Future<void> _onLoadOnboardingAgreements(
    LoadOnboardingAgreements event,
    Emitter<OnboardingAgreementsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: OnboardingAgreementsStatus.loading));

      final response = await _repository.getOnboardingAgreements(
        accountNo: event.accountNo,
        email: event.email,
      );

      emit(
        state.copyWith(
          status: OnboardingAgreementsStatus.loaded,
          signedAgreements: response.signedAgreements,
          optionalAgreements: response.optionalAgreements,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: OnboardingAgreementsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
