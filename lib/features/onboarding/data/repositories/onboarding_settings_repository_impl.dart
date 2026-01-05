import '../../domain/models/onboarding_settings_response_model.dart';
import '../../domain/repositories/onboarding_settings_repository.dart';
import '../services/onboarding_settings_service.dart';

class OnboardingSettingsRepositoryImpl
    implements OnboardingSettingsRepository {
  final OnboardingSettingsService _service;

  OnboardingSettingsRepositoryImpl(this._service);

  @override
  Future<OnboardingSettingsResponseModel> getOnboardingSettings({
    required String accountNo,
    required String email,
  }) async {
    return await _service.getOnboardingSettings(
      accountNo: accountNo,
      email: email,
    );
  }
}

