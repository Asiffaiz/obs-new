import 'package:voicealerts_obs/features/profile/data/services/profile_service.dart';

class ProfileRepository {
  final ProfileService _profileService = ProfileService();

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profile,
  ) async {
    try {
      return await _profileService.updateProfile(profile);
    } catch (e) {
      rethrow;
    }
  }
}
