import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

export 'src/utils/date_format.dart';

typedef UuidValue = String;

enum QuestionType { singleChoice, multipleChoice, textSingle, textMultiLine }

enum SurveyStatus { draft, published, closed, archived }

enum AuthRequirement { anonymous, authenticated }

String _enumName(Object value) => value.toString().split('.').last;

DateTime _date(dynamic value) =>
    value is DateTime ? value : DateTime.parse(value as String);

DateTime? _optionalDate(dynamic value) => value == null ? null : _date(value);

int _int(dynamic value) => value is int ? value : int.parse(value.toString());

double _double(dynamic value) =>
    value is double ? value : double.parse(value.toString());

bool _bool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value.toString() == 'true';
}

T _enum<T>(Iterable<T> values, dynamic value, T fallback) {
  if (value == null) return fallback;
  final name = value.toString();
  return values.firstWhere(
    (v) => _enumName(v as Object) == name,
    orElse: () => fallback,
  );
}

List<int>? _intList(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.map(_int).toList();
  if (value is String && value.isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is List) return decoded.map(_int).toList();
  }
  return null;
}

Map<String, dynamic>? _map(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

Map<String, dynamic> _withoutNulls(Map<String, dynamic> source) {
  return Map.fromEntries(source.entries.where((entry) => entry.value != null));
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Object? details;

  const ApiException(this.statusCode, this.message, [this.details]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

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
    deviceInfo: _map(json['deviceInfo']) == null
        ? null
        : DeviceInfo.fromJson(_map(json['deviceInfo'])!),
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
        account: AnonymousAccount.fromJson(
          json['account'] as Map<String, dynamic>,
        ),
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
        .map((value) => QuestionResult.fromJson(value))
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
    user: AuthUserInfo.fromJson(json['user'] as Map<String, dynamic>),
  );
}

class Client {
  final Uri baseUri;
  final http.Client _httpClient;

  late final SurveyEndpoint survey;
  late final SurveyAdminEndpoint surveyAdmin;
  late final QuestionAdminEndpoint questionAdmin;
  late final ChoiceAdminEndpoint choiceAdmin;
  late final ResponseAnalyticsEndpoint responseAnalytics;
  late final NotificationSettingsEndpoint notificationSettings;
  late final ConfigEndpoint config;
  late final UserAdminEndpoint userAdmin;
  late final AiAdminEndpoint aiAdmin;
  late final EmailIdpEndpoint emailIdp;
  late final AnonymousEndpoint anonymous;
  late final ClientAuth auth;

  Object? authSessionManager;
  Object? connectivityMonitor;

  Client(String serverUrl, {http.Client? httpClient})
    : baseUri = Uri.parse(
        serverUrl.endsWith('/')
            ? serverUrl.substring(0, serverUrl.length - 1)
            : serverUrl,
      ),
      _httpClient = httpClient ?? http.Client() {
    auth = ClientAuth();
    survey = SurveyEndpoint(this);
    surveyAdmin = SurveyAdminEndpoint(this);
    questionAdmin = QuestionAdminEndpoint(this);
    choiceAdmin = ChoiceAdminEndpoint(this);
    responseAnalytics = ResponseAnalyticsEndpoint(this);
    notificationSettings = NotificationSettingsEndpoint(this);
    config = ConfigEndpoint(this);
    userAdmin = UserAdminEndpoint(this);
    aiAdmin = AiAdminEndpoint(this);
    emailIdp = EmailIdpEndpoint(this);
    anonymous = AnonymousEndpoint(this);
  }

  Future<dynamic> request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool authenticated = false,
    String? bearerToken,
  }) async {
    final uri = baseUri.replace(
      path: '${baseUri.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: query == null
          ? null
          : Map.fromEntries(
              query.entries.where((entry) => entry.value.isNotEmpty),
            ),
    );

    final headers = <String, String>{
      'accept': 'application/json',
      if (body != null) 'content-type': 'application/json',
      if (bearerToken != null) 'authorization': 'Bearer $bearerToken',
      if (bearerToken == null && authenticated && auth.token != null)
        'authorization': 'Bearer ${auth.token}',
    };

    final response = await _httpClient
        .send(
          http.Request(method, uri)
            ..headers.addAll(headers)
            ..body = body == null ? '' : jsonEncode(body),
        )
        .then(http.Response.fromStream);

    final text = response.body;
    final decoded = text.isEmpty ? null : jsonDecode(text);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed';
      Object? details = decoded;
      if (decoded is Map<String, dynamic>) {
        message =
            decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            message;
        details = decoded['details'];
      }
      throw ApiException(response.statusCode, message, details);
    }

    return decoded;
  }

  void close() => _httpClient.close();
}

