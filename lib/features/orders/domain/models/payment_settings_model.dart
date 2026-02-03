class PaymentSettingsModel {
  final String paymentTerms;
  final String currency;
  final String contactPerson;
  final String contactEmail;
  final String validity;

  PaymentSettingsModel({
    required this.paymentTerms,
    required this.currency,
    required this.contactPerson,
    required this.contactEmail,
    required this.validity,
  });

  factory PaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    return PaymentSettingsModel(
      paymentTerms: json['payment_terms']?.toString() ?? '',
      currency: json['currency']?.toString().toUpperCase() ?? 'USD',
      contactPerson: json['contact_person']?.toString() ?? '',
      contactEmail: json['contact_email']?.toString() ?? '',
      validity: json['validity']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_terms': paymentTerms,
      'currency': currency,
      'contact_person': contactPerson,
      'contact_email': contactEmail,
      'validity': validity,
    };
  }
}

