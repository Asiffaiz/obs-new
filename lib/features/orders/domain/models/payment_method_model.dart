class PaymentMethodModel {
  final String orderNo;
  final String paymentMethod;
  final DateTime dateCreated;
  final String paymentDetails; // HTML content

  PaymentMethodModel({
    required this.orderNo,
    required this.paymentMethod,
    required this.dateCreated,
    required this.paymentDetails,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      orderNo: json['orderno']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      dateCreated: json['dateCreated'] != null
          ? DateTime.parse(json['dateCreated'])
          : DateTime.now(),
      paymentDetails: json['payment_details']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderno': orderNo,
      'payment_method': paymentMethod,
      'dateCreated': dateCreated.toIso8601String(),
      'payment_details': paymentDetails,
    };
  }
}

