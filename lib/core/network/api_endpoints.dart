import '../constants/network_urls.dart';

/// Centralized class for all API endpoints
class ApiEndpoints {
  static final String baseUrl = NetworkUrls.apiBaseUrl;

  // Auth endpoints
  static final String authToken = '$baseUrl/auth/auth_token';
  static final String login = '$baseUrl/appApis/client_login';
  static final String register = '$baseUrl/appApis/register_new_client';
  static final String googleLogin = '$baseUrl/appApis/client_login_google';
  static final String checkUser = '$baseUrl/appApis/client_login_Oauth';

  // Password reset endpoints
  static final String forgotPassword = '$baseUrl/appApis/forgot_password';
  static final String sendVerifyRegisterCode = '$baseUrl/appApis/send_registration_pin_verification';
  static final String verifyPinCode = '$baseUrl/appApis/verify_pincode';
  static final String resetPassword = '$baseUrl/appApis/reset_password';

  // Dashboard endpoints
  static final String getDashboardData = '$baseUrl/appApis/get_dashboard_data';

  // Agreements endpoints
  static final String getMandatoryAgreements =
      '$baseUrl/appApis/get_client_agreements_required';
  static final String signAgreementWithDraw =
      '$baseUrl/appApis/sign_agreement_signature';
  static final String signAgreementWithChose =
      '$baseUrl/appApis/sign_agreement_choose';
  static final String signAgreementWithWrite =
      '$baseUrl/appApis/sign_agreement_write';
  static final String getSignedAgreements =
      '$baseUrl/appApis/get_client_agreements_listing';
  static final String getOptionalAgreements =
      '$baseUrl/appApis/get_client_agreements_optional';
  static final String getArchivedAgreements =
      '$baseUrl/appApis/get_archived_agreements';
  static final String sendToSignee =
      '$baseUrl/appApis/send_agreement_to_signee';

  // Reports endpoints
  static final String getReportsData = '$baseUrl/appApis/get_client_reports';
  static final String viewClientReport = '$baseUrl/appApis/view_client_report';

  // Forms endpoints
  static final String getSingleFormToSubmit =
      '$baseUrl/appApis/get_single_form_to_submit';
  static final String getClientAssignedForms =
      '$baseUrl/appApis/get_assigned_forms';
  static final String saveFormAsDraft = '$baseUrl/appApis/save_form_as_draft';
  static final String saveForm = '$baseUrl/appApis/save_form';
  static final String getFormSubmissions =
      '$baseUrl/appApis/get_form_submissions';
  static final String saveFormMedia = '$baseUrl/appApis/save_form_media';

  // Documents endpoints
  static final String getClientDocuments =
      '$baseUrl/appApis/get_client_documents';
  static final String submitDocument = '$baseUrl/appApis/submit_document';
  static final String uploadDocument = '$baseUrl/appApis/upload_document';

  // Products endpoints
  static final String getClientProducts =
      '$baseUrl/appApis/get_client_products';

  // Profile endpoints
  static final String updateClientProfile =
      '$baseUrl/appApis/update_client_profile';

  // Add more endpoints as needed, organized by feature

  static final String privacyPolicy =
      '${NetworkUrls.webBaseUrl}/pages/privacyPolicy';
  static final String termsAndConditions =
      '${NetworkUrls.webBaseUrl}/pages/terms-of-service';
}
