import 'dart:math';
import 'package:voicealerts_obs/core/constants/network_urls.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_model.dart';
import 'package:voicealerts_obs/features/rfq/domain/models/rfq_product_model.dart';

/// Utility class to build RFQ submit payload according to API requirements
class RfqPayloadBuilder {
  /// Generate random RFQ account number (7 digits)
  static String generateRfqAccountNo() {
    // Generate a random 7-digit number (1000000 to 9999999)
    final random = Random();
    final accountNo = random.nextInt(9000000) + 1000000; // 7 digits
    return accountNo.toString();
  }

  /// Extract file name from base64 encoded file
  /// If the attachment is base64, we need to store the original file name separately
  /// For now, we'll use a generic name or extract from the state if available
  static String? extractFileName(String? attachmentFile) {
    if (attachmentFile == null || attachmentFile.isEmpty) {
      return null;
    }
    // If it's base64, we might need to store the filename separately
    // For now, return null and let the service handle it
    return null;
  }

  /// Build rfq_questions_rows from answers and form definition
  static List<Map<String, dynamic>> buildRfqQuestionsRows({
    required Map<String, dynamic> answers,
    required RfqFormDefinition formDefinition,
  }) {
    final questionsRows = <Map<String, dynamic>>[];

    for (final question in formDefinition.questions) {
      final questionId = question.id;
      final answerKey = questionId.toString();
      final answer = answers[answerKey];

      // Determine if question is answered
      final bool questionAnswered =
          answer != null &&
          answer.toString().isNotEmpty &&
          !(answer is List && answer.isEmpty);

      // Build the question row
      final questionRow = <String, dynamic>{
        'question_answered': questionAnswered,
        'question_id': questionId,
        'question_title': question.questionTitle,
        'question_type': question.questionType,
        'all_answers':
            question.options
                .map(
                  (opt) => {
                    'id': opt.id,
                    'question_id': questionId,
                    'question_options': opt.optionText,
                  },
                )
                .toList(),
        'field_name': 'selected_answer_$questionId',
        'isMandatory': question.isMandatory ? 1 : 0,
        'group_id': question.groupId,
      };

      // Add selected answer based on question type
      if (question.questionType == 'checkbox') {
        // For checkbox, answer should be a list of option IDs
        if (answer is List) {
          questionRow['selected_answer_$questionId'] = answer;
          questionRow['selected_key'] = answer.length;
        } else if (answer != null) {
          // If it's a single value, convert to list
          questionRow['selected_answer_$questionId'] = [answer];
          questionRow['selected_key'] = 1;
        } else {
          questionRow['selected_answer_$questionId'] = [];
        }
      } else if (question.questionType == 'dropdown') {
        // For dropdown, answer is the selected option ID (as string or int)
        questionRow['selected_answer_$questionId'] = answer?.toString() ?? '';
      } else if (question.questionType == 'fileinput') {
        // For file input, answer is the file path or base64
        questionRow['selected_answer_$questionId'] = answer?.toString() ?? '';
      } else {
        // For textfield, textarea, label, simple_text, etc.
        questionRow['selected_answer_$questionId'] = answer?.toString() ?? '';
      }

      questionsRows.add(questionRow);
    }

    return questionsRows;
  }

  /// Build services_rows from selected products
  static List<Map<String, dynamic>> buildServicesRows({
    required List<int> selectedProductIds,
    required List<RfqProduct> allProducts,
  }) {
    final servicesRows = <Map<String, dynamic>>[];

    for (final productId in selectedProductIds) {
      final product = allProducts.firstWhere(
        (p) => p.id == productId,
        orElse:
            () => RfqProduct(id: productId, serviceTitle: 'Unknown Product'),
      );

      servicesRows.add({
        'service_checked': false,
        'service_id': product.id,
        'service_title': product.serviceTitle,
        'service_price': 0, // Default to 0, API might update this
        'service_quantity': 1,
        'service_unit': '',
        'service_sub_total': 0, // Default to 0, API might update this
        'service_sku': product.sku ?? '',
      });
    }

    return servicesRows;
  }

  /// Build complete submit payload
  static Map<String, dynamic> buildSubmitPayload({
    required String accountNo,
    required Map<String, dynamic> answers,
    required RfqFormDefinition formDefinition,
    required List<int> selectedProductIds,
    required List<RfqProduct> allProducts,
    String? requirementDescription,
    String? attachmentFile,
    String? fileName,
  }) {
    // Generate random RFQ account number
    final rfqAccountNo = generateRfqAccountNo();

    // Build questions rows
    final rfqQuestionsRows = buildRfqQuestionsRows(
      answers: answers,
      formDefinition: formDefinition,
    );

    // Build services rows
    final servicesRows = buildServicesRows(
      selectedProductIds: selectedProductIds,
      allProducts: allProducts,
    );

    // Build the payload
    final payload = <String, dynamic>{
      'token': NetworkUrls.reactAppApiToken,
      'api_accountno': NetworkUrls.reactAppApiACCOUNTNO,
      'accountno': accountNo,
      'file': attachmentFile, // base64 encoded file or null
      'fileName': fileName, // Original file name or null
      'rfq_comments': requirementDescription ?? '',
      'rfq_accountno': rfqAccountNo,
      'rfq_questions_rows': rfqQuestionsRows,
      'services_rows': servicesRows,
    };

    return payload;
  }
}
