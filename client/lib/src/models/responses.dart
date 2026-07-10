part of form_concierge_client;

enum ResponseExportFormat { csv, json }

class ResponseExportFile {
  final List<int> bytes;
  final String filename;
  final String contentType;
  final ResponseExportFormat format;

  const ResponseExportFile({
    required this.bytes,
    required this.filename,
    required this.contentType,
    required this.format,
  });

  String get text => utf8.decode(bytes);
}

enum FollowUpStatus { skipped, pending, completed }

class FollowUpChoice {
  final String id;
  final String label;

  const FollowUpChoice({required this.id, required this.label});

  factory FollowUpChoice.fromJson(Map<String, dynamic> json) => FollowUpChoice(
    id: _string(json['id']),
    label: _string(json['label']),
  );

  Map<String, dynamic> toJson() => {'id': id, 'label': label};
}

class FollowUpAnswer {
  final String? textValue;
  final List<String> selectedChoiceIds;
  final List<String> fileKeys;

  const FollowUpAnswer({
    this.textValue,
    this.selectedChoiceIds = const [],
    this.fileKeys = const [],
  });

  factory FollowUpAnswer.fromJson(Map<String, dynamic> json) => FollowUpAnswer(
    textValue: _optionalString(json['textValue']),
    selectedChoiceIds: _stringList(json['selectedChoiceIds'] ?? const []),
    fileKeys: _stringList(json['fileKeys'] ?? const []),
  );

  Map<String, dynamic> toJson() => {
    'textValue': textValue,
    'selectedChoiceIds': selectedChoiceIds,
    'fileKeys': fileKeys,
  };
}

class FollowUpItem {
  final String id;
  final QuestionType type;
  final String text;
  final bool required;
  final String? placeholder;
  final int? maxFiles;
  final List<FollowUpChoice> choices;
  final FollowUpAnswer? answer;

  const FollowUpItem({
    required this.id,
    required this.type,
    required this.text,
    required this.required,
    this.placeholder,
    this.maxFiles,
    this.choices = const [],
    this.answer,
  });

  factory FollowUpItem.fromJson(Map<String, dynamic> json) => FollowUpItem(
    id: _string(json['id']),
    type: _enum(QuestionType.values, json['type']),
    text: _string(json['text']),
    required: _bool(json['required']),
    placeholder: _optionalString(json['placeholder']),
    maxFiles: json['maxFiles'] == null ? null : _int(json['maxFiles']),
    choices: _objectList(json['choices'] ?? const [], FollowUpChoice.fromJson),
    answer: _optionalObject(json['answer'], FollowUpAnswer.fromJson),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'type': _enumName(type),
    'text': text,
    'required': required,
    'placeholder': placeholder,
    'maxFiles': maxFiles,
    'choices': choices.map((choice) => choice.toJson()).toList(),
    'answer': answer?.toJson(),
  });
}

class MediaUpload {
  final String key;
  final String contentType;
  final int size;

  const MediaUpload({
    required this.key,
    required this.contentType,
    required this.size,
  });

  factory MediaUpload.fromJson(Map<String, dynamic> json) => MediaUpload(
    key: _string(json['key']),
    contentType: _string(json['contentType']),
    size: _int(json['size']),
  );
}

class FollowUp {
  final int version;
  final FollowUpStatus status;
  final DateTime generatedAt;
  final DateTime? completedAt;
  final String locale;
  final List<FollowUpItem> items;

  const FollowUp({
    this.version = 1,
    required this.status,
    required this.generatedAt,
    this.completedAt,
    required this.locale,
    this.items = const [],
  });

  factory FollowUp.fromJson(Map<String, dynamic> json) => FollowUp(
    version: _int(json['version'] ?? 1),
    status: _enum(FollowUpStatus.values, json['status']),
    generatedAt: _date(json['generatedAt']),
    completedAt: _optionalDate(json['completedAt']),
    locale: _string(json['locale']),
    items: _objectList(json['items'] ?? const [], FollowUpItem.fromJson),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'version': version,
    'status': _enumName(status),
    'generatedAt': generatedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'locale': locale,
    'items': items.map((item) => item.toJson()).toList(),
  });
}

class FollowUpGenerateResult {
  final bool needed;
  final FollowUp followUp;
  final String? error;

  const FollowUpGenerateResult({
    required this.needed,
    required this.followUp,
    this.error,
  });

  factory FollowUpGenerateResult.fromJson(Map<String, dynamic> json) =>
      FollowUpGenerateResult(
        needed: _bool(json['needed']),
        followUp: _object(json['followUp'], FollowUp.fromJson),
        error: _optionalString(json['error']),
      );
}

