import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/network/api_client.dart';
import 'package:voicealerts_obs/core/network/api_endpoints.dart';
import 'package:voicealerts_obs/features/dashboard/domain/models/dashboard_data_model.dart';
import 'package:voicealerts_obs/features/reports/domain/models/reports_model.dart';

class ReportsService {
  final ApiClient _apiClient = ApiClient();

  // Keys for shared preferences
  static const String _tokenKey = 'client_tkn__';
  static const String _accountNoKey = 'client_acn__';
  static const String _emailKey = 'client_eml__';
  static const String _companyNameKey = 'client_comp_nme__';
  static const String _userTypeKey = 'client_user_type__';
  static const String _parentAccountNoKey = 'client_parent_accountno__';
  static const String _nameKey = 'client_name__';
  static const String _phoneKey = 'client_phone__';
  static const String _addressKey = 'client_adress__';
  static const String _titleKey = 'client_title__';
  static const String _accessTokenKey = 'api_access_token';
  static const String _tokenExpiryKey = 'api_token_expiry';

  // Get user data from shared preferences
  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> userData = {};

    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return {};
    }

    userData['token'] = prefs.getString(_tokenKey) ?? '';
    userData['accountno'] = prefs.getString(_accountNoKey) ?? '';
    userData['email'] = prefs.getString(_emailKey) ?? '';
    userData['comp_name'] = prefs.getString(_companyNameKey) ?? '';
    // userData['user_type'] = prefs.getString(_userTypeKey) ?? '';
    // userData['parent_accountno'] = prefs.getString(_parentAccountNoKey) ?? '';
    userData['name'] = prefs.getString(_nameKey) ?? '';
    userData['phone'] = prefs.getString(_phoneKey) ?? '';
    userData['address'] = prefs.getString(_addressKey) ?? '';
    userData['title'] = prefs.getString(_titleKey) ?? '';

    return userData;
  }

  // Get token from shared preferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get user email from shared preferences
  Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? '';
  }

  // Fetch mandatory agreements from API
  Future<List<ReportsModel>> getReportsData() async {
    try {
      final email = await getUserEmail();
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient.post(ApiEndpoints.getReportsData, {
        'email': email,
        'accountno': accountNo,
      });

      if (response.statusCode == 200 && response.data['status'] == 200) {
        // Parse API response into ApiAgreementModel objects
        final List<dynamic> reportsData = response.data['data'] ?? [];
        final List<ReportsModel> apiReportsData =
            reportsData.map((item) => ReportsModel.fromJson(item)).toList();
        // Convert API models to domain models
        return apiReportsData;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get dashboard data',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while fetching dashboard data: ${e.toString()}',
      );
    }
  }

  // Get authenticated URL for viewing a report
  Future<Map<String, String>> getReportUrl(int reportId) async {
    try {
      final email = await getUserEmail();
      final prefs = await SharedPreferences.getInstance();
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient.post(ApiEndpoints.viewClientReport, {
        'email': email,
        'accountno': accountNo,
        'report_id': reportId,
      });

      if (response.statusCode == 200 && response.data['status'] == 200) {
        final String url = response.data['iframeData'] ?? '';
        return {
          "url": url,
          "title": response.data['data'][0]['title'],
        };
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get report URL');
      }
    } catch (e) {
      throw Exception(
        'An error occurred while fetching report URL: ${e.toString()}',
      );
    }
  }
}
