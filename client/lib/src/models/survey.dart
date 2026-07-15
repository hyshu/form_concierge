part of form_concierge_client;

/// Sentinel for [Question.copyWith] so null can clear optional constraints.
const Object _unset = Object();

const formContentLocaleCodes = <String>[
  'en',
  'ja',
  'zh-Hans',
  'zh-Hant',
  'ko',
  'de',
  'es',
  'fr',
  'it',
  'th',
  'tr',
];

const defaultFormContentLocale = 'en';

const formContentLocaleLabels = <String, String>{
  'en': 'English',
  'ja': '日本語',
  'zh-Hans': '简体中文',
  'zh-Hant': '繁體中文',
  'ko': '한국어',
  'de': 'Deutsch',
  'es': 'Español',
  'fr': 'Français',
  'it': 'Italiano',
  'th': 'ไทย',
  'tr': 'Türkçe',
};

String normalizeFormContentLocale(String locale) {
  final normalized = locale.replaceAll('_', '-');
  if (formContentLocaleCodes.contains(normalized)) return normalized;
  final lower = normalized.toLowerCase();
  if (lower == 'zh-hans' || lower == 'zh-cn' || lower == 'zh-sg') {
    return 'zh-Hans';
  }
  if (lower == 'zh-hant' ||
      lower == 'zh-tw' ||
      lower == 'zh-hk' ||
      lower == 'zh-mo') {
    return 'zh-Hant';
  }
  final language = lower.split('-').first;
  if (formContentLocaleCodes.contains(language)) return language;
  return normalized;
}

/// Picks the first [preferredLocales] entry that is in [supportedLocales]
/// (after [normalizeFormContentLocale]), otherwise [defaultLocale].
String resolveFormContentLocale({
  required Iterable<String> preferredLocales,
  required List<String> supportedLocales,
  String defaultLocale = defaultFormContentLocale,
}) {
  final orderedSupported = <String>[];
  for (final locale in supportedLocales) {
    final normalized = normalizeFormContentLocale(locale);
    if (!orderedSupported.contains(normalized)) {
      orderedSupported.add(normalized);
    }
  }
  if (orderedSupported.isEmpty) {
    return normalizeFormContentLocale(defaultLocale);
  }

  final normalizedDefault = normalizeFormContentLocale(defaultLocale);
  final fallback = orderedSupported.contains(normalizedDefault)
      ? normalizedDefault
      : orderedSupported.first;

  for (final preferred in preferredLocales) {
    final candidate = normalizeFormContentLocale(preferred);
    if (orderedSupported.contains(candidate)) return candidate;
  }
  return fallback;
}

class LocalizedText {
  final Map<String, String> values;

  const LocalizedText(this.values);

  factory LocalizedText.fromJson(Object? json) {
    final map = _requiredMap(json);
    return LocalizedText(
      map.map((key, value) => MapEntry(key, _string(value))),
    );
  }

  factory LocalizedText.filled(
    String value, {
    Iterable<String> locales = formContentLocaleCodes,
  }) => LocalizedText({
    for (final locale in locales) locale: value,
  });

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(values);

  String valueFor(String locale) {
    final normalized = normalizeFormContentLocale(locale);
    return values[normalized] ??
        values[defaultFormContentLocale] ??
        (values.isEmpty ? '' : values.values.first);
  }

  LocalizedText copyWithLocale(String locale, String value) => LocalizedText({
    ...values,
    normalizeFormContentLocale(locale): value,
  });
}

class FormContentMessages {
  static String text(String locale, String key) {
    final messages =
        formContentLocalizedValues[normalizeFormContentLocale(locale)] ??
        formContentLocalizedValues[defaultFormContentLocale]!;
    return messages[key] ??
        formContentLocalizedValues[defaultFormContentLocale]![key]!;
  }

  static String requiredQuestion(String locale) =>
      text(locale, 'requiredQuestion');

  static String minCharacters(String locale, int count) =>
      text(locale, 'minCharacters').replaceAll('{count}', '$count');

  static String maxCharacters(String locale, int count) =>
      text(locale, 'maxCharacters').replaceAll('{count}', '$count');

  static String minChoices(String locale, int count) =>
      text(locale, 'minChoices').replaceAll('{count}', '$count');

  static String maxChoices(String locale, int count) =>
      text(locale, 'maxChoices').replaceAll('{count}', '$count');

