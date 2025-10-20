import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '../../domain/models/user_model.dart';
import '../../domain/models/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  // final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final AuthService _authService;
  String? _verificationEmail;
  String? _verificationCode;

  AuthRepositoryImpl({
    // required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required AuthService authService,
  }) : // _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _authService = authService;

  // ----- API Authentication Methods -----

  @override
  Future<Map<String, dynamic>> loginWithApi(
    String email,
    String password,
  ) async {
    return await _authService.login(email, password);
  }

  @override
  Future<Map<String, dynamic>> registerWithApi(
    Map<String, dynamic> userData,
  ) async {
    return await _authService.register(userData);
  }

  @override
  Future<bool> isApiLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  @override
  Future<Map<String, String>> getApiUserData() async {
    return await _authService.getUserData();
  }

  @override
  Future<void> apiLogout() async {
    await _authService.logout();
  }

  // ----- Firebase Authentication Methods -----

  @override
  Future<UserModel?> getCurrentUser() async {
    // final user = _firebaseAuth.currentUser;
    final user = null;
    if (user == null) {
      return null;
    }

    return UserModel(
      id: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      phoneNumber: user.phoneNumber,
    );
  }

  // @override
  // Future<AuthResult> signInWithEmailPassword(
  //   String email,
  //   String password,
  // ) async {
  //   try {
  //     final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );

  //     final user = userCredential.user;
  //     if (user == null) {
  //       return AuthResult.error("User not found after sign in");
  //     }

  //     final userModel = UserModel(
  //       id: user.uid,
  //       displayName: user.displayName,
  //       email: user.email,
  //       photoUrl: user.photoURL,
  //       isEmailVerified: user.emailVerified,
  //       phoneNumber: user.phoneNumber,
  //     );

  //     return AuthResult.authenticated(userModel);
  //   } on FirebaseAuthException catch (e) {
  //     // Use logger instead of print in production
  //     // Logger.e('Failed to sign in: ${e.message}');
  //     return AuthResult.error(e.message ?? 'Authentication failed');
  //   }
  // }

  // @override
  // Future<AuthResult> signUpWithEmailPassword(
  //   String email,
  //   String password,
  //   String firstName,
  //   String lastName,
  // ) async {
  //   try {
  //     final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );

  //     final user = userCredential.user;
  //     if (user != null) {
  //       final displayName = '$firstName $lastName';
  //       await user.updateDisplayName(displayName);

  //       final userModel = UserModel(
  //         id: user.uid,
  //         displayName: displayName,
  //         email: user.email,
  //         photoUrl: user.photoURL,
  //         isEmailVerified: user.emailVerified,
  //         phoneNumber: user.phoneNumber,
  //       );

  //       return AuthResult.authenticated(userModel);
  //     }

  //     return AuthResult.error("User creation failed");
  //   } on FirebaseAuthException catch (e) {
  //     // Use logger instead of print in production
  //     // Logger.e('Failed to sign up: ${e.message}');
  //     return AuthResult.error(e.message ?? 'Registration failed');
  //   }
  // }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Sign out first to force the account selection dialog
      await _googleSignIn.signOut();

      // Now sign in to show the account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.canceled();
      }

      // 👇 Await here
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('idToken ======> ${googleAuth.idToken}');
      print('accessToken => ${googleAuth.accessToken}');
      print('googleUser======>: ${googleUser}');
      // Get user information from Google account without Firebase authentication
      final userModel = UserModel(
        id: googleUser.id,
        displayName: googleUser.displayName,
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
        isEmailVerified: true, // Google accounts are verified
        phoneNumber: null,
        idToken: googleAuth.idToken,
      );

      // Return user data for registration form or API authentication
      return AuthResult.authenticated(userModel);
    } on PlatformException catch (e) {
      return AuthResult.error(e.message ?? 'Google sign in failed');
    } catch (e) {
      return AuthResult.error('Failed to sign in with Google: $e');
    }
  }

  // @override
  // Future<AuthResult> signInWithApple() async {
  //   if (!kIsWeb) {
  //     try {
  //       final credential = await SignInWithApple.getAppleIDCredential(
  //         scopes: [
  //           AppleIDAuthorizationScopes.email,
  //           AppleIDAuthorizationScopes.fullName,
  //         ],
  //       );

  //       final oauthCredential = OAuthProvider('apple.com').credential(
  //         idToken: credential.identityToken,
  //         accessToken: credential.authorizationCode,
  //       );

  //       final userCredential = await _firebaseAuth.signInWithCredential(
  //         oauthCredential,
  //       );
  //       final user = userCredential.user;

  //       if (user == null) {
  //         return AuthResult.error("User not found after Apple sign in");
  //       }

  //       // Apple Sign In doesn't always return the user's name
  //       String? displayName;

  //       if (credential.givenName != null && credential.familyName != null) {
  //         displayName = '${credential.givenName} ${credential.familyName}';
  //       } else if (user.displayName != null) {
  //         displayName = user.displayName;
  //       }

  //       final userModel = UserModel(
  //         id: user.uid,
  //         displayName: displayName,
  //         email: user.email ?? credential.email,
  //         photoUrl: user.photoURL,
  //         isEmailVerified: user.emailVerified,
  //         phoneNumber: user.phoneNumber,
  //       );

  //       return AuthResult.authenticated(userModel);
  //     } on SignInWithAppleException catch (e) {
  //       // Use logger instead of print in production
  //       // Logger.e('Failed to sign in with Apple: ${e}');
  //       return AuthResult.error(e.toString());
  //     }
  //   }
  //   return AuthResult.error("Apple sign in is not available on this platform");
  // }

  @override
  Future<AuthResult> completeSocialRegistration({
    required String socialId,
    required String authProvider,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    bool marketingConsent = false,
  }) async {
    try {
      // Implementation for social registration completion
      // This would typically update the user profile with additional information

      // Here you would use Firebase to update the user profile
      //    final user = _firebaseAuth.currentUser;
      final user = null;
      if (user == null) {
        return AuthResult.error("User not found");
      }

      // Update the display name
      final displayName = '$firstName $lastName';
      await user.updateDisplayName(displayName);

      // You might store additional data in Firestore or another database

      final userModel = UserModel(
        id: user.uid,
        displayName: displayName,
        email: email,
        photoUrl: user.photoURL,
        isEmailVerified: user.emailVerified,
        phoneNumber: phoneNumber,
        // Store additional data in customData
        customData: {
          'address': address,
          'city': city,
          'state': state,
          'zipCode': zipCode,
          'country': country,
          'marketingConsent': marketingConsent,
        },
      );

      return AuthResult.authenticated(userModel);
    } catch (e) {
      // Use logger instead of print in production
      // Logger.e('Failed to complete social registration: ${e}');
      return AuthResult.error("Failed to complete profile: ${e.toString()}");
    }
  }

  @override
  Future<bool> resetPassword(String email) async {
    try {
      _verificationEmail = email;
      // await _firebaseAuth.sendPasswordResetEmail(email: email);

      // Instead of using Firebase, use our API to send a PIN code
      final result = await _authService.sendForgotPasswordPinCode(email);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> sendVerifyRegisterCode(String email) async {
    try {
      final result = await _authService.sendVerifyRegisterCode(email);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> verifyCode(String email, String code, String pincodeFor) async {
    try {
      _verificationEmail = email;
      _verificationCode = code;

      // Use our API to verify the PIN code
      final result = await _authService.verifyPinCode(email, code, pincodeFor);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> setNewPassword(String newPassword, String email) async {
    try {
      // We need the email and code from the verification step
      if (_verificationEmail == null || _verificationCode == null) {
        return false;
      }

      // Use our API to set the new password
      final result = await _authService.setNewPassword(
        _verificationEmail!,
        _verificationCode!,
        newPassword,
      );

      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  void setVerificationData(String email, String code) {
    _verificationEmail = email;
    _verificationCode = code;
  }

  @override
  Future<bool> signOut() async {
    try {
      // Only sign out from Google, not Firebase
      await _googleSignIn.signOut();

      // Clear API auth tokens
      await apiLogout();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Google sign-in flow methods
  @override
  Future<Map<String, dynamic>> checkUserExists(
    String email,
    String idToken,
  ) async {
    try {
      // Use AuthService to check if user exists
      final result = await _authService.checkUserExists(email, idToken);

      return result;
    } catch (e) {
      // If API call fails, assume user doesn't exist
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getUserDataByEmail(String email) async {
    try {
      // Get user info from Google Sign-In
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null || googleUser.email != email) {
        return {};
      }

      // Use AuthService to login with Google
      final result = await _authService.loginWithGoogle(
        googleUser.email,
        googleUser.displayName ?? '',
        googleUser.photoUrl,
      );

      if (result['success'] == true) {
        return result['data'] ?? {};
      }

      return {};
    } catch (e) {
      return {};
    }
  }
}
