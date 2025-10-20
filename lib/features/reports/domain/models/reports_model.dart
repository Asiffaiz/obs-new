import 'package:equatable/equatable.dart';

class ReportsModel extends Equatable {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime publishedAt;
  final int reportStatus;
  final String status;
  final String url;

  const ReportsModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.publishedAt,
    required this.reportStatus,
    required this.status,
    required this.url,
  });

  factory ReportsModel.fromJson(Map<String, dynamic> json) {
    return ReportsModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      publishedAt:
          DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
      reportStatus: json['report_status'] ?? 0,
      status: json['status'] ?? '',
      url: json['url'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    createdAt,
    publishedAt,
    reportStatus,
    status,
    url,
  ];
}
