part of form_concierge_client;

class PublicConfig {
  final bool passwordResetEnabled;
  final bool requireEmailVerification;
  final bool geminiEnabled;

  const PublicConfig({
    required this.passwordResetEnabled,
    required this.requireEmailVerification,
    required this.geminiEnabled,
  });

  factory PublicConfig.fromJson(Map<String, dynamic> json) => PublicConfig(
    passwordResetEnabled: _bool(json['passwordResetEnabled']),
    requireEmailVerification: _bool(json['requireEmailVerification']),
    geminiEnabled: _bool(json['geminiEnabled']),
  );

  Map<String, dynamic> toJson() => {
    'passwordResetEnabled': passwordResetEnabled,
    'requireEmailVerification': requireEmailVerification,
    'geminiEnabled': geminiEnabled,
  };
}

class Survey {
  final int? id;
  final String slug;
  final String title;
  final String? description;
  final SurveyStatus status;
  final AuthRequirement authRequirement;
  final String? createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const Survey({
    this.id,
    required this.slug,
    required this.title,
    this.description,
    this.status = SurveyStatus.draft,
    this.authRequirement = AuthRequirement.anonymous,
    this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.startsAt,
    this.endsAt,
  });

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
    id: json['id'] == null ? null : _int(json['id']),
    slug: json['slug'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    status: _enum(SurveyStatus.values, json['status'], SurveyStatus.draft),
    authRequirement: _enum(
      AuthRequirement.values,
      json['authRequirement'],
      AuthRequirement.anonymous,
    ),
    createdByUserId: json['createdByUserId'] as String?,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    startsAt: _optionalDate(json['startsAt']),
    endsAt: _optionalDate(json['endsAt']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'slug': slug,
    'title': title,
    'description': description,
    'status': _enumName(status),
    'authRequirement': _enumName(authRequirement),
    'createdByUserId': createdByUserId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'startsAt': startsAt?.toIso8601String(),
    'endsAt': endsAt?.toIso8601String(),
  });

  Survey copyWith({
    int? id,
    String? slug,
    String? title,
    String? description,
    SurveyStatus? status,
    AuthRequirement? authRequirement,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    return Survey(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      authRequirement: authRequirement ?? this.authRequirement,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
    );
  }
}

class Question {
  final int? id;
  final int surveyId;
  final String text;
  final QuestionType type;
  final int orderIndex;
  final bool isRequired;
  final String? placeholder;
  final int? minLength;
  final int? maxLength;
  final bool isDeleted;

  const Question({
    this.id,
    required this.surveyId,
    required this.text,
    required this.type,
    required this.orderIndex,
    this.isRequired = true,
    this.placeholder,
    this.minLength,
    this.maxLength,
    this.isDeleted = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] == null ? null : _int(json['id']),
    surveyId: _int(json['surveyId']),
    text: json['text'] as String,
    type: _enum(QuestionType.values, json['type'], QuestionType.textSingle),
    orderIndex: _int(json['orderIndex']),
    isRequired: _bool(json['isRequired'], true),
    placeholder: json['placeholder'] as String?,
    minLength: json['minLength'] == null ? null : _int(json['minLength']),
    maxLength: json['maxLength'] == null ? null : _int(json['maxLength']),
    isDeleted: _bool(json['isDeleted']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'surveyId': surveyId,
    'text': text,
    'type': _enumName(type),
    'orderIndex': orderIndex,
    'isRequired': isRequired,
    'placeholder': placeholder,
    'minLength': minLength,
    'maxLength': maxLength,
    'isDeleted': isDeleted,
  });

  Question copyWith({
    int? id,
    int? surveyId,
    String? text,
    QuestionType? type,
    int? orderIndex,
    bool? isRequired,
    String? placeholder,
    int? minLength,
    int? maxLength,
    bool? isDeleted,
  }) {
    return Question(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      text: text ?? this.text,
      type: type ?? this.type,
      orderIndex: orderIndex ?? this.orderIndex,
      isRequired: isRequired ?? this.isRequired,
      placeholder: placeholder ?? this.placeholder,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class Choice {
  final int? id;
  final int questionId;
  final String text;
  final int orderIndex;
  final String? value;

  const Choice({
    this.id,
    required this.questionId,
    required this.text,
    required this.orderIndex,
    this.value,
  });

  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
    id: json['id'] == null ? null : _int(json['id']),
    questionId: _int(json['questionId']),
    text: json['text'] as String,
    orderIndex: _int(json['orderIndex']),
    value: json['value'] as String?,
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'questionId': questionId,
    'text': text,
    'orderIndex': orderIndex,
    'value': value,
  });

  Choice copyWith({
    int? id,
    int? questionId,
    String? text,
    int? orderIndex,
    String? value,
  }) {
    return Choice(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      text: text ?? this.text,
      orderIndex: orderIndex ?? this.orderIndex,
      value: value ?? this.value,
    );
  }
}

class Answer {
  final int? id;
  final int surveyResponseId;
  final int questionId;
  final String? textValue;
  final List<int>? selectedChoiceIds;

