import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/constants/shared_prefence_keys.dart';

Future<String> getReplaceContentData(
  String htmlContent,
  Map<String, dynamic> signatoryDetails,
) async {
  final prefs = await SharedPreferences.getInstance();
  final Map<String, String> userData = {};

  final token = prefs.getString(SharedPreferenceKeys.tokenKey);
  if (token == null || token.isEmpty) {}

  // clinet details
  userData['token'] = prefs.getString(SharedPreferenceKeys.tokenKey) ?? '';
  userData['accountno'] =
      prefs.getString(SharedPreferenceKeys.accountNoKey) ?? '';
  userData['client_email'] =
      prefs.getString(SharedPreferenceKeys.emailKey) ?? '';
  userData['client_comp_name'] =
      prefs.getString(SharedPreferenceKeys.companyNameKey) ?? '*****';
  userData['client_name'] =
      prefs.getString(SharedPreferenceKeys.nameKey) ?? '*****';
  userData['client_phone_no'] =
      prefs.getString(SharedPreferenceKeys.phoneKey) ?? '';
  userData['client_address'] =
      prefs.getString(SharedPreferenceKeys.addressKey) ?? '';
  userData['client_title'] =
      prefs.getString(SharedPreferenceKeys.titleKey) ?? '*****';
  userData['client_city'] = prefs.getString(SharedPreferenceKeys.cityKey) ?? '';
  userData['client_state'] =
      prefs.getString(SharedPreferenceKeys.stateKey) ?? '';
  userData['client_zip'] = prefs.getString(SharedPreferenceKeys.zipKey) ?? '';
  userData['client_country'] =
      prefs.getString(SharedPreferenceKeys.countryKey) ?? '';

  // vendor details
  userData['company_profile_name'] = signatoryDetails['name'] ?? '';
  userData['company_profile_company_name'] = signatoryDetails['company'] ?? '';
  userData['company_profile_title'] = signatoryDetails['title'] ?? '';
  userData['company_profile_email'] = signatoryDetails['email'] ?? '';
  userData['company_profile_phone'] = signatoryDetails['phone'] ?? '';
  userData['company_profile_city'] = signatoryDetails['city'] ?? '';
  userData['company_profile_state'] = signatoryDetails['state'] ?? '';
  userData['company_profile_zip'] = signatoryDetails['zip'] ?? '';
  userData['company_profile_country'] = signatoryDetails['country'] ?? '';
  userData['company_profile_address'] = signatoryDetails['address'] ?? '';
  userData['def_sms_charges'] = signatoryDetails['def_sms_charges'] ?? '';

  // vendor details
  userData['vendor_signor_title'] = signatoryDetails['title'] ?? '';
  userData['vendor_signor_name'] = signatoryDetails['name'] ?? '';
  userData['vendor_signor_address'] = signatoryDetails['address'] ?? '';
  userData['vendor_signor_comp_title'] = signatoryDetails['title'] ?? '';
  userData['vendor_signor_city'] = signatoryDetails['city'] ?? '';
  userData['vendor_signor_state'] = signatoryDetails['state'] ?? '';
  userData['vendor_signor_zip'] = signatoryDetails['zip'] ?? '';
  userData['vendor_signor_phone_no'] = signatoryDetails['phone'] ?? '';
  userData['vendor_signor_email'] = signatoryDetails['email'] ?? '';
  userData['vendor_signor_comp_name'] = signatoryDetails['company'] ?? '';

  // {
  //             "id": 3,
  //             "name": "Waqas Shahid",
  //             "company": "OnboardSoft",
  //             "title": "Sales Manager",
  //             "signature_image": "file-1724106068629.png",
  //             "reseller_accountno": "925329925329",
  //             "status": 1,
  //             "dateAdded": "2024-03-07T20:14:47.000Z",
  //             "fileName": "signature.png",
  //             "email": "wshahid@tcpaas.com",
  //             "phone": "+12123727200",
  //             "address": "58 North Chicago Street",
  //             "address2": "",
  //             "city": "Joliet",
  //             "state": "IL",
  //             "zip": "60432",
  //             "country": "United States"
  //         }

  return replaceAgreementPlaceholders(htmlContent, userData);
}

