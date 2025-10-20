import 'package:equatable/equatable.dart';
import 'package:voicealerts_obs/features/bussiness%20card/domain/models/business_card_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class SignInWithEmailPasswordRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailPasswordRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SignUpWithEmailPasswordRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  const SignUpWithEmailPasswordRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  @override
  List<Object?> get props => [email, password, firstName, lastName];
}

class SignInWithGoogleRequested extends AuthEvent {
  const SignInWithGoogleRequested();
}

class SignUpWithGoogleRequested extends AuthEvent {
  const SignUpWithGoogleRequested();
}

// class SignInWithBusinessCardRequested extends AuthEvent {
//   final String email;
//   final BusinessCard? businessCardUser;
//   const SignInWithBusinessCardRequested({
//     required this.email,
//     required this.businessCardUser,
//   });
// }

class SignInWithAppleRequested extends AuthEvent {
  const SignInWithAppleRequested();
}

class CompleteSocialRegistrationRequested extends AuthEvent {
  final String socialId;
  final String authProvider;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final bool marketingConsent;

  const CompleteSocialRegistrationRequested({
    required this.socialId,
    required this.authProvider,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.marketingConsent = false,
  });

  @override
  List<Object?> get props => [
    socialId,
    authProvider,
    firstName,
    lastName,
    phoneNumber,
    address,
    city,
    state,
    zipCode,
    country,
    marketingConsent,
  ];
}

class ResetPasswordRequested extends AuthEvent {
  final String email;

  const ResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}



class ResendVerificationCodeRequested extends AuthEvent {
  final String email;

  const ResendVerificationCodeRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class VerifyCodeRequested extends AuthEvent {
  final String email;
  final String code;
  final String pincodeFor;

  const VerifyCodeRequested({
    required this.email,
    required this.code,
    required this.pincodeFor,
  });

  @override
  List<Object?> get props => [email, code, pincodeFor];
}



class SetNewPasswordRequested extends AuthEvent {
  final String newPassword;
  final String email;
  final String code;

  const SetNewPasswordRequested({
    required this.newPassword,
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [newPassword, email, code];
}

/////////Register Verification
class SendVerifyRegisterCodeRequested extends AuthEvent {
  final String email;

  const SendVerifyRegisterCodeRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class SendVerifyRegisterResendCodeRequested extends AuthEvent {
  final String email;

  const SendVerifyRegisterResendCodeRequested({required this.email});

  @override
  List<Object?> get props => [email];
}


class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class LoginWithApiRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginWithApiRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class ApiLogoutRequested extends AuthEvent {
  const ApiLogoutRequested();
}

class ApiAuthCheckRequested extends AuthEvent {
  const ApiAuthCheckRequested();
}

class RegisterWithApiRequested extends AuthEvent {
  final Map<String, dynamic> userData;

  const RegisterWithApiRequested({required this.userData});

  @override
  List<Object?> get props => [userData];
}

class AgreementsCompleted extends AuthEvent {
  const AgreementsCompleted();
}

class CheckGoogleUserExistsRequested extends AuthEvent {
  final String email;
  final String? idToken;
  final bool isSignIn;

  const CheckGoogleUserExistsRequested({
    required this.email,
    required this.idToken,
    required this.isSignIn,
  });

  @override
  List<Object?> get props => [email, idToken];
}

// class CheckBusinessCardUserExistsRequested extends AuthEvent {
//   final BusinessCard? businessCardUser;
//   final String email;
//   const CheckBusinessCardUserExistsRequested({
//     required this.businessCardUser,
//     required this.email,
//   });

//   @override
//   List<Object?> get props => [businessCardUser];
// }

class FillRegistrationWithGoogleData extends AuthEvent {
  final String email;
  final String name;
  final String? photoUrl;
  final String? companyName;
  final String signupHash;

  const FillRegistrationWithGoogleData({
    required this.email,
    required this.name,
    this.photoUrl,
    this.companyName,
    required this.signupHash,
  });

  @override
  List<Object?> get props => [email, name, photoUrl, companyName];
}

class CheckMandatoryAgreements extends AuthEvent {
  const CheckMandatoryAgreements();
}

class CheckMandatoryAgreementsBeforeLogin extends AuthEvent {
  const CheckMandatoryAgreementsBeforeLogin();
}

// class FillRegistrationWithBusinessCardData extends AuthEvent {
//   final String email;
//   final String name;
//   final String? photoUrl;
//   final String? companyName;

//   const FillRegistrationWithBusinessCardData({
//     required this.email,
//     required this.name,
//     this.photoUrl,
//     this.companyName,
//   });

//   @override
//   List<Object?> get props => [email, name, photoUrl, companyName];
// }
