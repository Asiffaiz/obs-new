class ProductModel {
  final int productId;
  final String sku;
  final int serviceTypeId;
  final String productTitle;
  final String productSummary;
  final String productDesc;
  final String marketing;
  final String kycRequired;
  final String integration;
  final String integrationTitle;
  final String formAccountno;
  final String formLink;
  final int rate;
  final List<MiscellaneousRates> miscellaneousRates;
  final List<OtherRates> otherRates;

  ProductModel({
    required this.productId,
    required this.sku,
    required this.serviceTypeId,
    required this.productTitle,
    required this.productSummary,
    required this.productDesc,
    required this.marketing,
    required this.kycRequired,
    required this.integration,
    required this.integrationTitle,
    required this.formAccountno,
    required this.formLink,
    required this.rate,
    required this.miscellaneousRates,
    required this.otherRates,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['id'] ?? 0,
      sku: json['sku'] ?? '',
      serviceTypeId: json['service_type_id'] ?? 0,
      productTitle: json['title'] ?? '',
      productSummary: json['product_summary'] ?? '',
      productDesc: json['product_desc'] ?? '',
      marketing: json['marketing'] ?? '',
      kycRequired: json['kyc_required'] ?? '',
      integration: json['integration'] ?? '',
      integrationTitle: json['integration_title'] ?? '',
      formAccountno: json['form_accountno'] ?? '',
      formLink: json['form_link'] ?? '',
      rate: json['rate'] ?? 0,
      miscellaneousRates:
          json['miscellaneous_rates'] != null
              ? (json['miscellaneous_rates'] as List)
                  .map((e) => MiscellaneousRates.fromJson(e))
                  .toList()
              : [],
      otherRates:
          json['other_rates'] != null
              ? (json['other_rates'] as List)
                  .map((e) => OtherRates.fromJson(e))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': productId,
      'sku': sku,
      'title': productTitle,
      'service_type_id': serviceTypeId,
      'product_summary': productSummary,
      'product_desc': productDesc,
      'marketing': marketing,
      'kyc_required': kycRequired,
      'integration': integration,
      'integration_title': integrationTitle,
      'form_accountno': formAccountno,
      'form_link': formLink,
    };
  }
}

class MiscellaneousRates {
  final String miscTitle;
  final String miscType;
  final double miscRate;

  MiscellaneousRates({
    required this.miscTitle,
    required this.miscType,
    required this.miscRate,
  });

  factory MiscellaneousRates.fromJson(Map<String, dynamic> json) {
    return MiscellaneousRates(
      miscTitle: json['misc_title'] ?? '',
      miscType: json['misc_type'] ?? '',
      miscRate:
          (json['misc_rate'] != null)
              ? (json['misc_rate'] as num).toDouble()
              : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'misc_title': miscTitle,
      'misc_type': miscType,
      'misc_rate': miscRate,
    };
  }
}

class OtherRates {
  final String genericTitle;
  final String genericType;
  final double genericRate;
  String payType;

  OtherRates({
    required this.genericTitle,
    required this.genericType,
    required this.genericRate,
    required this.payType,
  });

  factory OtherRates.fromJson(Map<String, dynamic> json) {
    return OtherRates(
      genericTitle: json['generic_title'] ?? '',
      genericType: json['generic_type'] ?? '',
      genericRate:
          (json['generic_rate'] != null)
              ? (json['generic_rate'] as num).toDouble()
              : 0.0,
      payType: json['pay_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generic_title': genericTitle,
      'generic_type': genericType,
      'generic_rate': genericRate,
      'pay_type': payType,
    };
  }
}
