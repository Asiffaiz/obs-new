import 'payment_method_model.dart';
import 'payment_settings_model.dart';

class PaymentCompleteDetailsModel {
  final List<PaymentMethodModel> paymentMethods;
  final PaymentSettingsModel paymentSettings;

  PaymentCompleteDetailsModel({
    required this.paymentMethods,
    required this.paymentSettings,
  });

  factory PaymentCompleteDetailsModel.fromJson(Map<String, dynamic> json) {
    // Parse payment methods array
    final paymentMethodData = json['get_sales_order_payment_method'];
    List<PaymentMethodModel> methods = [];
    
    if (paymentMethodData != null && paymentMethodData['data'] != null) {
      final List<dynamic> dataList = paymentMethodData['data'] as List<dynamic>;
      methods = dataList
          .map((item) => PaymentMethodModel.fromJson(item))
          .toList();
    }

    return PaymentCompleteDetailsModel(
      paymentMethods: methods,
      paymentSettings: PaymentSettingsModel.fromJson(
        json['get_sales_order_payment_settings'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'get_sales_order_payment_method': {
        'data': paymentMethods.map((method) => method.toJson()).toList(),
      },
      'get_sales_order_payment_settings': paymentSettings.toJson(),
    };
  }
}

