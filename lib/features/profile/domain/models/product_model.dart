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
