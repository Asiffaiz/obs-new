class OrderDocumentModel {
  final int id;
  final String orderNo;
  final String documentName;
  final String documentPath;
  final DateTime dateUploaded;
  final String uploadedBy;
  final String? documentType;

  OrderDocumentModel({
    required this.id,
    required this.orderNo,
    required this.documentName,
    required this.documentPath,
    required this.dateUploaded,
    required this.uploadedBy,
    this.documentType,
  });

  factory OrderDocumentModel.fromJson(Map<String, dynamic> json) {
    return OrderDocumentModel(
      id: json['id'] ?? 0,
      orderNo: json['orderno'] ?? '',
      documentName: json['document_name'] ?? '',
      documentPath: json['document_path'] ?? '',
      dateUploaded: json['date_uploaded'] != null
          ? DateTime.parse(json['date_uploaded'])
          : DateTime.now(),
      uploadedBy: json['uploaded_by'] ?? '',
      documentType: json['document_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderno': orderNo,
      'document_name': documentName,
      'document_path': documentPath,
      'date_uploaded': dateUploaded.toIso8601String(),
      'uploaded_by': uploadedBy,
      'document_type': documentType,
    };
  }

  String get fileExtension {
    return documentPath.split('.').last.toLowerCase();
  }

  bool get isPdf => fileExtension == 'pdf';
  bool get isImage => ['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension);
}