String replaceAgreementPlaceholders(
  String htmlContent,
  Map<String, dynamic> data,
) {
  final now = DateFormat('MMMM d, yyyy').format(DateTime.now());

  String content = htmlContent;
  // Common replacements
  final replacements = <String, String>{
    '[[SIGNATORY_DETAILS]]': "<div class='signatory_div'></div>",
    '[[AGENT_SIGNOR_TITLE]]': data['resellerCompName'] ?? '',
    '[[CLIENT_SIGNOR_TITLE]]': data['client_title'] ?? '',
    '[[AGENT_SIGNOR_NAME]]': data['client_name'] ?? '',
    '[[CLIENT_SIGNOR_NAME]]': data['client_name'] ?? '',
    '[[AGENT_COMPANY_NAME]]': data['client_comp_name'] ?? '*****',
    // Client Signor Details
    '[[CLIENT_COMPANY_NAME]]': data['client_comp_name'] ?? '',
    '[[CLIENT_SIGNOR_EMAIL]]': data['client_email'] ?? '',
    '[[CLIENT_EMAIL]]': data['client_email'] ?? '',
    '[[CLIENT_PHONE]]': data['client_phone_no'] ?? '',
    '[[CLIENT_SIGNOR_ADDRESS]]': data['client_address'] ?? '',
    '[[CLIENT_ADDRESS]]': data['client_address'] ?? '',
    '[[CLIENT_CITY]]': data['client_city'] ?? '',
    '[[CLIENT_STATE]]': data['client_state'] ?? '',
    '[[CLIENT_SIGNOR_STATE]]': data['client_state'] ?? '',
    '[[CLIENT_ZIP]]': data['client_zip'] ?? '',
    '[[CLIENT_COUNTRY]]': data['client_country'] ?? '',
    '[[CLIENT_FULL_ADDRESS]]': _buildFullAddress(data),
    '[[CONTRACT_DATE]]': now,
    // Vendor Signor Details
    '[[VENDOR_SIGNOR_TITLE]]': data['vendor_signor_title'] ?? '',
    '[[VENDOR_SIGNOR_NAME]]': data['vendor_signor_name'] ?? '',
    '[[VENDOR_SIGNOR_ADDRESS]]': data['vendor_signor_address'] ?? '',
    '[[VENDOR_SIGNOR_COMPANY_TITLE]]': data['vendor_signor_comp_title'] ?? '',
    '[[VENDOR_SIGNOR_CITY]]': data['vendor_signor_city'] ?? '',
    '[[VENDOR_SIGNOR_STATE]]': data['vendor_signor_state'] ?? '',
    '[[VENDOR_SIGNOR_ZIP]]': data['vendor_signor_zip'] ?? '',
    '[[VENDOR_SIGNOR_PHONENO]]': data['vendor_signor_phone_no'] ?? '',
    '[[VENDOR_SIGNOR_EMAIL]]': data['vendor_signor_email'] ?? '',
    '[[VENDOR_CONTRACT_DATE]]': now,
    '[[VENDOR_SIGNOR_COMPANY_NAME]]': data['vendor_signor_comp_name'] ?? '',
    // Company Profile Details
    '[[COMPANY_PROFILE_TITLE]]': data['company_profile_title'] ?? '',
    '[[COMPANY_PROFILE_NAME]]': data['company_profile_name'] ?? '',
    '[[COMPANY_PROFILE_COMPANY_NAME]]':
        data['company_profile_company_name'] ?? '',
    '[[COMPANY_PROFILE_EMAIL]]': data['company_profile_email'] ?? '',
    '[[COMPANY_PROFILE_PHONENO]]': data['company_profile_phone'] ?? '',
    '[[COMPANY_PROFILE_CITY]]': data['company_profile_city'] ?? '',
    '[[COMPANY_PROFILE_STATE]]': data['company_profile_state'] ?? '',
    '[[COMPANY_PROFILE_ZIP]]': data['company_profile_zip'] ?? '',
    '[[COMPANY_PROFILE_COUNTRY]]': data['company_profile_country'] ?? '',
    '[[COMPANY_PROFILE_ADDRESS]]': data['company_profile_address'] ?? '',
    '[[COMPANY_PROFILE_FULL_ADDRESS]]': _buildComapnyFullAddress(data) ?? '',
    '[[DEF_SMS_CHARGES]]': data['def_sms_charges'] ?? '',
    // Add more keys as needed...
  };

  //  Regex-based dynamic replacements
  content = replaceRegexBasedDynamicReplacements(content);

  // Static tags for signs (as in React)
  const vendorSign = "<img src=[[IMG_VENDOR_SIGN]] width='230' height='100' />";
  const clientSign = "<div class='clientsignatory_div'></div>";
  const agentSign = "<img src=[[IMG_AGENT_SIGN]] width='230' height='100' />";

  // Apply static HTML placeholders
  content = content
      .replaceAll('[[CLIENT_SIGN]]', clientSign)
      .replaceAll('[[VENDOR_SIGNOR_SIGN]]', vendorSign)
      .replaceAll('[[AGENT_SIGN]]', agentSign);

  // Bulk replacements
  for (final entry in replacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  return content;
}

String replaceRegexBasedDynamicReplacements(String content) {
  // Replace [[INPUT_TEXTFIELD]]
  content = content.replaceAll(
    '[[INPUT_TEXTFIELD]]',
    '<input class="agreement_input_textfield" type="text" />',
  );

  //  Replace [[INPUT_LABEL_({label})]]
  content = content.replaceAllMapped(
    RegExp(r'\[\[INPUT_LABEL_\{(.+?)\}\]\]'),
    (match) => '<label>${match.group(1)}</label>',
  );

  // Replace [[INPUT_TEXTFIELD_({default})]]
  // content = content.replaceAllMapped(
  //   RegExp(r'\[\[INPUT_TEXTFIELD_\(\{(.+?)\}\)\]\]'),
  //   (match) =>
  //       '<input class="agreement_input_textfield" type="text" value="${match.group(1)}" />',
  // );

  // Replace [[INPUT_TEXTAREA]]
  content = content.replaceAll(
    '[[INPUT_TEXTAREA]]',
    '<textarea class="agreement_input_textarea"></textarea>',
  );

  //  Replace [[INPUT_TEXTAREA_({default})]]
  content = content.replaceAllMapped(
    RegExp(r'\[\[INPUT_TEXTAREA_\(\{(.+?)\}\)\]\]'),
    (match) =>
        '<textarea class="agreement_input_textarea">${match.group(1)}</textarea>',
  );

  // Replace checkbox with or without round brackets
  content = content.replaceAllMapped(
    RegExp(r'\[\[INPUT_CHECKBOX_OPTION_(?:\(\{|\{)(.+?)(?:\}\)|\})\]\]'),
    (match) =>
        '<input type="checkbox" class="agreement_input_checkbox" value="${match.group(1)}" /> ${match.group(1)}',
  );

  content = content.replaceAllMapped(
    RegExp(
      r'\[\[INPUT_CHECKBOX_CHECKED_OPTION_(?:\(\{|\{)(.+?)(?:\}\)|\})\]\]',
    ),
    (match) =>
        '<input type="checkbox" class="agreement_input_checkbox" value="${match.group(1)}" checked /> ${match.group(1)}',
  );
  //  Replace [[INPUT_DROPDOWN_option1+option2(selected)+option3]]
  content = content.replaceAllMapped(RegExp(r'\[\[INPUT_DROPDOWN_(.*?)\]\]'), (
    match,
  ) {
    final options = match.group(1)!.split('+');
    String dropdown = '<select class="agreement_input_dropdown">';
    for (var option in options) {
      final isSelected = option.trim().endsWith('(selected)');
      final value =
          isSelected
              ? option.trim().replaceAll('(selected)', '')
              : option.trim();
      dropdown +=
          '<option value="$value"${isSelected ? ' selected' : ''}>$value</option>';
    }
    dropdown += '</select>';
    return dropdown;
  });

  //  Replace [[INPUT_RADIO_option1+option2(selected)+option3]]
  content = content.replaceAllMapped(RegExp(r'\[\[INPUT_RADIO_(.*?)\]\]'), (
    match,
  ) {
    final options = match.group(1)!.split('+');
    final groupName = 'group_${DateTime.now().millisecondsSinceEpoch}';
    String radios = '';
    for (var option in options) {
      final isSelected = option.trim().endsWith('(selected)');
      final value =
          isSelected
              ? option.trim().replaceAll('(selected)', '')
              : option.trim();
      radios +=
          '<input type="radio" name="$groupName" value="$value"${isSelected ? ' checked' : ''} /> $value<br>';
    }
    return radios;
  });

  return content;
}

String _buildFullAddress(Map<String, dynamic> data) {
  final parts = [
    data['client_address'],
    data['client_city'],
    data['client_state'],
    data['client_zip'],
    data['client_country'],
  ];

  return parts
      .where((part) => part != null && part != '' && part != 'N/A')
      .join(', ');
}

String _buildComapnyFullAddress(Map<String, dynamic> data) {
  final parts = [
    data['company_profile_address'],
    data['company_profile_city'],
    data['company_profile_state'],
    data['company_profile_zip'],
    data['company_profile_country'],
  ];

  return parts
      .where((part) => part != null && part != '' && part != 'N/A')
      .join(', ');
}

String _buildVendorFullAddress(Map<String, dynamic> data) {
  final parts = [
    data['vendor_signor_address'],
    data['vendor_signor_city'],
    data['vendor_signor_state'],
    data['vendor_signor_zip'],
    data['vendor_signor_country'],
  ];

  return parts
      .where((part) => part != null && part != '' && part != 'N/A')
      .join(', ');
}
