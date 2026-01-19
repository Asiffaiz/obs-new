/// Model for RFQ Product/Service selection
class RfqProduct {
  final int id;
  final String serviceTitle;
  final String? productTitle;
  final String? productDesc;
  final String? productSummary;
  final String? sku;

  RfqProduct({
    required this.id,
    required this.serviceTitle,
    this.productTitle,
    this.productDesc,
    this.productSummary,
    this.sku,
  });

  factory RfqProduct.fromJson(Map<String, dynamic> json) {
    return RfqProduct(
      id: json['id'] as int? ?? 0,
      serviceTitle: (json['service_title'] ?? '').toString(),
      productTitle: json['product_title']?.toString(),
      productDesc: json['product_desc']?.toString(),
      productSummary: json['product_summary']?.toString(),
      sku: json['sku']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'service_title': serviceTitle,
        'product_title': productTitle,
        'product_desc': productDesc,
        'product_summary': productSummary,
        'sku': sku,
      };

  /// Get display name
  String get displayName => serviceTitle;

  /// Get description for display (prefer summary, fallback to desc)
  String get displayDescription {
    if (productSummary != null && productSummary!.trim().isNotEmpty) {
      return productSummary!;
    }
    if (productDesc != null && productDesc!.trim().isNotEmpty) {
      // Strip HTML tags for display
      return productDesc!
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    return 'No description available';
  }
}

