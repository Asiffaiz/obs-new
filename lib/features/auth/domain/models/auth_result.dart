import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum AuthStatus { authenticated, needsProfileCompletion, error, canceled }

class AuthResult extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? socialId; // ID from social provider
  final String? authProvider; // google, apple, etc.
  final String? errorMessage;
  final Map<String, dynamic>? additionalData;

  const AuthResult({
    required this.status,
    this.user,
    this.socialId,
    this.authProvider,
    this.errorMessage,
    this.additionalData,
  });

  factory AuthResult.authenticated(UserModel user) =>
      AuthResult(status: AuthStatus.authenticated, user: user);

  factory AuthResult.needsProfileCompletion({
    required String socialId,
    required String authProvider,
    required Map<String, dynamic> userData,
  }) => AuthResult(
    status: AuthStatus.needsProfileCompletion,
    socialId: socialId,
    authProvider: authProvider,
    additionalData: userData,
  );

  factory AuthResult.error(String message) =>
      AuthResult(status: AuthStatus.error, errorMessage: message);

  factory AuthResult.canceled() =>
      const AuthResult(status: AuthStatus.canceled);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get needsProfileCompletion =>
      status == AuthStatus.needsProfileCompletion;
  bool get isError => status == AuthStatus.error;
  bool get isCanceled => status == AuthStatus.canceled;

  @override
  List<Object?> get props => [
    status,
    user,
    socialId,
    authProvider,
    errorMessage,
    additionalData,
  ];
}
