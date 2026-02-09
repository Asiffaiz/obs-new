import 'package:voicealerts_obs/features/orders/domain/models/order_comment_model.dart';
import 'package:voicealerts_obs/features/orders/domain/models/order_details_model.dart';
import 'package:voicealerts_obs/features/orders/domain/models/order_document_model.dart';
import 'package:voicealerts_obs/features/orders/domain/models/payment_complete_details_model.dart';

class SalesOrderViewDetailsModel {
  final PaymentCompleteDetailsModel paymentDetails;
  final OrderDetailsModel orderDetails;
  final List<OrderCommentModel> comments;
  final List<OrderDocumentModel> documents;
  final bool hasPaymentLogs;

  SalesOrderViewDetailsModel({
    required this.paymentDetails,
    required this.orderDetails,
    required this.comments,
    required this.documents,
    this.hasPaymentLogs = false,
  });

  factory SalesOrderViewDetailsModel.fromJson(Map<String, dynamic> json) {
    // Parse payment details
    final paymentMethodData = json['get_sales_order_payment_method'] ?? {};
    final paymentSettingsData =
        json['get_sales_order_payment_settings'] ?? {};

    final paymentDetails = PaymentCompleteDetailsModel.fromJson({
      'get_sales_order_payment_method': paymentMethodData,
      'get_sales_order_payment_settings': paymentSettingsData,
    });

    // Parse order details
    final orderData = json['get_single_sales_order'] ?? {};
    final orderDataList = orderData['data'] as List? ?? [];
    final orderDetails = orderDataList.isNotEmpty
        ? OrderDetailsModel.fromJson(orderDataList[0])
        : throw Exception('Order details not found');

    // Parse comments
    final commentsData = json['get_sales_order_comments'] ?? {};
    final commentsList = commentsData['clients'] as List? ?? [];
    final comments = commentsList
        .map((comment) => OrderCommentModel.fromJson(comment))
        .toList();

    // Parse documents
    final documentsData = json['get_sales_order_documents'] ?? {};
    final documentsList = documentsData['data'] as List? ?? [];
    final documents = documentsList
        .map((doc) => OrderDocumentModel.fromJson(doc))
        .toList();

    // Check if payment logs exist
    final paymentLogsData = json['get_sales_order_payment_logs'] ?? {};
    final hasPaymentLogs =
        paymentLogsData['message'] != 'not_found' &&
        (paymentLogsData['data'] as List?)?.isNotEmpty == true;

    return SalesOrderViewDetailsModel(
      paymentDetails: paymentDetails,
      orderDetails: orderDetails,
      comments: comments,
      documents: documents,
      hasPaymentLogs: hasPaymentLogs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentDetails': paymentDetails.toJson(),
      'orderDetails': orderDetails.toJson(),
      'comments': comments.map((c) => c.toJson()).toList(),
      'documents': documents.map((d) => d.toJson()).toList(),
      'hasPaymentLogs': hasPaymentLogs,
    };
  }
}