  static String selectionHint(
    String locale, {
    int? minSelected,
    int? maxSelected,
  }) {
    final parts = [
      if (minSelected != null)
        text(locale, 'minShort').replaceAll('{count}', '$minSelected'),
      if (maxSelected != null)
        text(locale, 'maxShort').replaceAll('{count}', '$maxSelected'),
    ];
    return text(
      locale,
      'selectionHint',
    ).replaceAll('{summary}', parts.join(', '));
  }
}

class Project {
  final int? id;
  final String slug;
  final String? customDomain;
  final String defaultLocale;
  final List<String> supportedLocales;
  final String name;
  final String? createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    this.id,
    required this.slug,
    this.customDomain,
    this.defaultLocale = defaultFormContentLocale,
    this.supportedLocales = formContentLocaleCodes,
    required this.name,
    this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] == null ? null : _int(json['id']),
    slug: _string(json['slug']),
    customDomain: _optionalString(json['customDomain']),
    defaultLocale: _string(json['defaultLocale']),
    supportedLocales: _stringList(json['supportedLocales']),
    name: _string(json['name']),
    createdByUserId: _optionalString(json['createdByUserId']),
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'slug': slug,
    'customDomain': customDomain ?? '',
    'defaultLocale': defaultLocale,
    'supportedLocales': supportedLocales,
    'name': name,
    'createdByUserId': createdByUserId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  });

  Project copyWith({
    int? id,
    String? slug,
    String? customDomain,
    bool clearCustomDomain = false,
    String? defaultLocale,
    List<String>? supportedLocales,
    String? name,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Project(
    id: id ?? this.id,
    slug: slug ?? this.slug,
    customDomain: clearCustomDomain ? null : customDomain ?? this.customDomain,
    defaultLocale: defaultLocale ?? this.defaultLocale,
    supportedLocales: supportedLocales ?? this.supportedLocales,
    name: name ?? this.name,
    createdByUserId: createdByUserId ?? this.createdByUserId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class ProjectWithSurveys {
  final Project project;
  final List<Survey> surveys;

  const ProjectWithSurveys({required this.project, required this.surveys});

  factory ProjectWithSurveys.fromJson(Map<String, dynamic> json) =>
      ProjectWithSurveys(
        project: _object(json['project'], Project.fromJson),
        surveys: _objectList(json['surveys'], Survey.fromJson),
      );
}

class PublicProject {
  final Project project;
  final List<Survey> surveys;

  const PublicProject({required this.project, required this.surveys});

  factory PublicProject.fromJson(Map<String, dynamic> json) => PublicProject(
    project: _object(json['project'], Project.fromJson),
    surveys: _objectList(json['surveys'], Survey.fromJson),
  );
}

class Survey {
  final int? id;
  final int projectId;
  final String slug;
  final LocalizedText titleTranslations;
  final LocalizedText descriptionTranslations;
  final SurveyStatus status;
  final bool webEnabled;
  final bool followUpEnabled;

  /// Admin-authored instructions included in AI follow-up generation.
  final String? followUpPrompt;

  /// Persisted admin setting. Use [captchaRequired] for submission behavior.
  final bool captchaConfigurationEnabled;

  @Deprecated('Use captchaRequired for submission behavior.')
  bool get captchaEnabled => captchaConfigurationEnabled;

  /// Whether this client must supply a CAPTCHA token for this survey.
  final bool captchaRequired;
  final String? createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const Survey({
    this.id,
    required this.projectId,
    required this.slug,
    required this.titleTranslations,
    required this.descriptionTranslations,
    this.status = SurveyStatus.draft,
    this.webEnabled = true,
    this.followUpEnabled = false,
    this.followUpPrompt,
    bool captchaConfigurationEnabled = true,
    @Deprecated('Use captchaRequired for submission behavior.')
    bool? captchaEnabled,
    bool? captchaRequired,
    this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.startsAt,
    this.endsAt,
  }) : captchaConfigurationEnabled =
           captchaEnabled ?? captchaConfigurationEnabled,
       captchaRequired =
           captchaRequired ?? captchaEnabled ?? captchaConfigurationEnabled;

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
    id: json['id'] == null ? null : _int(json['id']),
    projectId: _int(json['projectId']),
    slug: _string(json['slug']),
    titleTranslations: LocalizedText.fromJson(json['titleTranslations']),
    descriptionTranslations: LocalizedText.fromJson(
      json['descriptionTranslations'],
    ),
    status: _enum(SurveyStatus.values, json['status']),
    webEnabled: _bool(json['webEnabled']),
    followUpEnabled: _bool(json['followUpEnabled'] ?? false),
    followUpPrompt: _optionalString(json['followUpPrompt']),
    captchaConfigurationEnabled: _bool(json['captchaEnabled'] ?? true),
    // TODO(form-concierge-1.0.0): Remove the captchaEnabled fallback.
    captchaRequired: _bool(
      json['captchaRequired'] ?? json['captchaEnabled'] ?? true,
    ),
    createdByUserId: _optionalString(json['createdByUserId']),
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    startsAt: _optionalDate(json['startsAt']),
    endsAt: _optionalDate(json['endsAt']),
  );

  Map<String, dynamic> toJson() => {
    ..._withoutNulls({
      'id': id,
      'projectId': projectId,
      'slug': slug,
      'titleTranslations': titleTranslations.toJson(),
      'descriptionTranslations': descriptionTranslations.toJson(),
      'status': _enumName(status),
      'webEnabled': webEnabled,
      'followUpEnabled': followUpEnabled,
      'captchaEnabled': captchaConfigurationEnabled,
      'captchaRequired': captchaRequired,
      'createdByUserId': createdByUserId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'startsAt': startsAt?.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
    }),
    // Empty string clears the field server-side (null would be dropped).
    'followUpPrompt': followUpPrompt ?? '',
  };

  Survey copyWith({
    int? id,
    int? projectId,
    String? slug,
    LocalizedText? titleTranslations,
    LocalizedText? descriptionTranslations,
    SurveyStatus? status,
    bool? webEnabled,
    bool? followUpEnabled,
    String? followUpPrompt,
    bool clearFollowUpPrompt = false,
    bool? captchaConfigurationEnabled,
    @Deprecated('Use captchaRequired for submission behavior.')
    bool? captchaEnabled,
    bool? captchaRequired,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startsAt,
    DateTime? endsAt,
  }) => Survey(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    slug: slug ?? this.slug,
    titleTranslations: titleTranslations ?? this.titleTranslations,
    descriptionTranslations:
        descriptionTranslations ?? this.descriptionTranslations,
    status: status ?? this.status,
    webEnabled: webEnabled ?? this.webEnabled,
    followUpEnabled: followUpEnabled ?? this.followUpEnabled,
    followUpPrompt: clearFollowUpPrompt
        ? null
        : (followUpPrompt ?? this.followUpPrompt),
    captchaConfigurationEnabled:
        captchaEnabled ??
        captchaConfigurationEnabled ??
        this.captchaConfigurationEnabled,
    captchaRequired: captchaRequired ?? this.captchaRequired,
    createdByUserId: createdByUserId ?? this.createdByUserId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
  );

  String titleFor(String locale) => titleTranslations.valueFor(locale);
  String descriptionFor(String locale) =>
      descriptionTranslations.valueFor(locale);

  String get title => titleFor(defaultFormContentLocale);
  String? get description {
    final value = descriptionFor(defaultFormContentLocale);
    return value.trim().isEmpty ? null : value;
  }
}

class Question {
  final int? id;
  final int surveyId;
  final LocalizedText textTranslations;
  final QuestionType type;
  final int orderIndex;
  final bool isRequired;
  final LocalizedText placeholderTranslations;
  final int? minLength;
  final int? maxLength;
  final int? minSelected;
  final int? maxSelected;
  final VisibilityConditionMode visibilityConditionMode;
  final bool isDeleted;

  const Question({
    this.id,
    required this.surveyId,
    required this.textTranslations,
    required this.type,
    required this.orderIndex,
    this.isRequired = true,
    required this.placeholderTranslations,
    this.minLength,
    this.maxLength,
    this.minSelected,
    this.maxSelected,
    this.visibilityConditionMode = VisibilityConditionMode.all,
    this.isDeleted = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] == null ? null : _int(json['id']),
    surveyId: _int(json['surveyId']),
    textTranslations: LocalizedText.fromJson(json['textTranslations']),
    type: _enum(QuestionType.values, json['type']),
    orderIndex: _int(json['orderIndex']),
    isRequired: _bool(json['isRequired']),
    placeholderTranslations: LocalizedText.fromJson(
      json['placeholderTranslations'],
    ),
    minLength: json['minLength'] == null ? null : _int(json['minLength']),
    maxLength: json['maxLength'] == null ? null : _int(json['maxLength']),
    minSelected: json['minSelected'] == null ? null : _int(json['minSelected']),
    maxSelected: json['maxSelected'] == null ? null : _int(json['maxSelected']),
    visibilityConditionMode: _enum(
      VisibilityConditionMode.values,
      json['visibilityConditionMode'],
    ),
    isDeleted: _bool(json['isDeleted']),
  );

  Map<String, dynamic> toJson() => {
    // Always include constraint fields (including null) so updates can clear
    // min/max on the server via Object.hasOwn. Other nulls are still stripped.
    ..._withoutNulls({
      'id': id,
      'surveyId': surveyId,
      'textTranslations': textTranslations.toJson(),
      'type': _enumName(type),
      'orderIndex': orderIndex,
      'isRequired': isRequired,
      'placeholderTranslations': placeholderTranslations.toJson(),
      'visibilityConditionMode': _enumName(visibilityConditionMode),
      'isDeleted': isDeleted,
    }),
    'minLength': minLength,
    'maxLength': maxLength,
    'minSelected': minSelected,
    'maxSelected': maxSelected,
  };

  Question copyWith({
    int? id,
    int? surveyId,
    LocalizedText? textTranslations,
    QuestionType? type,
    int? orderIndex,
    bool? isRequired,
    LocalizedText? placeholderTranslations,
    Object? minLength = _unset,
    Object? maxLength = _unset,
    Object? minSelected = _unset,
    Object? maxSelected = _unset,
    VisibilityConditionMode? visibilityConditionMode,
    bool? isDeleted,
  }) => Question(
    id: id ?? this.id,
    surveyId: surveyId ?? this.surveyId,
    textTranslations: textTranslations ?? this.textTranslations,
    type: type ?? this.type,
    orderIndex: orderIndex ?? this.orderIndex,
    isRequired: isRequired ?? this.isRequired,
    placeholderTranslations:
        placeholderTranslations ?? this.placeholderTranslations,
    minLength: identical(minLength, _unset)
        ? this.minLength
        : minLength as int?,
    maxLength: identical(maxLength, _unset)
        ? this.maxLength
        : maxLength as int?,
    minSelected: identical(minSelected, _unset)
        ? this.minSelected
        : minSelected as int?,
    maxSelected: identical(maxSelected, _unset)
        ? this.maxSelected
        : maxSelected as int?,
    visibilityConditionMode:
        visibilityConditionMode ?? this.visibilityConditionMode,
    isDeleted: isDeleted ?? this.isDeleted,
  );

  String textFor(String locale) => textTranslations.valueFor(locale);

  String? placeholderFor(String locale) {
    final value = placeholderTranslations.valueFor(locale);
    return value.trim().isEmpty ? null : value;
  }

  String get text => textFor(defaultFormContentLocale);
  String? get placeholder => placeholderFor(defaultFormContentLocale);
}

class QuestionVisibilityRule {
  final int? id;
  final int surveyId;
  final int targetQuestionId;
  final int sourceQuestionId;
  final VisibilityOperator operator;
  final Object? value;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const QuestionVisibilityRule({
    this.id,
    required this.surveyId,
    required this.targetQuestionId,
    required this.sourceQuestionId,
    required this.operator,
    this.value,
    this.createdAt,
    this.updatedAt,
  });

  factory QuestionVisibilityRule.fromJson(Map<String, dynamic> json) =>
      QuestionVisibilityRule(
        id: json['id'] == null ? null : _int(json['id']),
        surveyId: _int(json['surveyId']),
        targetQuestionId: _int(json['targetQuestionId']),
        sourceQuestionId: _int(json['sourceQuestionId']),
        operator: _enum(VisibilityOperator.values, json['operator']),
        value: json['value'],
        createdAt: _optionalDate(json['createdAt']),
        updatedAt: _optionalDate(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'surveyId': surveyId,
    'targetQuestionId': targetQuestionId,
    'sourceQuestionId': sourceQuestionId,
    'operator': _enumName(operator),
    'value': value,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  });

  QuestionVisibilityRule copyWith({
    int? id,
    int? surveyId,
    int? targetQuestionId,
    int? sourceQuestionId,
    VisibilityOperator? operator,
    Object? value,
    bool clearValue = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => QuestionVisibilityRule(
    id: id ?? this.id,
    surveyId: surveyId ?? this.surveyId,
    targetQuestionId: targetQuestionId ?? this.targetQuestionId,
    sourceQuestionId: sourceQuestionId ?? this.sourceQuestionId,
    operator: operator ?? this.operator,
    value: clearValue ? null : value ?? this.value,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class Choice {
  final int? id;
  final int questionId;
  final LocalizedText textTranslations;
  final int orderIndex;
  final String? value;

  const Choice({
    this.id,
    required this.questionId,
    required this.textTranslations,
    required this.orderIndex,
    this.value,
  });

  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
    id: json['id'] == null ? null : _int(json['id']),
    questionId: _int(json['questionId']),
    textTranslations: LocalizedText.fromJson(json['textTranslations']),
    orderIndex: _int(json['orderIndex']),
    value: _optionalString(json['value']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'questionId': questionId,
    'textTranslations': textTranslations.toJson(),
    'orderIndex': orderIndex,
    'value': value,
  });

  Choice copyWith({
    int? id,
    int? questionId,
    LocalizedText? textTranslations,
    int? orderIndex,
    String? value,
  }) => Choice(
    id: id ?? this.id,
    questionId: questionId ?? this.questionId,
    textTranslations: textTranslations ?? this.textTranslations,
    orderIndex: orderIndex ?? this.orderIndex,
    value: value ?? this.value,
  );

  String textFor(String locale) => textTranslations.valueFor(locale);
  String get text => textFor(defaultFormContentLocale);
}

class QuestionWithChoices {
  final LocalizedText textTranslations;
  final QuestionType type;
  final bool isRequired;
  final LocalizedText placeholderTranslations;
  final int? minLength;
  final int? maxLength;
  final int? minSelected;
  final int? maxSelected;
  final VisibilityConditionMode visibilityConditionMode;
  final List<LocalizedText> choiceTranslations;

  const QuestionWithChoices({
    required this.textTranslations,
    required this.type,
    required this.isRequired,
    required this.placeholderTranslations,
    this.minLength,
    this.maxLength,
    this.minSelected,
    this.maxSelected,
    this.visibilityConditionMode = VisibilityConditionMode.all,
    required this.choiceTranslations,
  });

  factory QuestionWithChoices.fromJson(
    Map<String, dynamic> json,
  ) => QuestionWithChoices(
    textTranslations: LocalizedText.fromJson(json['textTranslations']),
    type: _enum(QuestionType.values, json['type']),
    isRequired: _bool(json['isRequired']),
    placeholderTranslations: LocalizedText.fromJson(
      json['placeholderTranslations'],
    ),
    minLength: json['minLength'] == null ? null : _int(json['minLength']),
    maxLength: json['maxLength'] == null ? null : _int(json['maxLength']),
    minSelected: json['minSelected'] == null ? null : _int(json['minSelected']),
    maxSelected: json['maxSelected'] == null ? null : _int(json['maxSelected']),
    visibilityConditionMode: _enum(
      VisibilityConditionMode.values,
      json['visibilityConditionMode'],
    ),
    choiceTranslations: _objectList(
      json['choiceTranslations'],
      LocalizedText.fromJson,
    ),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'textTranslations': textTranslations.toJson(),
    'type': _enumName(type),
    'isRequired': isRequired,
    'placeholderTranslations': placeholderTranslations.toJson(),
    'minLength': minLength,
    'maxLength': maxLength,
    'minSelected': minSelected,
    'maxSelected': maxSelected,
    'visibilityConditionMode': _enumName(visibilityConditionMode),
    'choiceTranslations': choiceTranslations
        .map((translations) => translations.toJson())
        .toList(),
  });

  String get text => textTranslations.valueFor(defaultFormContentLocale);
  String? get placeholder {
    final value = placeholderTranslations.valueFor(defaultFormContentLocale);
    return value.trim().isEmpty ? null : value;
  }

  List<String> get choices => choiceTranslations
      .map((translations) => translations.valueFor(defaultFormContentLocale))
      .toList();
}
