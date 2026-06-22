part of form_concierge_client;

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
    userId: json['userId'] as String?,
    anonymousId: json['anonymousId'] as String?,
    anonymousAccountId: json['anonymousAccountId'] as String?,
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
    questionText: json['questionText'] as String,
    questionType: _enum(
      QuestionType.values,
      json['questionType'],
      QuestionType.textSingle,
    ),
    choiceCounts: (json['choiceCounts'] as Map?)?.map(
      (key, value) => MapEntry(_int(key), _int(value)),
    ),
    textResponses: (json['textResponses'] as List?)
        ?.map((value) => value.toString())
        .toList(),
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
    questionResults: (json['questionResults'] as List? ?? const [])
        .map((value) => _object(value, QuestionResult.fromJson))
        .toList(),
  );
}

class NotificationSettings {
  final int? id;
  final int surveyId;
  final bool enabled;
  final String recipientEmail;
  final int sendHour;
  final DateTime updatedAt;
  final DateTime? lastSentAt;

  const NotificationSettings({
    this.id,
    required this.surveyId,
    this.enabled = false,
    required this.recipientEmail,
    this.sendHour = 9,
    required this.updatedAt,
    this.lastSentAt,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        id: json['id'] == null ? null : _int(json['id']),
        surveyId: _int(json['surveyId']),
        enabled: _bool(json['enabled']),
        recipientEmail: json['recipientEmail'] as String,
        sendHour: _int(json['sendHour']),
        updatedAt: _date(json['updatedAt']),
        lastSentAt: _optionalDate(json['lastSentAt']),
      );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'surveyId': surveyId,
    'enabled': enabled,
    'recipientEmail': recipientEmail,
    'sendHour': sendHour,
    'updatedAt': updatedAt.toIso8601String(),
    'lastSentAt': lastSentAt?.toIso8601String(),
  });
}