  const Answer({
    this.id,
    required this.surveyResponseId,
    required this.questionId,
    this.textValue,
    this.selectedChoiceIds,
  });

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
    id: json['id'] == null ? null : _int(json['id']),
    surveyResponseId: _int(json['surveyResponseId']),
    questionId: _int(json['questionId']),
    textValue: json['textValue'] as String?,
    selectedChoiceIds: _intList(json['selectedChoiceIds']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'surveyResponseId': surveyResponseId,
    'questionId': questionId,
    'textValue': textValue,
    'selectedChoiceIds': selectedChoiceIds,
  });

  Answer copyWith({
    int? id,
    int? surveyResponseId,
    int? questionId,
    String? textValue,
    List<int>? selectedChoiceIds,
  }) {
    return Answer(
      id: id ?? this.id,
      surveyResponseId: surveyResponseId ?? this.surveyResponseId,
      questionId: questionId ?? this.questionId,
      textValue: textValue ?? this.textValue,
      selectedChoiceIds: selectedChoiceIds ?? this.selectedChoiceIds,
    );
  }
}

List<Answer> buildAnswers(
  Map<int, dynamic> answerValues,
  Iterable<Question> questions, {
  int surveyResponseId = 0,
}) {
  final result = <Answer>[];

  for (final question in questions) {
    final questionId = question.id;
    if (questionId == null) continue;

    final value = answerValues[questionId];
    if (value == null) continue;

    switch (question.type) {
      case QuestionType.singleChoice:
        if (value is int) {
          result.add(
            Answer(
              surveyResponseId: surveyResponseId,
              questionId: questionId,
              selectedChoiceIds: [value],
            ),
          );
        }
      case QuestionType.multipleChoice:
        if (value is List<int> && value.isNotEmpty) {
          result.add(
            Answer(
              surveyResponseId: surveyResponseId,
              questionId: questionId,
              selectedChoiceIds: value,
            ),
          );
        }
      case QuestionType.textSingle:
      case QuestionType.textMultiLine:
        if (value is String && value.trim().isNotEmpty) {
          result.add(
            Answer(
              surveyResponseId: surveyResponseId,
              questionId: questionId,
              textValue: value.trim(),
            ),
          );
        }
    }
  }

  return result;
}

class DeviceInfo {
  final String? deviceId;
  final String? label;
  final String? platform;
  final String? os;
  final String? osVersion;
  final String? browser;
  final String? browserVersion;
  final String? appVersion;
  final String? appBuild;
  final String? model;
  final String? manufacturer;
  final String? locale;
  final String? timezone;
  final int? screenWidth;
  final int? screenHeight;
  final double? devicePixelRatio;
  final String? userAgent;

  const DeviceInfo({
    this.deviceId,
    this.label,
    this.platform,
    this.os,
    this.osVersion,
    this.browser,
    this.browserVersion,
    this.appVersion,
    this.appBuild,
    this.model,
    this.manufacturer,
    this.locale,
    this.timezone,
    this.screenWidth,
    this.screenHeight,
    this.devicePixelRatio,
    this.userAgent,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    deviceId: json['deviceId'] as String?,
    label: json['label'] as String?,
    platform: json['platform'] as String?,
    os: json['os'] as String?,
    osVersion: json['osVersion'] as String?,
    browser: json['browser'] as String?,
    browserVersion: json['browserVersion'] as String?,
    appVersion: json['appVersion'] as String?,
    appBuild: json['appBuild'] as String?,
    model: json['model'] as String?,
    manufacturer: json['manufacturer'] as String?,
    locale: json['locale'] as String?,
    timezone: json['timezone'] as String?,
    screenWidth: json['screenWidth'] == null ? null : _int(json['screenWidth']),
    screenHeight: json['screenHeight'] == null
        ? null
        : _int(json['screenHeight']),
    devicePixelRatio: json['devicePixelRatio'] == null
        ? null
        : _double(json['devicePixelRatio']),
    userAgent: json['userAgent'] as String?,
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'deviceId': deviceId,
    'label': label,
    'platform': platform,
    'os': os,
    'osVersion': osVersion,
    'browser': browser,
    'browserVersion': browserVersion,
    'appVersion': appVersion,
    'appBuild': appBuild,
    'model': model,
    'manufacturer': manufacturer,
    'locale': locale,
    'timezone': timezone,
    'screenWidth': screenWidth,
    'screenHeight': screenHeight,
    'devicePixelRatio': devicePixelRatio,
    'userAgent': userAgent,
  });

