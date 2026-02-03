class SalesOrderModel {
  final String orderNo;
  final String? quoteAccountNo;
  final String accountNo;
  final DateTime dateCreated;
  final DateTime? dateUpdated;
  final String quoteStatus; // pending, completed
  final String quoteAttachment;
  final String paymentStatus; // unpaid, paid
  final String quoteTitle;

  SalesOrderModel({
    required this.orderNo,
    this.quoteAccountNo,
    required this.accountNo,
    required this.dateCreated,
    this.dateUpdated,
    required this.quoteStatus,
    required this.quoteAttachment,
    required this.paymentStatus,
    required this.quoteTitle,
  });

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderModel(
      orderNo: json['orderno']?.toString() ?? '',
      quoteAccountNo: json['quote_accountno']?.toString(),
      accountNo: json['accountno']?.toString() ?? '',
      dateCreated: json['dateCreated'] != null
          ? DateTime.parse(json['dateCreated'])
          : DateTime.now(),
      dateUpdated: json['dateUpdated'] != null
          ? DateTime.parse(json['dateUpdated'])
          : null,
      quoteStatus: json['quote_status']?.toString().toLowerCase() ?? 'pending',
      quoteAttachment: json['quote_attachement']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString().toLowerCase() ?? 'unpaid',
      quoteTitle: json['quote_title']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderno': orderNo,
      'quote_accountno': quoteAccountNo,
      'accountno': accountNo,
      'dateCreated': dateCreated.toIso8601String(),
      'dateUpdated': dateUpdated?.toIso8601String(),
      'quote_status': quoteStatus,
      'quote_attachement': quoteAttachment,
      'payment_status': paymentStatus,
      'quote_title': quoteTitle,
    };
  }

  bool get isCompleted => quoteStatus == 'completed';
  bool get isPending => quoteStatus == 'pending';
  bool get isPaid => paymentStatus == 'paid';
  bool get isUnpaid => paymentStatus == 'unpaid';
}