class ClientAuth {
  String? token;
  AuthUserInfo? signedInUser;

  ClientAuth();

  bool get isAuthenticated => token != null;

  Future<void> updateSignedInUser(AuthSuccess authSuccess) async {
    token = authSuccess.token;
    signedInUser = authSuccess.user;
  }

  Future<void> restore() async {}

  Future<void> signOutDevice() async {
    token = null;
    signedInUser = null;
  }
}

class SurveyEndpoint {
  final Client _client;
  SurveyEndpoint(this._client);

  Future<Survey?> getBySlug(String slug) async {
    final json = await _client.request('GET', '/api/surveys/$slug');
    return json == null ? null : Survey.fromJson(json);
  }

  Future<List<Question>> getQuestionsForSurvey(int surveyId) async {
    final json =
        await _client.request(
              'GET',
              '/api/surveys/id/$surveyId/questions',
            )
            as List;
    return json.map((value) => Question.fromJson(value)).toList();
  }

  Future<List<Choice>> getChoicesForQuestion(int questionId) async {
    final json =
        await _client.request(
              'GET',
              '/api/questions/$questionId/choices',
            )
            as List;
    return json.map((value) => Choice.fromJson(value)).toList();
  }

  Future<SurveyResponse> submitResponse({
    required int surveyId,
    required List<Answer> answers,
    String? anonymousId,
    DeviceInfo? deviceInfo,
    Map<String, dynamic>? metadata,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/surveys/id/$surveyId/responses',
      body: {
        'anonymousId': anonymousId,
        'answers': answers.map((answer) => answer.toJson()).toList(),
        'deviceInfo': deviceInfo?.toJson(),
        'metadata': metadata,
      },
      bearerToken: _client.anonymous.token,
    );
    return SurveyResponse.fromJson(json);
  }
}

class AnonymousEndpoint {
  final Client _client;
  String? token;
  AnonymousAccount? account;

  AnonymousEndpoint(this._client);

  bool get isAuthenticated => token != null;

  void useToken(String token, {AnonymousAccount? account}) {
    this.token = token;
    this.account = account;
  }

  void clear() {
    token = null;
    account = null;
  }

  Future<AnonymousSession> createAccount({String? displayName}) async {
    final json = await _client.request(
      'POST',
      '/api/anonymous/accounts',
      body: {'displayName': displayName},
    );
    final session = AnonymousSession.fromJson(json);
    token = session.token;
    account = session.account;
    return session;
  }

  Future<AnonymousAccount> me() async {
    final json = await _client.request(
      'GET',
      '/api/anonymous/me',
      bearerToken: token,
    );
    account = AnonymousAccount.fromJson(json);
    return account!;
  }

  Future<List<AdminReply>> getReplies({int? responseId}) async {
    final query = responseId == null ? null : {'responseId': '$responseId'};
    final json =
        await _client.request(
              'GET',
              '/api/anonymous/replies',
              query: query,
              bearerToken: token,
            )
            as List;
    return json.map((value) => AdminReply.fromJson(value)).toList();
  }
}

class EmailIdpEndpoint {
  final Client _client;
  EmailIdpEndpoint(this._client);

