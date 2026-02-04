import 'order_service_model.dart';

class OrderDetailsModel {
  final String? quoteAccountNo;
  final String orderNo;
  final String clientAccountNo;
  final DateTime dateCreated;
  final DateTime? dateUpdated;
  final String quoteStatus;
  final String quoteAttachment;
  final String quoteTitle;
  final String? rfqAccountNo;
  final String paymentStatus;
  final String quoteNotes;
  final List<OrderServiceModel> quoteServices;
  final List<dynamic> discounts;
  final List<dynamic> taxes;
  final List<dynamic> shipping;
  final String emailSent;
  final String paymentTerms;
  final String currency;
  final String contactPerson;
  final String contactEmail;
  final String validity;
  final DateTime? dueDate;
  final String orderViaForm;

  OrderDetailsModel({
    this.quoteAccountNo,
    required this.orderNo,
    required this.clientAccountNo,
    required this.dateCreated,
    this.dateUpdated,
    required this.quoteStatus,
    required this.quoteAttachment,
    required this.quoteTitle,
    this.rfqAccountNo,
    required this.paymentStatus,
    required this.quoteNotes,
    required this.quoteServices,
    required this.discounts,
    required this.taxes,
    required this.shipping,
    required this.emailSent,
    required this.paymentTerms,
    required this.currency,
    required this.contactPerson,
    required this.contactEmail,
    required this.validity,
    this.dueDate,
    required this.orderViaForm,
  });

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailsModel(
      quoteAccountNo: json['quote_accountno']?.toString(),
      orderNo: json['orderno']?.toString() ?? '',
      clientAccountNo: json['client_accountno']?.toString() ?? '',
      dateCreated: json['dateCreated'] != null
          ? DateTime.parse(json['dateCreated'])
          : DateTime.now(),
      dateUpdated: json['dateUpdated'] != null
          ? DateTime.parse(json['dateUpdated'])
          : null,
      quoteStatus: json['quote_status']?.toString().toLowerCase() ?? 'pending',
      quoteAttachment: json['quote_attachement']?.toString() ?? '',
      quoteTitle: json['quote_title']?.toString() ?? '',
      rfqAccountNo: json['rfq_accountno']?.toString(),
      paymentStatus: json['payment_status']?.toString().toLowerCase() ?? 'unpaid',
      quoteNotes: json['quote_notes']?.toString() ?? '',
      quoteServices: json['quote_services'] != null
          ? (json['quote_services'] as List)
              .map((e) => OrderServiceModel.fromJson(e))
              .toList()
          : [],
      discounts: json['discounts'] ?? [],
      taxes: json['taxes'] ?? [],
      shipping: json['shipping'] ?? [],
      emailSent: json['email_sent']?.toString() ?? 'No',
      paymentTerms: json['payment_terms']?.toString() ?? '',
      currency: json['currency']?.toString().toUpperCase() ?? 'USD',
      contactPerson: json['contact_person']?.toString() ?? '',
      contactEmail: json['contact_email']?.toString() ?? '',
      validity: json['validity']?.toString() ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : null,
      orderViaForm: json['order_via_form']?.toString() ?? 'No',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quote_accountno': quoteAccountNo,
      'orderno': orderNo,
      'client_accountno': clientAccountNo,
      'dateCreated': dateCreated.toIso8601String(),
      'dateUpdated': dateUpdated?.toIso8601String(),
      'quote_status': quoteStatus,
      'quote_attachement': quoteAttachment,
      'quote_title': quoteTitle,
      'rfq_accountno': rfqAccountNo,
      'payment_status': paymentStatus,
      'quote_notes': quoteNotes,
      'quote_services': quoteServices.map((e) => e.toJson()).toList(),
      'discounts': discounts,
      'taxes': taxes,
      'shipping': shipping,
      'email_sent': emailSent,
      'payment_terms': paymentTerms,
      'currency': currency,
      'contact_person': contactPerson,
      'contact_email': contactEmail,
      'validity': validity,
      'dueDate': dueDate?.toIso8601String(),
      'order_via_form': orderViaForm,
    };
  }
}

