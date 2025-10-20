import 'package:equatable/equatable.dart';
import 'package:voicealerts_obs/features/bussiness%20card/domain/models/business_card_model.dart';

// abstract class BusinessCardEvent {}

abstract class BusinessCardEvent extends Equatable {
  const BusinessCardEvent();

  @override
  List<Object?> get props => [];
}
class LoadBusinessCards extends BusinessCardEvent {}

class LoadBusinessCardDetails extends BusinessCardEvent {
  final int cardId;

 const LoadBusinessCardDetails(this.cardId);
}

class SaveBusinessCard extends BusinessCardEvent {
  final String imagePath;
  final bool useLocalProcessing;

 const  SaveBusinessCard(this.imagePath, {this.useLocalProcessing = false});
}

class SignInWithBusinessCardRequested extends BusinessCardEvent {
  final String email;
  final BusinessCard? businessCardUser;
 const SignInWithBusinessCardRequested({
    required this.email,
    required this.businessCardUser,
  });
}


class CheckBusinessCardUserExistsRequested extends BusinessCardEvent {
  final BusinessCard? businessCardUser;
  final String email;
  const CheckBusinessCardUserExistsRequested({
    required this.businessCardUser,
    required this.email,
  });

  @override
  List<Object?> get props => [businessCardUser];
}


class FillRegistrationWithBusinessCardData extends BusinessCardEvent {
  final String email;
  final String name;
  final String? photoUrl;
  final String? companyName;

  const FillRegistrationWithBusinessCardData({
    required this.email,
    required this.name,
    this.photoUrl,
    this.companyName,
  });

  @override
  List<Object?> get props => [email, name, photoUrl, companyName];
}
