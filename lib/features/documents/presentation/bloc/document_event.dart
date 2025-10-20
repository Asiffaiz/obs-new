import 'package:equatable/equatable.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocuments extends DocumentEvent {
  const LoadDocuments();
}

class UploadDocument extends DocumentEvent {
  final String filePath;
  final int documentId;

  const UploadDocument({required this.filePath, required this.documentId});

  @override
  List<Object?> get props => [filePath, documentId];
}

class ClearDocumentError extends DocumentEvent {
  const ClearDocumentError();
}
