import 'package:voicealerts_obs/features/auth/domain/models/user_model.dart';
import 'package:voicealerts_obs/features/bussiness%20card/domain/models/business_card_model.dart';

abstract class BusinessCardState {}

class BusinessCardInitial extends BusinessCardState {}

class BusinessCardLoading extends BusinessCardState {}

class BusinessCardsLoaded extends BusinessCardState {
  final List<BusinessCard> businessCards;

  BusinessCardsLoaded(this.businessCards);
}

class BusinessCardDetailLoaded extends BusinessCardState {
  final BusinessCard businessCard;

  BusinessCardDetailLoaded(this.businessCard);
}

class BusinessCardError extends BusinessCardState {
  final String message;

  BusinessCardError(this.message);
}

////////////
class BusinessCardSigninRequested extends BusinessCardState {}

class BusinessCardSigninRequestedLoading extends BusinessCardState {}

class BusinessCardSigninRequestedSuccess extends BusinessCardState {
  final Map<String, dynamic> additionalData;

  BusinessCardSigninRequestedSuccess({required this.additionalData});
}

class BusinessCardSigninRequestedError extends BusinessCardState {
  final String message;

  BusinessCardSigninRequestedError(this.message);
}

class BusinessCardUserExists extends BusinessCardState {
  final Map<String, dynamic> user;

  BusinessCardUserExists(this.user);
}

class BusinessCardUserDoesNotExist extends BusinessCardState {}
