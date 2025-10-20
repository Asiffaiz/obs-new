import '../models/user_model.dart';
import '../models/auth_result.dart';

abstract class AuthRepository {
  /// Check if user is already logged in
  Future<UserModel?> getCurrentUser();

  /// Sign in with email and password
  // Future<AuthResult> signInWithEmailPassword(String email, String password);

  /// Login with API (returns a Map with success status, message, and data)
  Future<Map<String, dynamic>> loginWithApi(String email, String password);

  /// Register with API (returns a Map with success status, message, and data)
  Future<Map<String, dynamic>> registerWithApi(Map<String, dynamic> userData);

  /// Check if API token exists and is valid
  Future<bool> isApiLoggedIn();

  /// Get user data from stored API credentials
  Future<Map<String, String>> getApiUserData();

  /// API logout (clear stored credentials)
  Future<void> apiLogout();

  /// Sign up with email and password
  // Future<AuthResult> signUpWithEmailPassword(
  //   String email,
  //   String password,
  //   String firstName,
  //   String lastName,
  // );

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle();

  /// Sign in with Apple
  // Future<AuthResult> signInWithApple();

  /// Complete social registration with additional user info
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
  });

  /// Reset password
  Future<bool> resetPassword(String email);

  /// Send verify register code
  Future<bool> sendVerifyRegisterCode(String email);

  /// Verify reset password code
  Future<bool> verifyCode(String email, String code, String pincodeFor);

  /// Set verification data for password reset
  void setVerificationData(String email, String code);

  /// Set new password
  Future<bool> setNewPassword(String newPassword, String email);

  /// Sign out
  Future<bool> signOut();

  // Google sign-in flow methods
  Future<Map<String, dynamic>> checkUserExists(String email, String idToken);
  Future<Map<String, dynamic>> getUserDataByEmail(String email);
}
