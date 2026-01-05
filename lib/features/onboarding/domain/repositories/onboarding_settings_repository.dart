import '../models/onboarding_settings_response_model.dart';

abstract class OnboardingSettingsRepository {
  /// Get onboarding settings for the user
  Future<OnboardingSettingsResponseModel> getOnboardingSettings({
    required String accountNo,
    required String email,
  });
}

