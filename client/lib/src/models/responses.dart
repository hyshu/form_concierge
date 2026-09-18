part of form_concierge_client;

/// The file format used to export survey responses.
enum ResponseExportFormat {
  /// Exports responses as comma-separated values.
  csv,

  /// Exports responses as JSON.
  json,
}

/// The contents and download metadata of a response export.
class ResponseExportFile {
  /// The file contents as raw bytes.
  final List<int> bytes;

  /// The suggested name for the downloaded file.
  final String filename;

  /// The MIME type of the content.
  final String contentType;

  /// The encoding used for the exported response file.
  final ResponseExportFormat format;

  /// Creates ResponseExportFile with the supplied values.
  const ResponseExportFile({
    required this.bytes,
    required this.filename,
    required this.contentType,
    required this.format,
  });

  /// Decodes the downloaded bytes as UTF-8 text.
  String get text => utf8.decode(bytes);
}

/// The progress of an adaptive follow-up interview.
enum FollowUpStatus {
  /// No follow-up interview is required.
  skipped,

  /// The follow-up interview is waiting for answers.
  pending,

  /// The follow-up answers have been saved.
  completed,
}

/// A selectable option in a follow-up question.
class FollowUpChoice {
  /// The identifier of this follow up choice.
  final String id;

  /// A human-readable label.
  final String label;

  /// Creates FollowUpChoice with the supplied values.
  const FollowUpChoice({required this.id, required this.label});

  /// Decodes FollowUpChoice from its JSON representation.
  factory FollowUpChoice.fromJson(Map<String, dynamic> json) => FollowUpChoice(
    id: _string(json['id']),
    label: _string(json['label']),
  );

  /// Returns the JSON representation used by the API.
  Map<String, dynamic> toJson() => {'id': id, 'label': label};
}

/// An answer to an adaptive follow-up question.
class FollowUpAnswer {
  /// The submitted text for a text question, when present.
  final String? textValue;

  /// The identifiers of the selected answer choices.
  final List<String> selectedChoiceIds;

  /// Storage keys for the uploaded files attached to the answer.
  final List<String> fileKeys;

  /// Creates FollowUpAnswer with the supplied values.
  const FollowUpAnswer({
    this.textValue,
    this.selectedChoiceIds = const [],
    this.fileKeys = const [],
  });

  /// Decodes FollowUpAnswer from its JSON representation.
  factory FollowUpAnswer.fromJson(Map<String, dynamic> json) => FollowUpAnswer(
    textValue: _optionalString(json['textValue']),
    selectedChoiceIds: _stringList(json['selectedChoiceIds'] ?? const []),
    fileKeys: _stringList(json['fileKeys'] ?? const []),
  );

  /// Returns the JSON representation used by the API.
  Map<String, dynamic> toJson() => {
    'textValue': textValue,
    'selectedChoiceIds': selectedChoiceIds,
    'fileKeys': fileKeys,
  };
}

/// A follow-up question with its choices and any saved answer.
class FollowUpItem {
  /// The identifier of this follow up item.
  final String id;

  /// The input format used to collect the answer.
  final QuestionType type;

  /// The question text shown to the respondent.
  final String text;

  /// Whether the respondent must answer this question.
  final bool required;

  /// Hint text displayed when the text input is empty.
  final String? placeholder;

  /// The maximum number of files allowed for this question.
  final int? maxFiles;

  /// The choices available for this question.
  final List<FollowUpChoice> choices;

  /// The saved answer, if the follow-up question has been answered.
  final FollowUpAnswer? answer;

  /// Creates FollowUpItem with the supplied values.
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

  /// Decodes FollowUpItem from its JSON representation.
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

  /// Returns the JSON representation used by the API.
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

/// The storage key and metadata of an uploaded file.
class MediaUpload {
  /// The storage key used to retrieve the uploaded file.
  final String key;

  /// The MIME type of the content.
  final String contentType;

  /// The size of the uploaded file in bytes.
  final int size;

  /// Creates MediaUpload with the supplied values.
  const MediaUpload({
    required this.key,
    required this.contentType,
    required this.size,
  });

