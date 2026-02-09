class OrderCommentModel {
  final int id;
  final String? quoteAccountNo;
  final String? fromAdmin;
  final String? adminAccountNo;
  final String? fromAgent;
  final String? agentAccountNo;
  final DateTime dateAdded;
  final String? fromClient;
  final String? clientAccountNo;
  final String conversation;
  final String? quoteFile;
  final String conversationType;
  final String orderNo;

  OrderCommentModel({
    required this.id,
    this.quoteAccountNo,
    this.fromAdmin,
    this.adminAccountNo,
    this.fromAgent,
    this.agentAccountNo,
    required this.dateAdded,
    this.fromClient,
    this.clientAccountNo,
    required this.conversation,
    this.quoteFile,
    required this.conversationType,
    required this.orderNo,
  });

  factory OrderCommentModel.fromJson(Map<String, dynamic> json) {
    return OrderCommentModel(
      id: json['id'] ?? 0,
      quoteAccountNo: json['quote_accountno'],
      fromAdmin: json['from_admin'],
      adminAccountNo: json['admin_accountno'],
      fromAgent: json['from_agent'],
      agentAccountNo: json['agent_accountno'],
      dateAdded: json['dateAdded'] != null
          ? DateTime.parse(json['dateAdded'])
          : DateTime.now(),
      fromClient: json['from_client'],
      clientAccountNo: json['client_accountno'],
      conversation: json['conversation'] ?? '',
      quoteFile: json['quote_file'],
      conversationType: json['conversation_type'] ?? 'all',
      orderNo: json['orderno'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote_accountno': quoteAccountNo,
      'from_admin': fromAdmin,
      'admin_accountno': adminAccountNo,
      'from_agent': fromAgent,
      'agent_accountno': agentAccountNo,
      'dateAdded': dateAdded.toIso8601String(),
      'from_client': fromClient,
      'client_accountno': clientAccountNo,
      'conversation': conversation,
      'quote_file': quoteFile,
      'conversation_type': conversationType,
      'orderno': orderNo,
    };
  }

  String get fromName {
    if (fromAdmin != null && fromAdmin!.isNotEmpty) {
      return fromAdmin!;
    } else if (fromAgent != null && fromAgent!.isNotEmpty) {
      return fromAgent!;
    } else if (fromClient != null && fromClient!.isNotEmpty) {
      return fromClient!;
    }
    return 'Unknown';
  }

  String get fromType {
    if (fromAdmin != null && fromAdmin!.isNotEmpty) {
      return 'Admin';
    } else if (fromAgent != null && fromAgent!.isNotEmpty) {
      return 'Agent';
    } else if (fromClient != null && fromClient!.isNotEmpty) {
      return 'Client';
    }
    return 'System';
  }
}

