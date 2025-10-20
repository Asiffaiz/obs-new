import 'dart:convert';

class FormQuestion {
  final String id;
  final String questionText;
  final String answerType; // input, dropdown, textarea, ...
  final bool required;
  final List<String> options; // for dropdown/radio
  final String imageUrl;
  final String dynamicValue; // reserved for future dynamic sources
  final int sequenceNumber; // used for ordering within group
  final String? inputFormat; // number_only, alphanumeric
  final String? maxLength; // as string in payload
  final String? validationValue; // validation_email, validation_phone, ...
  final String? answer;

  FormQuestion({
    required this.id,
    required this.questionText,
    required this.answerType,
    required this.required,
    required this.options,
    required this.imageUrl,
    required this.dynamicValue,
    required this.sequenceNumber,
    this.inputFormat,
    this.maxLength,
    this.validationValue,
    this.answer,
  });

  factory FormQuestion.fromJson(Map<String, dynamic> j) => FormQuestion(
    id: j['id'] as String,
    questionText: (j['questionText'] ?? '').toString(),
    answerType: (j['answerType'] ?? '').toString().toLowerCase(),
    required: (j['required'] ?? false) == true,
    options:
        (j['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    imageUrl: (j['imageUrl'] ?? '').toString(),
    dynamicValue: (j['dynamicValue'] ?? '').toString(),
    sequenceNumber: int.tryParse((j['sequenceNumber'] ?? '0').toString()) ?? 0,
    inputFormat: j['inputFormat']?.toString(),
    maxLength: j['maxLength']?.toString(),
    validationValue: j['validationValue']?.toString(),
    answer: j['answer']?.toString(),
  );
}

class FormGroup {
  final String id;
  final String title;
  final String desc;
  final int sequenceNumber; // used for ordering steps
  final List<String> questionIds; // ids to pull from questions map

  FormGroup({
    required this.id,
    required this.title,
    required this.desc,
    required this.sequenceNumber,
    required this.questionIds,
  });

  factory FormGroup.fromJson(Map<String, dynamic> j) => FormGroup(
    id: j['id'] as String,
    title: (j['group_title'] ?? '').toString(),
    desc: (j['group_desc'] ?? '').toString(),
    sequenceNumber: int.tryParse((j['sequenceNumber'] ?? '0').toString()) ?? 0,
    questionIds: (j['questions'] as List).map((e) => e.toString()).toList(),
  );
}

class FormDefinition {
  final String title;
  final String? description;
  final List<FormQuestion> questions; // master list
  final List<FormGroup> groups; // steps
  final List<FormQuestion>? draftResponse;
  final String? formMediaPath;
  final String? submitText;
  final String? progress;

  FormDefinition({
    required this.title,
    this.description,
    required this.questions,
    required this.groups,
    this.submitText,
    this.draftResponse,
    this.formMediaPath,
    this.progress,
  });

  /// Parse API payload (top-level JSON).
  factory FormDefinition.fromApi(Map<String, dynamic> j) {
    // Collect questions from all form_content blocks.
    final List<FormQuestion> qList = [];
    final List<FormQuestion> draftqList = [];
    var content = const <dynamic>[];
    var draftContent = const <dynamic>[];

    // Handle form_content based on its type
    if (j['form_content'] is String) {
      String formContentStr = j['form_content'] as String;
      try {
        // Direct JSON parse without removing brackets
        content = jsonDecode(formContentStr) as List;
      } catch (e) {
        // If direct parsing fails, try with bracket removal as fallback
        try {
          if (formContentStr.startsWith('[') && formContentStr.endsWith(']')) {
            formContentStr = formContentStr.substring(
              1,
              formContentStr.length - 1,
            );
          }
          content = jsonDecode(formContentStr) as List;
        } catch (e) {
          content = const [];
        }
      }
    } else if (j['form_content'] is List) {
      content = j['form_content'] as List;
    }

    for (final block in content) {
      final qs = (block['questions'] as List?) ?? const [];
      qList.addAll(
        qs.map((e) => FormQuestion.fromJson(e as Map<String, dynamic>)),
      );
    }

    // Handle draft response based on its type
    if (j['draft_response'] is String) {
      String draftResponseStr = j['draft_response'] as String;
      try {
        // Direct JSON parse without removing brackets
        draftContent = jsonDecode(draftResponseStr) as List;
      } catch (e) {
        // If direct parsing fails, try with bracket removal as fallback
        try {
          if (draftResponseStr.startsWith('[') &&
              draftResponseStr.endsWith(']')) {
            draftResponseStr = draftResponseStr.substring(
              1,
              draftResponseStr.length - 1,
            );
          }
          draftContent = jsonDecode(draftResponseStr) as List;
        } catch (e) {
          draftContent = const [];
        }
      }
    } else if (j['draft_response'] is List) {
      draftContent = j['draft_response'] as List;
    }

    for (final block in draftContent) {
      final qs = (block['questions'] as List?) ?? const [];
      draftqList.addAll(
        qs.map((e) => FormQuestion.fromJson(e as Map<String, dynamic>)),
      );
    }

    // Handle groups based on its type
    var groupsData = const <dynamic>[];
    if (j['groups'] is String) {
      String groupsStr = j['groups'] as String;
      try {
        // Direct JSON parse without removing brackets
        groupsData = jsonDecode(groupsStr) as List;
      } catch (e) {
        // If direct parsing fails, try with bracket removal as fallback
        try {
          if (groupsStr.startsWith('[') && groupsStr.endsWith(']')) {
            groupsStr = groupsStr.substring(1, groupsStr.length - 1);
          }
          groupsData = jsonDecode(groupsStr) as List;
        } catch (e) {
          groupsData = const [];
        }
      }
    } else if (j['groups'] is List) {
      groupsData = j['groups'] as List;
    }

    final groups =
        groupsData
            .map((e) => FormGroup.fromJson(e as Map<String, dynamic>))
            .toList();

    ////////////

    /////////
    final mediaPath = j['form_media_path']?.toString();
    final progress = j['progress']?.toString();
    return FormDefinition(
      title: (j['form_title'] ?? '').toString(),
      description: j['form_desc']?.toString(),
      questions: qList,
      groups: groups,
      draftResponse: draftqList,
      submitText: j['btn_text']?.toString(),
      formMediaPath: mediaPath,
      progress: progress,
    );
  }
}
