import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:voicealerts_obs/core/network/api_client.dart';
import 'package:voicealerts_obs/core/network/api_endpoints.dart';
import 'package:voicealerts_obs/features/documents/domain/models/document_model.dart';
import 'package:voicealerts_obs/features/products/domain/models/product_model.dart';

class ProductService {
  final ApiClient _apiClient = ApiClient();
  static const String _accountNoKey = 'client_acn__';
  static const String _emailKey = 'client_eml__';

  Future<List<ProductModel>> getProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_emailKey) ?? '';
      final accountNo = prefs.getString(_accountNoKey) ?? '';

      final response = await _apiClient.post(ApiEndpoints.getClientProducts, {
        'email': email,
        'accountno': accountNo,
      });
      print(response.data);
      if (response.statusCode == 200) {
        if (response.data['status'] == 200 && response.data['data'] != null) {
          final List<dynamic> productsData = response.data['data'];
          return productsData
              .map((data) => ProductModel.fromJson(data))
              .toList();
        }
      }

      throw Exception('Failed to load products');
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }


}
