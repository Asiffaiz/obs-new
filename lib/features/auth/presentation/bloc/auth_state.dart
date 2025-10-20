import 'package:equatable/equatable.dart';
import '../../domain/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  apiAuthenticated,
  unauthenticated,
  needsProfileCompletion,
  hasMandatoryAgreements,
  googleUserDataReady,
  googleSigninUserNotExistFromGoogleSignIn,
  businessCardUserDataReady,
  pinVerified,
  registerPinVerified,
  forgotPasswordCodeSent,
  forgotPasswordCodeResent,
  registerCodeSent,
  registerCodeResent,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? socialId;
  final String? authProvider;
  final Map<String, dynamic>? additionalData;
  final Map<String, dynamic>? apiUserData;
  final bool isHasMandatoryAgreements;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.socialId,
    this.authProvider,
    this.additionalData,
    this.apiUserData,
    this.isHasMandatoryAgreements = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? socialId,
    String? authProvider,
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? apiUserData,
    bool? isHasMandatoryAgreements,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      socialId: socialId ?? this.socialId,
      authProvider: authProvider ?? this.authProvider,
      additionalData: additionalData ?? this.additionalData,
      apiUserData: apiUserData ?? this.apiUserData,
      isHasMandatoryAgreements:
          isHasMandatoryAgreements ?? this.isHasMandatoryAgreements,
    );
  }

  bool get isAuthenticated =>
      status == AuthStatus.authenticated ||
      status == AuthStatus.apiAuthenticated;

  bool get isApiAuthenticated => status == AuthStatus.apiAuthenticated;
  bool get isFirebaseAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get needsProfileCompletion =>
      status == AuthStatus.needsProfileCompletion;

  @override
  List<Object?> get props => [
    status,
    user,
    errorMessage,
    socialId,
    authProvider,
    additionalData,
    apiUserData,
    isHasMandatoryAgreements,
  ];
}