  /// Decodes MediaUpload from its JSON representation.
  factory MediaUpload.fromJson(Map<String, dynamic> json) => MediaUpload(
    key: _string(json['key']),
    contentType: _string(json['contentType']),
    size: _int(json['size']),
  );
}

/// An adaptive interview generated from a submitted survey response.
class FollowUp {
  /// The version associated with this record.
  final int version;

  /// The current progress of the follow-up interview.
  final FollowUpStatus status;

  /// When the follow-up interview was generated.
  final DateTime generatedAt;

  /// When the follow-up interview was completed, if applicable.
  final DateTime? completedAt;

  /// The locale used to display the form content.
  final String locale;

  /// The questions in the follow-up interview.
  final List<FollowUpItem> items;

  /// Creates FollowUp with the supplied values.
  const FollowUp({
    this.version = 1,
    required this.status,
    required this.generatedAt,
    this.completedAt,
    required this.locale,
    this.items = const [],
  });

  /// Decodes FollowUp from its JSON representation.
  factory FollowUp.fromJson(Map<String, dynamic> json) => FollowUp(
    version: _int(json['version'] ?? 1),
    status: _enum(FollowUpStatus.values, json['status']),
    generatedAt: _date(json['generatedAt']),
    completedAt: _optionalDate(json['completedAt']),
    locale: _string(json['locale']),
    items: _objectList(json['items'] ?? const [], FollowUpItem.fromJson),
  );

  /// Returns the JSON representation used by the API.
  Map<String, dynamic> toJson() => _withoutNulls({
    'version': version,
    'status': _enumName(status),
    'generatedAt': generatedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'locale': locale,
    'items': items.map((item) => item.toJson()).toList(),
  });
}

/// The outcome of requesting an adaptive follow-up interview.
class FollowUpGenerateResult {
  /// Whether the generated follow-up requires additional answers.
  final bool needed;

  /// The adaptive follow-up interview associated with the response.
  final FollowUp followUp;

  /// The error message, when the operation could not complete.
  final String? error;

  /// Creates FollowUpGenerateResult with the supplied values.
  const FollowUpGenerateResult({
    required this.needed,
    required this.followUp,
    this.error,
  });

  /// Decodes FollowUpGenerateResult from its JSON representation.
  factory FollowUpGenerateResult.fromJson(Map<String, dynamic> json) =>
      FollowUpGenerateResult(
        needed: _bool(json['needed']),
        followUp: _object(json['followUp'], FollowUp.fromJson),
        error: _optionalString(json['error']),
      );
}

/// A recorded survey submission and its associated metadata.
class SurveyResponse {
  /// The identifier of this survey response. Null until the record has been saved.
  final int? id;

  /// The identifier of the associated survey.
  final int surveyId;

  /// The user identifier associated with the response, when present.
  final String? userId;

  /// An optional respondent identifier supplied by the host application.
  final String? anonymousId;

  /// The anonymous account that owns the response or reply.
  final String? anonymousAccountId;

  /// When the survey response was submitted.
  final DateTime submittedAt;

  /// Optional device details attached to the submission.
  final DeviceInfo? deviceInfo;

  /// Application-provided metadata attached to the submission.
  final Map<String, dynamic>? metadata;

  /// The adaptive follow-up interview associated with the response.
  final FollowUp? followUp;

  /// The number of administrator replies attached to the response.
  final int replyCount;

  /// Creates SurveyResponse with the supplied values.
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
    this.replyCount = 0,
  });

  /// Decodes SurveyResponse from its JSON representation.
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
    replyCount: json['replyCount'] == null ? 0 : _int(json['replyCount']),
  );

  /// Returns the JSON representation used by the API.
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
    'replyCount': replyCount,
  });
}

/// One respondent's answer for a question, used under aggregated results.
class IndividualAnswer {
  /// The identifier of the associated survey response.
  final int responseId;

  /// When the survey response was submitted.
  final DateTime submittedAt;

  /// An optional respondent identifier supplied by the host application.
  final String? anonymousId;

