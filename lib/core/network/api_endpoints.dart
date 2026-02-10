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
  static final String sendVerifyRegisterCode =
      '$baseUrl/appApis/send_registration_pin_verification';
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
  static final String getClientAgreementsListingAll =
      '$baseUrl/appApis/get_client_agreements_listing_all';
  static final String getUnsignedAgreementForClient =
      '$baseUrl/appApis/get_unsigned_agreement_for_client';

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

  // Orders endpoints
  static final String listSalesOrders = '$baseUrl/appApis/list_sales_orders';
  static final String getSalesOrderPaymentCompleteDetails =
      '$baseUrl/appApis/get_sales_order_payment_complete_details';
  static final String saveOrderAndSend = '$baseUrl/appApis/save_order_and_send';
  static final String saveOrderAsDraft = '$baseUrl/appApis/save_order_as_draft';
  static final String getSingleSalesOrder = '$baseUrl/appApis/get_single_sales_order';
  static final String getSalesOrderViewDetails = '$baseUrl/appApis/get_sales_order_view_details';
  static final String uploadOrderDocument = '$baseUrl/appApis/upload_order_document';

  // RFQ endpoints
  static final String getRfqInitialDetails =
      '$baseUrl/appApis/get_rfq_initial_details';
  static final String getRfqEditDetails =
      '$baseUrl/appApis/get_rfq_edit_details';
  static final String submitRfqForm = '$baseUrl/appApis/submit_rfq';
  static final String updateRfq = '$baseUrl/appApis/update_rfq';
  static final String saveRfqFormAsDraft =
      '$baseUrl/appApis/save_rfq_form_as_draft';
  static final String getRfqSubmissions = '$baseUrl/appApis/list_rfqs';
  static final String getSingleRfq = '$baseUrl/appApis/get_single_rfq';
  static final String rfqFileResponse = '$baseUrl/appApis/rfq_file_response';

  // Profile endpoints
  static final String updateClientProfile =
      '$baseUrl/appApis/update_client_profile';

  // Onboarding endpoints
  static final String getOnboardingUser =
      '$baseUrl/appApis/get_onboarding_user';
  static final String updateOnboardingStep =
      '$baseUrl/appApis/save_onboarding_user';

  // Add more endpoints as needed, organized by feature

  static final String privacyPolicy =
      '${NetworkUrls.webBaseUrl}/pages/privacyPolicy';
  static final String termsAndConditions =
      '${NetworkUrls.webBaseUrl}/pages/terms-of-service';
}
