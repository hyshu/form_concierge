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

class SurveyResponse {
  final int? id;
  final int surveyId;
  final String? userId;
  final String? anonymousId;
  final String? anonymousAccountId;
  final DateTime submittedAt;
  final DeviceInfo? deviceInfo;
  final Map<String, dynamic>? metadata;

  const SurveyResponse({
    this.id,
    required this.surveyId,
    this.userId,
    this.anonymousId,
    this.anonymousAccountId,
    required this.submittedAt,
    this.deviceInfo,
    this.metadata,
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
  });
}

class QuestionResult {
  final int questionId;
  final String questionText;
  final QuestionType questionType;
  final Map<int, int>? choiceCounts;
  final List<String>? textResponses;

  const QuestionResult({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    this.choiceCounts,
    this.textResponses,
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