  Future<AuthSuccess> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/auth/login',
      body: {'email': email, 'password': password},
    );
    return AuthSuccess.fromJson(json);
  }

  Future<UuidValue> startRegistration({required String email}) async {
    final json = await _client.request(
      'POST',
      '/api/admin/auth/start-registration',
      body: {'email': email},
      authenticated: true,
    );
    return json['requestId'].toString();
  }

  Future<String> verifyRegistrationCode({
    required UuidValue accountRequestId,
    required String verificationCode,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/auth/verify-registration',
      body: {
        'accountRequestId': accountRequestId,
        'verificationCode': verificationCode,
      },
      authenticated: true,
    );
    return json['registrationToken'] as String;
  }

  Future<AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/auth/finish-registration',
      body: {'registrationToken': registrationToken, 'password': password},
      authenticated: true,
    );
    return AuthSuccess.fromJson(json);
  }

  Future<UuidValue> startPasswordReset({required String email}) async {
    throw const ApiException(501, 'Password reset is not configured');
  }

  Future<String> verifyPasswordResetCode({
    required UuidValue passwordResetRequestId,
    required String verificationCode,
  }) async {
    throw const ApiException(501, 'Password reset is not configured');
  }

  Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) async {
    throw const ApiException(501, 'Password reset is not configured');
  }
}

class ConfigEndpoint {
  final Client _client;
  ConfigEndpoint(this._client);

  Future<PublicConfig> getPublicConfig() async {
    final json = await _client.request('GET', '/api/config');
    return PublicConfig.fromJson(json);
  }
}

class SurveyAdminEndpoint {
  final Client _client;
  SurveyAdminEndpoint(this._client);

  Future<Survey> create(Survey survey) async {
    final json = await _client.request(
      'POST',
      '/api/admin/surveys',
      body: survey.toJson(),
      authenticated: true,
    );
    return Survey.fromJson(json);
  }

  Future<Survey> createWithQuestions(
    Survey survey,
    List<QuestionWithChoices> questions,
  ) async {
    final json = await _client.request(
      'POST',
      '/api/admin/surveys/with-questions',
      body: {
        'survey': survey.toJson(),
        'questions': questions.map((question) => question.toJson()).toList(),
      },
      authenticated: true,
    );
    return Survey.fromJson(json);
  }

  Future<Survey> update(Survey survey) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/surveys/${survey.id}',
      body: survey.toJson(),
      authenticated: true,
    );
    return Survey.fromJson(json);
  }

  Future<bool> delete(int surveyId) async {
    await _client.request(
      'DELETE',
      '/api/admin/surveys/$surveyId',
      authenticated: true,
    );
    return true;
  }

  Future<List<Survey>> list() async {
    final json =
        await _client.request(
              'GET',
              '/api/admin/surveys',
              authenticated: true,
            )
            as List;
    return json.map((value) => Survey.fromJson(value)).toList();
  }

  Future<Survey?> getById(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId',
      authenticated: true,
    );
    return json == null ? null : Survey.fromJson(json);
  }

  Future<Survey> publish(int surveyId) => _status(surveyId, 'publish');
  Future<Survey> close(int surveyId) => _status(surveyId, 'close');
  Future<Survey> reopen(int surveyId) => _status(surveyId, 'reopen');

  Future<Survey> _status(int surveyId, String action) async {
    final json = await _client.request(
      'POST',
      '/api/admin/surveys/$surveyId/$action',
      authenticated: true,
    );
    return Survey.fromJson(json);
  }
}

class QuestionAdminEndpoint {
  final Client _client;
  QuestionAdminEndpoint(this._client);

  Future<Question> create(Question question) async {
    final json = await _client.request(
      'POST',
      '/api/admin/questions',
      body: question.toJson(),
      authenticated: true,
    );
    return Question.fromJson(json);
  }

