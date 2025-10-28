import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicealerts_obs/features/agreements/domain/repositories/agreements_repository.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/auth_result.dart' hide AuthStatus;
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final AgreementsRepository _agreementsRepository;
  AuthBloc({
    required AuthRepository authRepository,
    required AgreementsRepository agreementsRepository,
  }) : _agreementsRepository = agreementsRepository,
       _authRepository = authRepository,
       super(const AuthState()) {


        String userName = '';
        String userEmail = '';
    on<CheckMandatoryAgreements>(_onCheckMandatoryAgreements);
    on<CheckMandatoryAgreementsBeforeLogin>(
      _onCheckMandatoryAgreementsBeforeLogin,
    );
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithEmailPasswordRequested>(_onSignInWithEmailPasswordRequested);
    on<SignUpWithEmailPasswordRequested>(_onSignUpWithEmailPasswordRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignUpWithGoogleRequested>(_onSignUpWithGoogleRequested);
    // on<SignInWithBusinessCardRequested>(_onSignInWithBusinessCardRequested);
    on<SignInWithAppleRequested>(_onSignInWithAppleRequested);
    on<CompleteSocialRegistrationRequested>(
      _onCompleteSocialRegistrationRequested,
    );

    // API Authentication events [Working]
    on<LoginWithApiRequested>(_onLoginWithApiRequested);
    on<ApiLogoutRequested>(_onApiLogoutRequested);
    on<ApiAuthCheckRequested>(_onApiAuthCheckRequested);
    on<RegisterWithApiRequested>(_onRegisterWithApiRequested);
    on<AgreementsCompleted>(_onAgreementsCompleted);
    /////////////////
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<SendVerifyRegisterCodeRequested>(_onSendVerifyRegisterCodeRequested);
    on<SendVerifyRegisterResendCodeRequested>(_onSendVerifyRegisterResendCodeRequested);
    on<ResendVerificationCodeRequested>(_onResendVerificationCodeRequested);
    on<VerifyCodeRequested>(_onVerifyCodeRequested);
    on<SetNewPasswordRequested>(_onSetNewPasswordRequested);
    on<SignOutRequested>(_onSignOutRequested);

    // New Google sign-in flow events
    on<CheckGoogleUserExistsRequested>(_onCheckGoogleUserExistsRequested);
    on<FillRegistrationWithGoogleData>(_onFillRegistrationWithGoogleData);

    // New Business Card sign-in flow events
    // on<CheckBusinessCardUserExistsRequested>(
    //   _onCheckBusinessCardUserExistsRequested,
    // );
    // on<FillRegistrationWithBusinessCardData>(
    //   _onFillRegistrationWithBusinessCardData,
    // );
  }

  Future<void> _onCheckMandatoryAgreements(
    CheckMandatoryAgreements event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final allSigned =
          await _agreementsRepository.areAllMandatoryAgreementsSigned();

      if (allSigned == false) {
        emit(state.copyWith(status: AuthStatus.hasMandatoryAgreements));
        emit(state.copyWith(isHasMandatoryAgreements: true));
      } else {
        emit(state.copyWith(status: AuthStatus.apiAuthenticated));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onCheckMandatoryAgreementsBeforeLogin(
    CheckMandatoryAgreementsBeforeLogin event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final allSigned =
          await _agreementsRepository.areAllMandatoryAgreementsSigned();

      if (allSigned == false) {
        emit(state.copyWith(status: AuthStatus.hasMandatoryAgreements));
        emit(state.copyWith(isHasMandatoryAgreements: true));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<dynamic>? handleCheckMandatoryAgreementsBeforeLogin() async {
    try {
      final allSigned =
          await _agreementsRepository.areAllMandatoryAgreementsSigned();
      print(allSigned);
      return allSigned;
    } catch (e) {
      return null;
    }
  }

  // API Authentication handlers

  Future<void> _onRegisterWithApiRequested(
    RegisterWithApiRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final result = await _authRepository.registerWithApi(event.userData);

      if (result['success'] == true) {
        add(const CheckMandatoryAgreements());
        // emit(
        //   state.copyWith(
        //     status: AuthStatus.apiAuthenticated,
        //     apiUserData: result,
        //   ),
        // );
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: result['message'] ?? 'Registration failed',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onLoginWithApiRequested(
    LoginWithApiRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final result = await _authRepository.loginWithApi(
        event.email,
        event.password,
      );

      if (result['success'] == true) {
        add(const CheckMandatoryAgreements());
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: result['message'] ?? 'Failed to login',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onApiLogoutRequested(
    ApiLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _authRepository.apiLogout();
      emit(
        state.copyWith(status: AuthStatus.unauthenticated, apiUserData: null),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onApiAuthCheckRequested(
    ApiAuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final isLoggedIn = await _authRepository.isApiLoggedIn();

      if (isLoggedIn) {
        final userData = await _authRepository.getApiUserData();
        emit(
          state.copyWith(
            status: AuthStatus.apiAuthenticated,
            apiUserData: userData,
          ),
        );
      } else {
        // Check if Firebase user exists as a fallback
        final user = await _authRepository.getCurrentUser();

        if (user != null) {
          emit(state.copyWith(status: AuthStatus.authenticated, user: user));
        } else {
          emit(state.copyWith(status: AuthStatus.unauthenticated));
        }
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Existing Firebase Authentication handlers

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      // First check if API token exists
      final isApiLoggedIn = await _authRepository.isApiLoggedIn();

      if (isApiLoggedIn) {
        final userData = await _authRepository.getApiUserData();
        emit(
          state.copyWith(
            status: AuthStatus.apiAuthenticated,
            apiUserData: userData,
          ),
        );
        return;
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSignInWithEmailPasswordRequested(
    SignInWithEmailPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      // final result = await _authRepository.signInWithEmailPassword(
      //   event.email,
      //   event.password,
      // );
      final result = null;
      if (result.isAuthenticated) {
        emit(
          state.copyWith(status: AuthStatus.authenticated, user: result.user),
        );
      } else if (result.isError) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: result.errorMessage ?? 'Failed to sign in',
          ),
        );
      } else if (result.isCanceled) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      } else if (result.needsProfileCompletion) {
        emit(
          state.copyWith(
            status: AuthStatus.needsProfileCompletion,
            additionalData: result.additionalData,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSignUpWithEmailPasswordRequested(
    SignUpWithEmailPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      // final result = await _authRepository.signUpWithEmailPassword(
      //   event.email,
      //   event.password,
      //   event.firstName,
      //   event.lastName,
      // );
      final result = null;

      if (result.isAuthenticated) {
        emit(
          state.copyWith(status: AuthStatus.authenticated, user: result.user),
        );
      } else if (result.isError) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: result.errorMessage ?? 'Failed to sign up',
          ),
        );
      } else if (result.isCanceled) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final result = await _authRepository.signInWithGoogle();

      if (result.isAuthenticated && result.user != null) {
        // Store the user data in state
        emit(
          state.copyWith(
            user: result.user,
            status:
                AuthStatus
                    .loading, // Keep loading while we check if user exists
          ),
        );

        // We have user data from Google, now check if this user exists in our API
        add(
          CheckGoogleUserExistsRequested(
            email: result.user!.email ?? '',
            idToken: result.user!.idToken,
            isSignIn: true,
          ),
        );
      } else if (result.isError) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Failed to sign in with Google',
          ),
        );
      } else if (result.isCanceled) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSignUpWithGoogleRequested(
    SignUpWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final result = await _authRepository.signInWithGoogle();

      if (result.isAuthenticated && result.user != null) {
        // Store the user data in state
        emit(
          state.copyWith(
            user: result.user,
            status:
                AuthStatus
                    .loading, // Keep loading while we check if user exists
          ),
        );

        // We have user data from Google, now check if this user exists in our API
        add(
          CheckGoogleUserExistsRequested(
            email: result.user!.email ?? '',
            idToken: result.user!.idToken,
            isSignIn: false,
          ),
        );
      } else if (result.isError) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage:
                result.errorMessage ?? 'Failed to sign in with Google',
          ),
        );
      } else if (result.isCanceled) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  // Future<void> _onSignInWithBusinessCardRequested(
  //   SignInWithBusinessCardRequested event,
  //   Emitter<AuthState> emit,
  // ) async {
  //   emit(state.copyWith(status: AuthStatus.loading));

  //   try {
  //     // We have user data from Business Card, now check if this user exists in our API
  //     add(
  //       CheckBusinessCardUserExistsRequested(
  //         businessCardUser: event.businessCardUser,
  //         email: event.email,
  //       ),
  //     );
  //   } catch (e) {
  //     emit(
  //       state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
  //     );
  //   }
  // }

  Future<void> _onSignInWithAppleRequested(
    SignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      // final result = await _authRepository.signInWithApple();
      final result = null;

      if (result.isAuthenticated) {
        emit(
          state.copyWith(status: AuthStatus.authenticated, user: result.user),
        );
      } else if (result.needsProfileCompletion) {
        emit(
          state.copyWith(
            status: AuthStatus.needsProfileCompletion,
            socialId: result.socialId,
            authProvider: result.authProvider,
            additionalData: result.additionalData,
          ),
        );
      } else if (result.isError) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: result.errorMessage ?? 'Failed to sign in with Apple',
          ),
        );
      } else if (result.isCanceled) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onCompleteSocialRegistrationRequested(
    CompleteSocialRegistrationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final result = await _authRepository.completeSocialRegistration(
        socialId: event.socialId,
        authProvider: event.authProvider,
        email: state.user?.email ?? '',
        firstName: event.firstName,
        lastName: event.lastName,
        phoneNumber: event.phoneNumber,
        address: event.address,
        city: event.city,
        state: event.state,
        zipCode: event.zipCode,
        country: event.country,
        marketingConsent: event.marketingConsent,
      );

      if (result.isAuthenticated) {
        emit(
          state.copyWith(status: AuthStatus.authenticated, user: result.user),
        );
      } else if (result.isError) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage:
                result.errorMessage ?? 'Failed to complete registration',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final success = await _authRepository.resetPassword(event.email);

      if (success) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Failed to send reset password email',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSendVerifyRegisterCodeRequested(
    SendVerifyRegisterCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final success = await _authRepository.sendVerifyRegisterCode(event.email);

      if (success) {
        emit(state.copyWith(status: AuthStatus.registerCodeSent));
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Failed to send reset password email',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

    Future<void> _onSendVerifyRegisterResendCodeRequested(
    SendVerifyRegisterResendCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final success = await _authRepository.sendVerifyRegisterCode(event.email);

      if (success) {
        emit(state.copyWith(status: AuthStatus.registerCodeResent));
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Failed to send reset password email',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  

  Future<void> _onResendVerificationCodeRequested(
    ResendVerificationCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final success = await _authRepository.resetPassword(event.email);

      if (success) {
        emit(state.copyWith(status: AuthStatus.forgotPasswordCodeResent));
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Failed to resend verification code',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onVerifyCodeRequested(
    VerifyCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final success = await _authRepository.verifyCode(
        event.email,
        event.code,
        event.pincodeFor,
      );

      if (success) {
        // PIN verification successful, navigate to reset password screen

        if (event.pincodeFor == 'registration') {
          emit(
            state.copyWith(
              status: AuthStatus.registerPinVerified,
              additionalData: {
                'email': event.email,
                'code': event.code,
                'pincodeFor': event.pincodeFor,
              },
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: AuthStatus.pinVerified,
              additionalData: {
                'email': event.email,
                'code': event.code,
                'pincodeFor': event.pincodeFor,
              },
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Invalid verification code. Please try again.',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSetNewPasswordRequested(
    SetNewPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      // Store the verification data in the repository
      //   _authRepository.setVerificationData(event.email, event.code);

      // Now set the new password
      final success = await _authRepository.setNewPassword(
        event.newPassword,
        event.email,
      );

      if (success) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Failed to set new password. Please try again.',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final success = await _authRepository.signOut();

      if (success) {
        emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Failed to sign out',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void _onAgreementsCompleted(
    AgreementsCompleted event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(isHasMandatoryAgreements: true));
  }

  // New handlers for Google sign-in flow

  Future<void> _onCheckGoogleUserExistsRequested(
    CheckGoogleUserExistsRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Don't change status to loading again since we're already in loading state

    try {
      // Check if user exists in our API
      final userExists = await _authRepository.checkUserExists(
        event.email,
        event.idToken ?? '',
      );

      if (userExists['success'] == true &&
          userExists['requestType'] == "user_login") {
        // If user exists, login with API
        add(const CheckMandatoryAgreements());
      } else {
        // Use the Google user data we already have in state
        if (state.user != null) {
          // If user doesn't exist, fill registration form with Google data
          if (event.isSignIn) {
            emit(
              state.copyWith(
                status: AuthStatus.googleSigninUserNotExistFromGoogleSignIn,
                additionalData: {
                  'email': event.email,
                  'fullName': state.user!.displayName ?? '',
                  'signupHash': userExists['data']['signup_hash'] ?? '',
                },
              ),
            );
          } else {
            add(
              FillRegistrationWithGoogleData(
                email: event.email,
                name: state.user!.displayName ?? '',
                photoUrl: state.user!.photoUrl,
                signupHash: userExists['data']['signup_hash'] ?? '',
              ),
            );
          }
        } else {
          // Handle error if we somehow lost the user data
          emit(
            state.copyWith(
              status: AuthStatus.error,
              errorMessage: 'Failed to get Google user data',
            ),
          );
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: "Something went wrong please try again later",
        ),
      );
    }
  }

  // Future<void> _onCheckBusinessCardUserExistsRequested(
  //   CheckBusinessCardUserExistsRequested event,
  //   Emitter<AuthState> emit,
  // ) async {
  //   // Don't change status to loading again since we're already in loading state

  //   try {
  //     // Check if user exists in our API
  //     final userExists = await _authRepository.checkUserExists(event.email);

  //     if (userExists) {
  //       // If user exists, login with API
  //       final userData = await _authRepository.getUserDataByEmail(event.email);
  //       emit(
  //         state.copyWith(
  //           status: AuthStatus.apiAuthenticated,
  //           apiUserData: userData,
  //         ),
  //       );
  //     } else {
  //       // Use the Google user data we already have in state
  //       if (state.user != null) {
  //         // If user doesn't exist, fill registration form with Google data
  //         add(
  //           FillRegistrationWithBusinessCardData(
  //             email: event.email,
  //             name: event.businessCardUser!.name ?? '',
  //             photoUrl: '',
  //             companyName: event.businessCardUser!.company ?? '',
  //           ),
  //         );
  //       } else {
  //         // Handle error if we somehow lost the user data
  //         emit(
  //           state.copyWith(
  //             status: AuthStatus.error,
  //             errorMessage: 'Failed to get Google user data',
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     emit(
  //       state.copyWith(status: AuthStatus.error, errorMessage: e.toString()),
  //     );
  //   }
  // }

  void _onFillRegistrationWithGoogleData(
    FillRegistrationWithGoogleData event,
    Emitter<AuthState> emit,
  ) {
    // Split the name into first and last name
    final nameParts = event.name.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Emit state with Google user data ready to be filled in registration form
    emit(
      state.copyWith(
        status: AuthStatus.googleUserDataReady,
        additionalData: {
          'email': event.email,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': event.name,
          'photoUrl': event.photoUrl,
          'companyName': event.companyName,
          'signupHash': event.signupHash,
        },
      ),
    );
  }

  // void _onFillRegistrationWithBusinessCardData(
  //   FillRegistrationWithBusinessCardData event,
  //   Emitter<AuthState> emit,
  // ) {
  //   // Split the name into first and last name
  //   final nameParts = event.name.split(' ');
  //   final firstName = nameParts.isNotEmpty ? nameParts.first : '';
  //   final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

  //   // Emit state with Google user data ready to be filled in registration form
  //   emit(
  //     state.copyWith(
  //       status: AuthStatus.businessCardUserDataReady,
  //       additionalData: {
  //         'email': event.email,
  //         'firstName': firstName,
  //         'lastName': lastName,
  //         'fullName': event.name,
  //         'photoUrl': event.photoUrl,
  //         'companyName': event.companyName,
  //       },
  //     ),
  //   );
  // }
}