class SurveyResponse {
  final int? id;
  final int surveyId;
  final String? userId;
  final String? anonymousId;
  final String? anonymousAccountId;
  final DateTime submittedAt;
  final DeviceInfo? deviceInfo;
  final Map<String, dynamic>? metadata;
  final FollowUp? followUp;

  const SurveyResponse({
    this.id,
    required this.surveyId,
    this.userId,
    this.anonymousId,
    this.anonymousAccountId,
    required this.submittedAt,
    this.deviceInfo,
    this.metadata,
    this.followUp,
  });

  factory SurveyResponse.fromJson(Map<String, dynamic> json) => SurveyResponse(
    id: json['id'] == null ? null : _int(json['id']),
    surveyId: _int(json['surveyId']),
    userId: _optionalString(json['userId']),
    anonymousId: _optionalString(json['anonymousId']),
    anonymousAccountId: _optionalString(json['anonymousAccountId']),
    submittedAt: _date(json['submittedAt']),
    deviceInfo: _optionalObject(json['deviceInfo'], DeviceInfo.fromJson),
    metadata: _map(json['metadata']),
    followUp: _optionalObject(json['followUp'], FollowUp.fromJson),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'surveyId': surveyId,
    'userId': userId,
    'anonymousId': anonymousId,
    'anonymousAccountId': anonymousAccountId,
    'submittedAt': submittedAt.toIso8601String(),
    'deviceInfo': deviceInfo?.toJson(),
    'metadata': metadata,
    'followUp': followUp?.toJson(),
  });
}

/// One respondent's answer for a question, used under aggregated results.
class IndividualAnswer {
  final int responseId;
  final DateTime submittedAt;
  final String? anonymousId;
  final String? textValue;
  final List<int>? selectedChoiceIds;
  final List<String>? fileKeys;

  const IndividualAnswer({
    required this.responseId,
    required this.submittedAt,
    this.anonymousId,
    this.textValue,
    this.selectedChoiceIds,
    this.fileKeys,
  });

  factory IndividualAnswer.fromJson(Map<String, dynamic> json) =>
      IndividualAnswer(
        responseId: _int(json['responseId']),
        submittedAt: _date(json['submittedAt']),
        anonymousId: _optionalString(json['anonymousId']),
        textValue: _optionalString(json['textValue']),
        selectedChoiceIds: _intList(json['selectedChoiceIds']),
        fileKeys: json['fileKeys'] == null
            ? null
            : _stringList(json['fileKeys']),
      );
}

class QuestionResult {
  final int questionId;
  final String questionText;
  final QuestionType questionType;
  final Map<int, int>? choiceCounts;
  final List<String>? textResponses;
  final int? imageResponseCount;
  final List<IndividualAnswer> individualAnswers;

  const QuestionResult({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    this.choiceCounts,
    this.textResponses,
    this.imageResponseCount,
    this.individualAnswers = const [],
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) => QuestionResult(
    questionId: _int(json['questionId']),
    questionText: _string(json['questionText']),
    questionType: _enum(QuestionType.values, json['questionType']),
    choiceCounts: (json['choiceCounts'] as Map?)?.map(
      (key, value) => MapEntry(_intStringKey(key), _int(value)),
    ),
    textResponses: json['textResponses'] == null
        ? null
        : _stringList(json['textResponses']),
    imageResponseCount: json['imageResponseCount'] == null
        ? null
        : _int(json['imageResponseCount']),
    individualAnswers: json['individualAnswers'] == null
        ? const []
        : _objectList(json['individualAnswers'], IndividualAnswer.fromJson),
  );
}

class SurveyResults {
  final int surveyId;
  final int totalResponses;
  final List<QuestionResult> questionResults;

  const SurveyResults({
    required this.surveyId,
    required this.totalResponses,
    required this.questionResults,
  });

  factory SurveyResults.fromJson(Map<String, dynamic> json) => SurveyResults(
    surveyId: _int(json['surveyId']),
    totalResponses: _int(json['totalResponses']),
    questionResults: _objectList(
      json['questionResults'],
      QuestionResult.fromJson,
    ),
  );
}

class NotificationSettings {
  final int? id;
  final int surveyId;
  final bool enabled;
  final String recipientEmail;
  final DateTime updatedAt;

  const NotificationSettings({
    this.id,
    required this.surveyId,
    this.enabled = false,
    required this.recipientEmail,
    required this.updatedAt,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        id: json['id'] == null ? null : _int(json['id']),
        surveyId: _int(json['surveyId']),
        enabled: _bool(json['enabled']),
        recipientEmail: _string(json['recipientEmail']),
        updatedAt: _date(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'surveyId': surveyId,
    'enabled': enabled,
    'recipientEmail': recipientEmail,
    'updatedAt': updatedAt.toIso8601String(),
  });
}
