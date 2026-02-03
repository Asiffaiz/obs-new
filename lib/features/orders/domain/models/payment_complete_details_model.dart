import 'payment_method_model.dart';
import 'payment_settings_model.dart';

class PaymentCompleteDetailsModel {
  final PaymentMethodModel paymentMethod;
  final PaymentSettingsModel paymentSettings;

  PaymentCompleteDetailsModel({
    required this.paymentMethod,
    required this.paymentSettings,
  });

  factory PaymentCompleteDetailsModel.fromJson(Map<String, dynamic> json) {
    return PaymentCompleteDetailsModel(
      paymentMethod: PaymentMethodModel.fromJson(
        json['get_sales_order_payment_method'] ?? {},
      ),
      paymentSettings: PaymentSettingsModel.fromJson(
        json['get_sales_order_payment_settings'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'get_sales_order_payment_method': paymentMethod.toJson(),
      'get_sales_order_payment_settings': paymentSettings.toJson(),
    };
  }
}

