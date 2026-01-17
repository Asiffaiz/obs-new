/// RFQ Question model representing individual questions
class RfqQuestion {
  final int id;
  final String questionTitle;
  final String questionType;
  final DateTime dateAdded;
  final List<RfqQuestionOption> options;
  final String domainName;
  final bool isMandatory;
  final int groupId;

  RfqQuestion({
    required this.id,
    required this.questionTitle,
    required this.questionType,
    required this.dateAdded,
    required this.options,
    required this.domainName,
    required this.isMandatory,
    required this.groupId,
  });

  factory RfqQuestion.fromJson(Map<String, dynamic> json) {
    return RfqQuestion(
      id: json['id'] as int,
      questionTitle: (json['question_title'] ?? '').toString(),
      questionType: (json['question_type'] ?? 'textfield').toString(),
      dateAdded: DateTime.tryParse(json['dateAdded'] ?? '') ?? DateTime.now(),
      options: (json['question_options'] as List?)
              ?.map((e) => RfqQuestionOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      domainName: (json['domain_name'] ?? '').toString(),
      isMandatory: json['isMandatory'] == 1,
      groupId: json['group_id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question_title': questionTitle,
        'question_type': questionType,
        'dateAdded': dateAdded.toIso8601String(),
        'question_options': options.map((e) => e.toJson()).toList(),
        'domain_name': domainName,
        'isMandatory': isMandatory ? 1 : 0,
        'group_id': groupId,
      };
}

/// RFQ Question Option model
class RfqQuestionOption {
  final int id;
  final int questionId;
  final String optionText;

  RfqQuestionOption({
    required this.id,
    required this.questionId,
    required this.optionText,
  });

  factory RfqQuestionOption.fromJson(Map<String, dynamic> json) {
    return RfqQuestionOption(
      id: json['id'] as int? ?? 0,
      questionId: json['question_id'] as int? ?? 0,
      optionText: (json['question_options'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question_id': questionId,
        'question_options': optionText,
      };
}

/// RFQ Question Group model representing steps in the form
class RfqQuestionGroup {
  final int id;
  final String groupTitle;
  final String groupDesc;
  final int groupId;
  final int groupSequence;

  RfqQuestionGroup({
    required this.id,
    required this.groupTitle,
    required this.groupDesc,
    required this.groupId,
    required this.groupSequence,
  });

  factory RfqQuestionGroup.fromJson(Map<String, dynamic> json) {
    return RfqQuestionGroup(
      id: json['id'] as int? ?? 0,
      groupTitle: (json['group_title'] ?? '').toString(),
      groupDesc: (json['group_desc'] ?? '').toString(),
      groupId: json['group_id'] as int? ?? 0,
      groupSequence: json['group_sequence'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_title': groupTitle,
        'group_desc': groupDesc,
        'group_id': groupId,
        'group_sequence': groupSequence,
      };
}

/// RFQ Settings model
class RfqSettings {
  final int id;
  final String accountNo;
  final String email;
  final String sendToAgent;
  final String title;
  final String heading;
  final String shortDesc;

  RfqSettings({
    required this.id,
    required this.accountNo,
    required this.email,
    required this.sendToAgent,
    required this.title,
    required this.heading,
    required this.shortDesc,
  });

  factory RfqSettings.fromJson(Map<String, dynamic> json) {
    return RfqSettings(
      id: json['id'] as int? ?? 0,
      accountNo: (json['accountno'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      sendToAgent: (json['send_to_agent'] ?? 'No').toString(),
      title: (json['title'] ?? '').toString(),
      heading: (json['heading'] ?? '').toString(),
      shortDesc: (json['short_desc'] ?? '').toString(),
    );
  }
}

/// Main RFQ Form Definition model
class RfqFormDefinition {
  final List<RfqQuestion> questions;
  final List<RfqQuestionGroup> groups;
  final RfqSettings? settings;

  RfqFormDefinition({
    required this.questions,
    required this.groups,
    this.settings,
  });

  factory RfqFormDefinition.fromApiResponse(Map<String, dynamic> json) {
    final questionsList = (json['rfqQuestionsListing'] as List?)
            ?.map((e) => RfqQuestion.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final groupsList = (json['rfqQuestionGroupsListing'] as List?)
            ?.map((e) => RfqQuestionGroup.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final settingsList = json['rfq_settings'] as List?;
    RfqSettings? settings;
    if (settingsList != null && settingsList.isNotEmpty) {
      settings = RfqSettings.fromJson(settingsList.first as Map<String, dynamic>);
    }

    return RfqFormDefinition(
      questions: questionsList,
      groups: groupsList,
      settings: settings,
    );
  }

  /// Get ordered groups sorted by sequence
  List<RfqQuestionGroup> get orderedGroups {
    final sorted = [...groups];
    sorted.sort((a, b) => a.groupSequence.compareTo(b.groupSequence));
    return sorted;
  }

  /// Get questions for a specific group
  List<RfqQuestion> getQuestionsForGroup(int groupId) {
    return questions.where((q) => q.groupId == groupId).toList();
  }
}

