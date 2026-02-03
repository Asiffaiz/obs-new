import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicealerts_obs/core/constants/shared_prefence_keys.dart';
import 'package:voicealerts_obs/core/network/api_client.dart';
import 'package:voicealerts_obs/core/network/api_endpoints.dart';
import 'package:voicealerts_obs/features/orders/domain/models/sales_order_model.dart';

class SalesOrdersService {
  final ApiClient _apiClient = ApiClient();

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

      final response = await _apiClient.post(
        ApiEndpoints.listSalesOrders,
        {'accountno': accountNo},
      );

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
}