  /// The locale recorded for the respondent's submission, when available.
  final String? responseLocale;

  /// The submitted text for a text question, when present.
  final String? textValue;

  /// The identifiers of the selected answer choices.
  final List<int>? selectedChoiceIds;

  /// Storage keys for the uploaded files attached to the answer.
  final List<String>? fileKeys;

  /// Creates IndividualAnswer with the supplied values.
  const IndividualAnswer({
    required this.responseId,
    required this.submittedAt,
    this.anonymousId,
    this.responseLocale,
    this.textValue,
    this.selectedChoiceIds,
    this.fileKeys,
  });

  /// Decodes IndividualAnswer from its JSON representation.
  factory IndividualAnswer.fromJson(Map<String, dynamic> json) =>
      IndividualAnswer(
        responseId: _int(json['responseId']),
        submittedAt: _date(json['submittedAt']),
        anonymousId: _optionalString(json['anonymousId']),
        responseLocale: _optionalString(json['responseLocale']),
        textValue: _optionalString(json['textValue']),
        selectedChoiceIds: _intList(json['selectedChoiceIds']),
        fileKeys: json['fileKeys'] == null
            ? null
            : _stringList(json['fileKeys']),
      );
}

/// Aggregated statistics and individual answers for one question.
class QuestionResult {
  /// The identifier of the associated question.
  final int questionId;

  /// The display text of the question being summarized.
  final String questionText;

  /// The input format of the question being summarized.
  final QuestionType questionType;

  /// Response counts indexed by choice identifier, when applicable.
  final Map<int, int>? choiceCounts;

  /// Submitted text answers, when applicable.
  final List<String>? textResponses;

  /// The number of responses containing uploaded images, when applicable.
  final int? imageResponseCount;

  /// Individual answers with their originating response metadata.
  final List<IndividualAnswer> individualAnswers;

  /// Creates QuestionResult with the supplied values.
  const QuestionResult({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    this.choiceCounts,
    this.textResponses,
    this.imageResponseCount,
    this.individualAnswers = const [],
  });

  /// Decodes QuestionResult from its JSON representation.
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

/// Response totals and per-question results for a survey.
class SurveyResults {
  /// The identifier of the associated survey.
  final int surveyId;

  /// The total number of responses included in the results.
  final int totalResponses;

  /// Aggregated results for each question.
  final List<QuestionResult> questionResults;

  /// Creates SurveyResults with the supplied values.
  const SurveyResults({
    required this.surveyId,
    required this.totalResponses,
    required this.questionResults,
  });

  /// Decodes SurveyResults from its JSON representation.
  factory SurveyResults.fromJson(Map<String, dynamic> json) => SurveyResults(
    surveyId: _int(json['surveyId']),
    totalResponses: _int(json['totalResponses']),
    questionResults: _objectList(
      json['questionResults'],
      QuestionResult.fromJson,
    ),
  );
}

/// Email notification preferences for new survey responses.
class NotificationSettings {
  /// The identifier of this notification settings. Null until the record has been saved.
  final int? id;

  /// The identifier of the associated survey.
  final int surveyId;

  /// Whether new responses trigger email notifications.
  final bool enabled;

  /// The address that receives survey response notifications.
  final String recipientEmail;

  /// When this record was last updated.
  final DateTime updatedAt;

  /// Creates NotificationSettings with the supplied values.
  const NotificationSettings({
    this.id,
    required this.surveyId,
    this.enabled = false,
    required this.recipientEmail,
    required this.updatedAt,
  });

  /// Decodes NotificationSettings from its JSON representation.
  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        id: json['id'] == null ? null : _int(json['id']),
        surveyId: _int(json['surveyId']),
        enabled: _bool(json['enabled']),
        recipientEmail: _string(json['recipientEmail']),
        updatedAt: _date(json['updatedAt']),
      );

  /// Returns the JSON representation used by the API.
  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'surveyId': surveyId,
    'enabled': enabled,
    'recipientEmail': recipientEmail,
    'updatedAt': updatedAt.toIso8601String(),
  });
}
