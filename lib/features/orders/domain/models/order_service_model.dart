class OrderServiceModel {
  final int serviceId;
  final String sku;
  final String serviceName;
  final int quantity;
  final String serviceUnit;
  final DateTime dateAdded;
  final DateTime? dateUpdated;
  final String itemType;
  final double servicePrice;
  final String description;

  OrderServiceModel({
    required this.serviceId,
    required this.sku,
    required this.serviceName,
    required this.quantity,
    required this.serviceUnit,
    required this.dateAdded,
    this.dateUpdated,
    required this.itemType,
    required this.servicePrice,
    required this.description,
  });

  factory OrderServiceModel.fromJson(Map<String, dynamic> json) {
    return OrderServiceModel(
      serviceId: json['service_id'] ?? 0,
      sku: json['sku']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      serviceUnit: json['service_unit']?.toString() ?? '',
      dateAdded: json['dateAdded'] != null
          ? DateTime.parse(json['dateAdded'])
          : DateTime.now(),
      dateUpdated: json['dateUpdated'] != null
          ? DateTime.parse(json['dateUpdated'])
          : null,
      itemType: json['item_type']?.toString() ?? 'service',
      servicePrice: (json['service_price'] != null)
          ? (json['service_price'] is int
              ? json['service_price'].toDouble()
              : json['service_price'] as double)
          : 0.0,
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'sku': sku,
      'service_name': serviceName,
      'quantity': quantity,
      'service_unit': serviceUnit,
      'dateAdded': dateAdded.toIso8601String(),
      'dateUpdated': dateUpdated?.toIso8601String(),
      'item_type': itemType,
      'service_price': servicePrice,
      'description': description,
    };
  }
}

