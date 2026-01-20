import 'dart:convert';

/// Model for RFQ Detail Question
class RfqDetailQuestion {
  final int questionId;
  final String answerId;
  final String question;
  final String? answer;
  final DateTime dateAdded;
  final String questionType;
  final String groupTitle;
  final int groupSequence;

  RfqDetailQuestion({
    required this.questionId,
    required this.answerId,
    required this.question,
    this.answer,
    required this.dateAdded,
    required this.questionType,
    required this.groupTitle,
    required this.groupSequence,
  });

  factory RfqDetailQuestion.fromJson(Map<String, dynamic> json) {
    return RfqDetailQuestion(
      questionId: json['question_id'] as int? ?? 0,
      answerId: (json['answer_id'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      answer: json['answer']?.toString(),
      dateAdded: DateTime.tryParse(json['dateAdded'] ?? '') ?? DateTime.now(),
      questionType: (json['question_type'] ?? 'textfield').toString(),
      groupTitle: (json['group_title'] ?? '').toString(),
      groupSequence: json['group_sequence'] as int? ?? 0,
    );
  }

  /// Parse answer ID to get display text
  /// For checkbox, answer_id is a JSON array string
  /// For other types, it's a simple string or ID
  String? getParsedAnswer(List<RfqDetailAnswer> allAnswers) {
    if (answerId.isEmpty) return null;

    if (questionType == 'checkbox') {
      try {
        // Parse JSON array string
        final List<dynamic> answerIds = jsonDecode(answerId);
        if (answerIds.isEmpty) return null;

        // Find matching answers from all_answers
        final answerTexts = answerIds.map((id) {
          if (id is String) {
            // Try to find by option text (exact match)
            try {
              final found = allAnswers.firstWhere(
                (ans) => ans.questionOptions == id && ans.questionId == questionId,
                orElse: () => RfqDetailAnswer(
                  id: 0,
                  questionId: questionId,
                  questionOptions: id, // Return the text as is if not found
                ),
              );
              return found.questionOptions;
            } catch (e) {
              // If not found, return the text as is
              return id;
            }
          } else if (id is int) {
            // Find by ID
            try {
              final found = allAnswers.firstWhere(
                (ans) => ans.id == id && ans.questionId == questionId,
                orElse: () => RfqDetailAnswer(
                  id: id,
                  questionId: questionId,
                  questionOptions: '',
                ),
              );
              return found.questionOptions.isNotEmpty ? found.questionOptions : id.toString();
            } catch (e) {
              return id.toString();
            }
          }
          return id.toString();
        }).where((text) => text.isNotEmpty).toList();

        return answerTexts.isEmpty ? null : answerTexts.join(', ');
      } catch (e) {
        // If parsing fails, return as is
        return answerId;
      }
    } else if (questionType == 'dropdown' || questionType == 'radio') {
      // Find answer by ID or by option text
      try {
        final answerIdInt = int.tryParse(answerId);
        if (answerIdInt != null) {
          final found = allAnswers.firstWhere(
            (ans) => ans.id == answerIdInt && ans.questionId == questionId,
            orElse: () => RfqDetailAnswer(
              id: answerIdInt,
              questionId: questionId,
              questionOptions: answerId,
            ),
          );
          return found.questionOptions.isNotEmpty ? found.questionOptions : answerId;
        }
        // If not a number, try to find by option text
        final found = allAnswers.firstWhere(
          (ans) => ans.questionOptions == answerId && ans.questionId == questionId,
          orElse: () => RfqDetailAnswer(
            id: 0,
            questionId: questionId,
            questionOptions: answerId,
          ),
        );
        return found.questionOptions.isNotEmpty ? found.questionOptions : answerId;
      } catch (e) {
        return answerId;
      }
    } else {
      // For textfield, textarea, etc., return answer_id as is
      return answerId.isEmpty ? null : answerId;
    }
  }
}

/// Model for RFQ Detail Answer Option
class RfqDetailAnswer {
  final int id;
  final int questionId;
  final String questionOptions;

  RfqDetailAnswer({
    required this.id,
    required this.questionId,
    required this.questionOptions,
  });

  factory RfqDetailAnswer.fromJson(Map<String, dynamic> json) {
    return RfqDetailAnswer(
      id: json['id'] as int? ?? 0,
      questionId: json['question_id'] as int? ?? 0,
      questionOptions: (json['question_options'] ?? '').toString(),
    );
  }
}

/// Model for RFQ Detail
class RfqDetail {
  final String rfqAccountNo;
  final String clientAccountNo;
  final DateTime dateCreated;
  final DateTime? dateUpdated;
  final String rfqStatus;
  final String? rfqAttachment;
  final String? rfqComments;
  final List<dynamic> rfqServices;
  final List<RfqDetailQuestion> rfqQuestions;
  final List<RfqDetailAnswer> allAnswers;

  RfqDetail({
    required this.rfqAccountNo,
    required this.clientAccountNo,
    required this.dateCreated,
    this.dateUpdated,
    required this.rfqStatus,
    this.rfqAttachment,
    this.rfqComments,
    required this.rfqServices,
    required this.rfqQuestions,
    required this.allAnswers,
  });

  factory RfqDetail.fromJson(Map<String, dynamic> json) {
    final questionsList = (json['rfq_questions'] as List?)
            ?.map((e) => RfqDetailQuestion.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final answersList = (json['all_answers'] as List?)
            ?.map((e) => RfqDetailAnswer.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return RfqDetail(
      rfqAccountNo: (json['rfq_accountno'] ?? '').toString(),
      clientAccountNo: (json['client_accountno'] ?? '').toString(),
      dateCreated: DateTime.tryParse(json['dateCreated'] ?? '') ?? DateTime.now(),
      dateUpdated: json['dateUpdated'] != null
          ? DateTime.tryParse(json['dateUpdated'])
          : null,
      rfqStatus: (json['rfq_status'] ?? 'pending').toString(),
      rfqAttachment: json['rfq_attachement']?.toString(),
      rfqComments: json['rfq_comments']?.toString(),
      rfqServices: json['rfq_services'] as List? ?? [],
      rfqQuestions: questionsList,
      allAnswers: answersList,
    );
  }

  /// Get questions grouped by group_title and sorted by group_sequence
  Map<String, List<RfqDetailQuestion>> get groupedQuestions {
    final Map<String, List<RfqDetailQuestion>> grouped = {};
    
    for (final question in rfqQuestions) {
      if (!grouped.containsKey(question.groupTitle)) {
        grouped[question.groupTitle] = [];
      }
      grouped[question.groupTitle]!.add(question);
    }

    // Sort groups by sequence (get min sequence for each group)
    final sortedGroups = grouped.entries.toList()
      ..sort((a, b) {
        final aMinSeq = a.value.map((q) => q.groupSequence).reduce((a, b) => a < b ? a : b);
        final bMinSeq = b.value.map((q) => q.groupSequence).reduce((a, b) => a < b ? a : b);
        return aMinSeq.compareTo(bMinSeq);
      });

    return Map.fromEntries(sortedGroups);
  }
}