  DeviceInfo merge(DeviceInfo? override) {
    if (override == null) return this;
    return DeviceInfo(
      deviceId: override.deviceId ?? deviceId,
      label: override.label ?? label,
      platform: override.platform ?? platform,
      os: override.os ?? os,
      osVersion: override.osVersion ?? osVersion,
      browser: override.browser ?? browser,
      browserVersion: override.browserVersion ?? browserVersion,
      appVersion: override.appVersion ?? appVersion,
      appBuild: override.appBuild ?? appBuild,
      model: override.model ?? model,
      manufacturer: override.manufacturer ?? manufacturer,
      locale: override.locale ?? locale,
      timezone: override.timezone ?? timezone,
      screenWidth: override.screenWidth ?? screenWidth,
      screenHeight: override.screenHeight ?? screenHeight,
      devicePixelRatio: override.devicePixelRatio ?? devicePixelRatio,
      userAgent: override.userAgent ?? userAgent,
    );
  }

  String? get summary {
    final name = label ?? model;
    final system = [
      os,
      osVersion,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');
    final agent = [
      browser,
      browserVersion,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');
    final parts = [
      name,
      system.isEmpty ? platform : system,
      agent.isEmpty ? null : agent,
    ].whereType<String>().where((value) => value.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' / ');
  }

  String? get detailSummary {
    final screen = screenWidth != null && screenHeight != null
        ? '${screenWidth}x$screenHeight'
        : null;
    final parts = [
      locale,
      timezone,
      screen,
      devicePixelRatio == null ? null : '${devicePixelRatio}x',
      appVersion == null ? null : 'app $appVersion',
      appBuild == null ? null : 'build $appBuild',
    ].whereType<String>().where((value) => value.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' / ');
  }
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

class AnonymousAccount {
  final String id;
  final String? displayName;
  final DateTime createdAt;
  final DateTime lastSeenAt;

  const AnonymousAccount({
    required this.id,
    this.displayName,
    required this.createdAt,
    required this.lastSeenAt,
  });

  factory AnonymousAccount.fromJson(Map<String, dynamic> json) =>
      AnonymousAccount(
        id: json['id'] as String,
        displayName: json['displayName'] as String?,
        createdAt: _date(json['createdAt']),
        lastSeenAt: _date(json['lastSeenAt']),
      );
}

class AnonymousSession {
  final AnonymousAccount account;
  final String token;

  const AnonymousSession({required this.account, required this.token});

  factory AnonymousSession.fromJson(Map<String, dynamic> json) =>
      AnonymousSession(
        account: _object(json['account'], AnonymousAccount.fromJson),
        token: json['token'] as String,
      );
}

class AdminReply {
  final int id;
  final int surveyResponseId;
  final String anonymousAccountId;
  final String body;
  final String? adminId;
  final DateTime createdAt;
  final DateTime? readAt;

  const AdminReply({
    required this.id,
    required this.surveyResponseId,
    required this.anonymousAccountId,
    required this.body,
    this.adminId,
    required this.createdAt,
    this.readAt,
  });

  factory AdminReply.fromJson(Map<String, dynamic> json) => AdminReply(
    id: _int(json['id']),
    surveyResponseId: _int(json['surveyResponseId']),
    anonymousAccountId: json['anonymousAccountId'] as String,
    body: json['body'] as String,
    adminId: json['adminId'] as String?,
    createdAt: _date(json['createdAt']),
    readAt: _optionalDate(json['readAt']),
  );
}

class QuestionWithChoices {
  final String text;
  final QuestionType type;
  final bool isRequired;
  final String? placeholder;
  final List<String> choices;

  const QuestionWithChoices({
    required this.text,
    required this.type,
    required this.isRequired,
    this.placeholder,
    required this.choices,
  });

  factory QuestionWithChoices.fromJson(Map<String, dynamic> json) =>
      QuestionWithChoices(
        text: json['text'] as String,
        type: _enum(QuestionType.values, json['type'], QuestionType.textSingle),
        isRequired: _bool(json['isRequired'], true),
        placeholder: json['placeholder'] as String?,
        choices: (json['choices'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => _withoutNulls({
    'text': text,
    'type': _enumName(type),
    'isRequired': isRequired,
    'placeholder': placeholder,
    'choices': choices,
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

class AuthUserInfo {
  final UuidValue id;
  final String? email;
  final List<String> scopeNames;
  final bool blocked;
  final DateTime created;

  const AuthUserInfo({
    required this.id,
    this.email,
    required this.scopeNames,
    required this.blocked,
    required this.created,
  });

  factory AuthUserInfo.fromJson(Map<String, dynamic> json) => AuthUserInfo(
    id: json['id'].toString(),
    email: json['email'] as String?,
    scopeNames: (json['scopeNames'] as List? ?? const [])
        .map((e) => '$e')
        .toList(),
    blocked: _bool(json['blocked']),
    created: _date(json['created']),
  );
}

class AuthSuccess {
  final String token;
  final AuthUserInfo user;

  const AuthSuccess({required this.token, required this.user});

  factory AuthSuccess.fromJson(Map<String, dynamic> json) => AuthSuccess(
    token: json['token'] as String,
    user: _object(json['user'], AuthUserInfo.fromJson),
  );
}