  Future<Question> update(Question question) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/questions/${question.id}',
      body: question.toJson(),
      authenticated: true,
    );
    return Question.fromJson(json);
  }

  Future<bool> delete(int questionId) async {
    final json = await _client.request(
      'DELETE',
      '/api/admin/questions/$questionId',
      authenticated: true,
    );
    return _bool(json['hardDeleted'], true);
  }

  Future<List<Question>> reorder(int surveyId, List<int> questionIds) async {
    final json =
        await _client.request(
              'POST',
              '/api/admin/surveys/$surveyId/questions/reorder',
              body: {'questionIds': questionIds},
              authenticated: true,
            )
            as List;
    return json.map((value) => Question.fromJson(value)).toList();
  }

  Future<List<Question>> getForSurvey(int surveyId) async {
    final json =
        await _client.request(
              'GET',
              '/api/admin/surveys/$surveyId/questions',
              authenticated: true,
            )
            as List;
    return json.map((value) => Question.fromJson(value)).toList();
  }

  Future<Question?> getById(int questionId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/questions/$questionId',
      authenticated: true,
    );
    return json == null ? null : Question.fromJson(json);
  }

  Future<List<Choice>> getChoicesForQuestion(int questionId) async {
    final json =
        await _client.request(
              'GET',
              '/api/admin/questions/$questionId/choices',
              authenticated: true,
            )
            as List;
    return json.map((value) => Choice.fromJson(value)).toList();
  }
}

class ChoiceAdminEndpoint {
  final Client _client;
  ChoiceAdminEndpoint(this._client);

  Future<Choice> create(Choice choice) async {
    final json = await _client.request(
      'POST',
      '/api/admin/choices',
      body: choice.toJson(),
      authenticated: true,
    );
    return Choice.fromJson(json);
  }

  Future<Choice> update(Choice choice) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/choices/${choice.id}',
      body: choice.toJson(),
      authenticated: true,
    );
    return Choice.fromJson(json);
  }

  Future<bool> delete(int choiceId) async {
    await _client.request(
      'DELETE',
      '/api/admin/choices/$choiceId',
      authenticated: true,
    );
    return true;
  }

  Future<List<Choice>> reorder(int questionId, List<int> choiceIds) async {
    final json =
        await _client.request(
              'POST',
              '/api/admin/questions/$questionId/choices/reorder',
              body: {'choiceIds': choiceIds},
              authenticated: true,
            )
            as List;
    return json.map((value) => Choice.fromJson(value)).toList();
  }

  Future<Choice?> getById(int choiceId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/choices/$choiceId',
      authenticated: true,
    );
    return json == null ? null : Choice.fromJson(json);
  }
}

class ResponseAnalyticsEndpoint {
  final Client _client;
  ResponseAnalyticsEndpoint(this._client);

  Future<List<SurveyResponse>> getResponses(
    int surveyId, {
    int? limit,
    int? offset,
  }) async {
    final json =
        await _client.request(
              'GET',
              '/api/admin/surveys/$surveyId/responses',
              query: {
                if (limit != null) 'limit': '$limit',
                if (offset != null) 'offset': '$offset',
              },
              authenticated: true,
            )
            as List;
    return json.map((value) => SurveyResponse.fromJson(value)).toList();
  }

  Future<int> getResponseCount(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/responses/count',
      authenticated: true,
    );
    return _int(json['count']);
  }

  Future<List<Answer>> getAnswersForResponse(int responseId) async {
    final json =
        await _client.request(
              'GET',
              '/api/admin/responses/$responseId/answers',
              authenticated: true,
            )
            as List;
    return json.map((value) => Answer.fromJson(value)).toList();
  }

  Future<SurveyResults> getAggregatedResults(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/results',
      authenticated: true,
    );
    return SurveyResults.fromJson(json);
  }

  Future<Map<String, int>> getResponseTrends(
    int surveyId, {
    int days = 30,
  }) async {
    final json =
        await _client.request(
              'GET',
              '/api/admin/surveys/$surveyId/trends',
              query: {'days': '$days'},
              authenticated: true,
            )
            as Map;
    return json.map((key, value) => MapEntry(key.toString(), _int(value)));
  }

  Future<bool> deleteResponse(int responseId) async {
    await _client.request(
      'DELETE',
      '/api/admin/responses/$responseId',
      authenticated: true,
    );
    return true;
  }

  Future<AdminReply> createReply(int responseId, String body) async {
    final json = await _client.request(
      'POST',
      '/api/admin/responses/$responseId/replies',
      body: {'body': body},
      authenticated: true,
    );
    return AdminReply.fromJson(json);
  }

  Future<List<AdminReply>> getReplies(int responseId) async {
    final json =
        await _client.request(
              'GET',
              '/api/admin/responses/$responseId/replies',
              authenticated: true,
            )
            as List;
    return json.map((value) => AdminReply.fromJson(value)).toList();
  }
}

