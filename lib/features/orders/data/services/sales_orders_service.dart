import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/constants/network_urls.dart';
import 'package:voicealerts_obs/core/constants/shared_prefence_keys.dart';
import 'package:voicealerts_obs/core/network/api_client.dart';
import 'package:voicealerts_obs/core/network/api_endpoints.dart';
import 'package:voicealerts_obs/core/services/token_service.dart';
import 'package:voicealerts_obs/features/orders/domain/models/payment_complete_details_model.dart';
import 'package:voicealerts_obs/features/orders/domain/models/sales_order_model.dart';

class SalesOrdersService {
  final ApiClient _apiClient = ApiClient();
  final TokenService _tokenService = TokenService();

  // Get account number from shared preferences
  Future<String> getAccountNo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SharedPreferenceKeys.accountNoKey) ?? '';
  }

  // Fetch sales orders from API
  Future<List<SalesOrderModel>> getSalesOrders() async {
    try {
      final accountNo = await getAccountNo();

      if (accountNo.isEmpty) {
        throw Exception('Account number not found');
      }

      final response = await _apiClient.post(ApiEndpoints.listSalesOrders, {
        'accountno': accountNo,
      });

      if (response.statusCode == 200 && response.data['status'] == 200) {
        final List<dynamic> ordersData = response.data['data'] ?? [];
        return ordersData
            .map((item) => SalesOrderModel.fromJson(item))
            .toList();
      } else if (response.statusCode == 200 && response.data['status'] == 404) {
        return [];
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get sales orders',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while fetching sales orders: ${e.toString()}',
      );
    }
  }

  // Fetch payment complete details for an order
  Future<PaymentCompleteDetailsModel> getPaymentCompleteDetails({
    required String accountNo,
    required String orderNo,
  }) async {
    try {
      if (accountNo.isEmpty || orderNo.isEmpty) {
        throw Exception('Account number and order number are required');
      }

      final response = await _apiClient.post(
        ApiEndpoints.getSalesOrderPaymentCompleteDetails,
        {'accountno': accountNo, 'orderno': orderNo},
      );

      if (response.statusCode == 200 && response.data['status'] == 200) {
        return PaymentCompleteDetailsModel.fromJson(
          response.data['data'] ?? {},
        );
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to get payment details',
        );
      }
    } catch (e) {
      throw Exception(
        'An error occurred while fetching payment details: ${e.toString()}',
      );
    }
  }

  // Submit order as FormData (multipart/form-data)
  Future<bool> submitOrder({
    required String accountNo,
    required String orderNo,
    required String contactEmail,
    required String contactPerson,
    required String currency,
    required String paymentTerms,
    required String validity,
    required String quoteTitle,
    required String quotationNotes,
    required String itemsListJson,
    required String paymentDetails,
    required double serviceGrandSubTotal,
    required double serviceGrandTotal,
    double discountValue = 0,
    double discountValueTotal = 0,
    String discountType = 'amount',
    String discountReason = '',
    double shippingValue = 0,
    double shippingValueTotal = 0,
    String shippingTitle = '',
    double taxValue = 0,
    double taxValueTotal = 0,
    String taxType = 'amount',
    String taxReason = '',
  }) async {
    try {
      final token = await _tokenService.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.saveOrderAndSend),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add form fields
      request.fields['token'] = NetworkUrls.reactAppApiToken;
      request.fields['api_accountno'] = NetworkUrls.reactAppApiACCOUNTNO;
      request.fields['accountno'] = accountNo;
      request.fields['orderno'] = orderNo;
      request.fields['contact_email'] = contactEmail;
      request.fields['contact_person'] = contactPerson;
      request.fields['currency'] = currency.toLowerCase();
      request.fields['payment_terms'] = paymentTerms;
      request.fields['validity'] = validity;
      request.fields['quote_title'] = quoteTitle;
      request.fields['quotation_notes'] = quotationNotes;
      request.fields['items_list'] = itemsListJson;
      request.fields['payment_details'] = paymentDetails;
      request.fields['service_grand_sub_total'] = serviceGrandSubTotal
          .toStringAsFixed(2);
      request.fields['service_grand_total'] = serviceGrandTotal.toStringAsFixed(
        2,
      );
      request.fields['discount_value'] = discountValue.toStringAsFixed(2);
      request.fields['discount_value_total'] = discountValueTotal
          .toStringAsFixed(2);
      request.fields['discount_type'] = discountType;
      request.fields['discount_reason'] = discountReason;
      request.fields['shipping_value'] = shippingValue.toStringAsFixed(2);
      request.fields['shipping_value_total'] = shippingValueTotal
          .toStringAsFixed(2);
      request.fields['shipping_title'] = shippingTitle;
      request.fields['tax_value'] = taxValue.toStringAsFixed(2);
      request.fields['tax_value_total'] = taxValueTotal.toStringAsFixed(2);
      request.fields['tax_type'] = taxType;
      request.fields['tax_reason'] = taxReason;

      if (kDebugMode) {
        print('Submit Order - Sending FormData');
        print('Fields: ${request.fields}');
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('Submit Order Response Status: ${response.statusCode}');
        print('Submit Order Response Body: ${response.body}');
      }

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 200) {
        return true;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to submit order');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting order: $e');
      }
      throw Exception(
        'An error occurred while submitting order: ${e.toString()}',
      );
    }
  }

  // Save order as draft as FormData (multipart/form-data)
  Future<bool> saveOrderAsDraft({
    required String accountNo,
    required String orderNo,
    required String contactEmail,
    required String contactPerson,
    required String currency,
    required String paymentTerms,
    required String validity,
    required String quoteTitle,
    required String quotationNotes,
    required String itemsListJson,
    required String paymentDetails,
    required double serviceGrandSubTotal,
    required double serviceGrandTotal,
    double discountValue = 0,
    double discountValueTotal = 0,
    String discountType = 'amount',
    String discountReason = '',
    String shippingValue = '',
    double shippingValueTotal = 0,
    String shippingTitle = '',
    double taxValue = 0,
    double taxValueTotal = 0,
    String taxType = 'amount',
    String taxReason = '',
  }) async {
    try {
      final token = await _tokenService.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.saveOrderAsDraft),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add form fields
      request.fields['token'] = NetworkUrls.reactAppApiToken;
      request.fields['api_accountno'] = NetworkUrls.reactAppApiACCOUNTNO;
      request.fields['accountno'] = accountNo;
      request.fields['client_accountno'] = accountNo; // Same as accountno
      request.fields['orderno'] = orderNo;
      request.fields['contact_email'] = contactEmail;
      request.fields['contact_person'] = contactPerson;
      request.fields['currency'] = currency.toLowerCase();
      request.fields['payment_terms'] = paymentTerms;
      request.fields['validity'] = validity;
      request.fields['quote_title'] = quoteTitle;
      request.fields['quotation_notes'] = quotationNotes;
      request.fields['quote_notes'] = ''; // Can be null/empty
      request.fields['items_list'] = itemsListJson;
      request.fields['payment_details'] = paymentDetails;
      request.fields['service_grand_sub_total'] = serviceGrandSubTotal
          .toStringAsFixed(2);
      request.fields['service_grand_total'] = serviceGrandTotal.toStringAsFixed(
        2,
      );
      request.fields['discount_value'] = discountValue.toStringAsFixed(2);
      request.fields['discount_value_total'] = discountValueTotal
          .toStringAsFixed(2);
      request.fields['discount_type'] = discountType;
      request.fields['discount_reason'] = discountReason;
      request.fields['shipping_value'] = shippingValue; // Can be empty string
      request.fields['shipping_value_total'] = shippingValueTotal
          .toStringAsFixed(2);
      request.fields['shipping_title'] = shippingTitle;
      request.fields['tax_value'] = taxValue.toStringAsFixed(2);
      request.fields['tax_value_total'] = taxValueTotal.toStringAsFixed(2);
      request.fields['tax_type'] = taxType;
      request.fields['tax_reason'] = taxReason;

      if (kDebugMode) {
        print('Save Order as Draft - Sending FormData');
        print('Fields: ${request.fields}');
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('Save Order as Draft Response Status: ${response.statusCode}');
        print('Save Order as Draft Response Body: ${response.body}');
      }

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 200) {
        return true;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to save order as draft',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving order as draft: $e');
      }
      throw Exception(
        'An error occurred while saving order as draft: ${e.toString()}',
      );
    }
  }
}
