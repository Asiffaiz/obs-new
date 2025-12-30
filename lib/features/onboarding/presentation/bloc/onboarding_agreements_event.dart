import 'package:equatable/equatable.dart';

abstract class OnboardingAgreementsEvent extends Equatable {
  const OnboardingAgreementsEvent();

  @override
  List<Object?> get props => [];
}

class LoadOnboardingAgreements extends OnboardingAgreementsEvent {
  final String accountNo;
  final String email;

  const LoadOnboardingAgreements({
    required this.accountNo,
    required this.email,
  });

  @override
  List<Object?> get props => [accountNo, email];
}