class NotificationSettingsEndpoint {
  final Client _client;
  NotificationSettingsEndpoint(this._client);

  Future<NotificationSettings?> getForSurvey(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/notification-settings',
      authenticated: true,
    );
    return json == null ? null : NotificationSettings.fromJson(json);
  }

  Future<NotificationSettings> upsert(NotificationSettings settings) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/surveys/${settings.surveyId}/notification-settings',
      body: settings.toJson(),
      authenticated: true,
    );
    return NotificationSettings.fromJson(json);
  }

  Future<NotificationSettings> enable(int surveyId) => _toggle(surveyId, true);
  Future<NotificationSettings> disable(int surveyId) =>
      _toggle(surveyId, false);

  Future<NotificationSettings> _toggle(int surveyId, bool enabled) async {
    final json = await _client.request(
      'POST',
      '/api/admin/surveys/$surveyId/notification-settings/toggle',
      body: {'enabled': enabled},
      authenticated: true,
    );
    return NotificationSettings.fromJson(json);
  }

  Future<bool> delete(int surveyId) async {
    await _client.request(
      'DELETE',
      '/api/admin/surveys/$surveyId/notification-settings',
      authenticated: true,
    );
    return true;
  }

  Future<bool> isEmailConfigured() async => false;

  Future<bool> sendTestNotification(int surveyId) async {
    throw const ApiException(501, 'Email notifications are not configured');
  }
}

class UserAdminEndpoint {
  final Client _client;
  UserAdminEndpoint(this._client);

  Future<bool> isFirstUser() async {
    final json = await _client.request('GET', '/api/admin/bootstrap/status');
    return _bool(json['isFirstUser']);
  }

  Future<AuthSuccess> registerFirstUser({
    required String email,
    required String password,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/bootstrap',
      body: {'email': email, 'password': password},
    );
    return AuthSuccess.fromJson(json);
  }

  Future<List<AuthUserInfo>> listUsers() async {
    final json =
        await _client.request(
              'GET',
              '/api/admin/users',
              authenticated: true,
            )
            as List;
    return json.map((value) => AuthUserInfo.fromJson(value)).toList();
  }

  Future<AuthUserInfo> createUser({
    required String email,
    required String password,
    required List<String> scopes,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/users',
      body: {'email': email, 'password': password, 'scopes': scopes},
      authenticated: true,
    );
    return AuthUserInfo.fromJson(json);
  }

  Future<bool> deleteUser(UuidValue userId) async {
    final json = await _client.request(
      'DELETE',
      '/api/admin/users/$userId',
      authenticated: true,
    );
    return _bool(json['selfDeleted']);
  }

  Future<bool> toggleUserBlocked(UuidValue userId) async {
    final json = await _client.request(
      'POST',
      '/api/admin/users/$userId/toggle-blocked',
      authenticated: true,
    );
    return _bool(json['blocked']);
  }
}

class AiAdminEndpoint {
  final Client _client;
  AiAdminEndpoint(this._client);

  Future<List<QuestionWithChoices>> generateSurveyQuestions(
    String prompt,
  ) async {
    final json =
        await _client.request(
              'POST',
              '/api/admin/ai/survey-questions',
              body: {'prompt': prompt},
              authenticated: true,
            )
            as List;
    return json.map((value) => QuestionWithChoices.fromJson(value)).toList();
  }
}
