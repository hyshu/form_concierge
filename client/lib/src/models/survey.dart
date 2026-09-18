part of form_concierge_client;

/// Sentinel for [Question.copyWith] so null can clear optional constraints.
const Object _unset = Object();

/// Locale codes supported by the built-in survey translations.
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

/// The fallback locale used when a translation is unavailable.
const defaultFormContentLocale = 'en';

/// Human-readable language names indexed by supported locale code.
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

/// Normalizes locale separators and supported language aliases while preserving
/// unrecognized locale codes.
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

/// Text translations indexed by locale code.
class LocalizedText {
  /// Translations indexed by locale code.
  final Map<String, String> values;

  /// Creates LocalizedText with the supplied values.
  const LocalizedText(this.values);

  /// Decodes LocalizedText from its JSON representation.
  factory LocalizedText.fromJson(Object? json) {
    final map = _requiredMap(json);
    return LocalizedText(
      map.map((key, value) => MapEntry(key, _string(value))),
    );
  }

  /// Creates translations that use the same text for every supplied locale.
  factory LocalizedText.filled(
    String value, {
    Iterable<String> locales = formContentLocaleCodes,
  }) => LocalizedText({
    for (final locale in locales) locale: value,
  });

  /// Returns the JSON representation used by the API.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(values);

  /// Returns the requested translation, falling back to English, the first stored value,
  /// then an empty string.
  String valueFor(String locale) {
    final normalized = normalizeFormContentLocale(locale);
    return values[normalized] ??
        values[defaultFormContentLocale] ??
        (values.isEmpty ? '' : values.values.first);
  }

  /// Returns translations with the normalized locale set to the supplied text.
  LocalizedText copyWithLocale(String locale, String value) => LocalizedText({
    ...values,
    normalizeFormContentLocale(locale): value,
  });
}

/// Localized labels and validation messages used in survey forms.
class FormContentMessages {
  /// Returns a localized message by key with English as the fallback language.
  static String text(String locale, String key) {
    final messages =
        formContentLocalizedValues[normalizeFormContentLocale(locale)] ??
        formContentLocalizedValues[defaultFormContentLocale]!;
    return messages[key] ??
        formContentLocalizedValues[defaultFormContentLocale]![key]!;
  }

  /// Returns the localized message for a missing required answer.
  static String requiredQuestion(String locale) =>
      text(locale, 'requiredQuestion');

  /// Returns a localized message describing the minimum text length.
  static String minCharacters(String locale, int count) =>
      text(locale, 'minCharacters').replaceAll('{count}', '$count');

  /// Returns a localized message describing the maximum text length.
  static String maxCharacters(String locale, int count) =>
      text(locale, 'maxCharacters').replaceAll('{count}', '$count');

  /// Returns a localized message describing the minimum number of selections.
  static String minChoices(String locale, int count) =>
      text(locale, 'minChoices').replaceAll('{count}', '$count');

  /// Returns a localized message describing the maximum number of selections.
  static String maxChoices(String locale, int count) =>
      text(locale, 'maxChoices').replaceAll('{count}', '$count');

  /// Returns a localized hint for the supplied minimum and maximum selection counts.
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

/// A group of surveys with shared locale and domain settings.
class Project {
  /// The identifier of this project. Null until the record has been saved.
  final int? id;

  /// The URL-friendly name used to look up this resource.
  final String slug;

  /// The custom host name assigned to the project, if any.
  final String? customDomain;

  /// The locale used when the respondent's preferred language is unavailable.
  final String defaultLocale;

  /// The locale codes enabled for this project.
  final List<String> supportedLocales;

  /// The name displayed for the project.
  final String name;

  /// The identifier of the administrator who created this resource.
  final String? createdByUserId;

  /// When this record was created.
  final DateTime createdAt;

  /// When this record was last updated.
  final DateTime updatedAt;

  /// Creates Project with the supplied values.
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

  /// Decodes Project from its JSON representation.
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

  /// Returns the JSON representation used by the API.
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

  /// Returns a copy with the supplied changes. Set clearCustomDomain to remove
  /// the custom domain instead of preserving it.
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

/// An administrator's view of a project and its surveys.
class ProjectWithSurveys {
  /// The project that contains the survey.
  final Project project;

  /// The surveys included in the project result.
  final List<Survey> surveys;

  /// Creates ProjectWithSurveys with the supplied values.
  const ProjectWithSurveys({required this.project, required this.surveys});

  /// Decodes ProjectWithSurveys from its JSON representation.
  factory ProjectWithSurveys.fromJson(Map<String, dynamic> json) =>
      ProjectWithSurveys(
        project: _object(json['project'], Project.fromJson),
        surveys: _objectList(json['surveys'], Survey.fromJson),
      );
}

/// A public project and the surveys available to respondents.
class PublicProject {
  /// The project that contains the survey.
  final Project project;

  /// The surveys included in the project result.
  final List<Survey> surveys;

  /// Creates PublicProject with the supplied values.
  const PublicProject({required this.project, required this.surveys});

  /// Decodes PublicProject from its JSON representation.
  factory PublicProject.fromJson(Map<String, dynamic> json) => PublicProject(
    project: _object(json['project'], Project.fromJson),
    surveys: _objectList(json['surveys'], Survey.fromJson),
  );
}

/// A form's localized content, availability, and submission settings.
class Survey {
  /// The identifier of this survey. Null until the record has been saved.
  final int? id;

  /// The identifier of the project containing the survey.
  final int projectId;

  /// The URL-friendly name used to look up this resource.
  final String slug;

  /// Survey titles indexed by locale code.
  final LocalizedText titleTranslations;

  /// Survey descriptions indexed by locale code.
  final LocalizedText descriptionTranslations;

  /// The current publication state of the survey.
  final SurveyStatus status;

  /// Whether the survey is available through its public web page.
  final bool webEnabled;

  /// Whether submissions may receive an adaptive follow-up interview.
  final bool followUpEnabled;

  /// Admin-authored instructions included in AI follow-up generation.
  final String? followUpPrompt;

  /// Persisted admin setting. Use [captchaRequired] for submission behavior.
  final bool captchaConfigurationEnabled;

  /// The configured CAPTCHA preference. Use captchaRequired for submission behavior.
  @Deprecated('Use captchaRequired for submission behavior.')
  bool get captchaEnabled => captchaConfigurationEnabled;

  /// Whether this client must supply a CAPTCHA token for this survey.
  final bool captchaRequired;

  /// The identifier of the administrator who created this resource.
  final String? createdByUserId;

  /// When this record was created.
  final DateTime createdAt;

  /// When this record was last updated.
  final DateTime updatedAt;

  /// When the survey begins accepting responses, if scheduled.
  final DateTime? startsAt;

  /// When the survey stops accepting responses, if scheduled.
  final DateTime? endsAt;

  /// Creates Survey with the supplied values.
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

  /// Decodes Survey from its JSON representation.
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

  /// Returns the JSON representation used by the API.
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

  /// Returns a copy with the supplied changes. Set clearFollowUpPrompt to remove
  /// the follow-up instructions instead of preserving them.
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

  /// Returns the survey title for the requested locale with translation fallback.
  String titleFor(String locale) => titleTranslations.valueFor(locale);

  /// Returns the survey description for the requested locale with translation fallback.
  String descriptionFor(String locale) =>
      descriptionTranslations.valueFor(locale);

  /// The survey title in the default form content locale.
  String get title => titleFor(defaultFormContentLocale);

  /// The survey description in the default form content locale, or null when empty.
  String? get description {
    final value = descriptionFor(defaultFormContentLocale);
    return value.trim().isEmpty ? null : value;
  }
}

/// A survey question with input constraints and visibility settings.
class Question {
  /// The identifier of this question. Null until the record has been saved.
  final int? id;

  /// The identifier of the associated survey.
  final int surveyId;

  /// Display text indexed by locale code.
  final LocalizedText textTranslations;

  /// The input format used to collect the answer.
  final QuestionType type;

  /// The position of this item in its ordered question or choice list.
  final int orderIndex;

  /// Whether the respondent must answer this question.
  final bool isRequired;

  /// Input hints indexed by locale code.
  final LocalizedText placeholderTranslations;

  /// The minimum accepted text length, or null when no minimum is set.
  final int? minLength;

  /// The maximum accepted text length, or null when no maximum is set.
  final int? maxLength;

  /// The minimum number of choices or uploaded files required, if set.
  final int? minSelected;

  /// The maximum number of choices or uploaded files allowed, if set.
  final int? maxSelected;

  /// Whether all visibility rules or any one rule must match.
  final VisibilityConditionMode visibilityConditionMode;

  /// Whether the question is marked as deleted.
  final bool isDeleted;

  /// Creates Question with the supplied values.
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

  /// Decodes Question from its JSON representation.
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

  /// Returns the JSON representation used by the API.
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

  /// Returns a copy with the supplied changes. Omit optional constraints to preserve them
  /// or pass null to clear them.
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

  /// Returns display text for the requested locale with translation fallback.
  String textFor(String locale) => textTranslations.valueFor(locale);

  /// Returns the localized input hint, or null when the resolved hint is empty.
  String? placeholderFor(String locale) {
    final value = placeholderTranslations.valueFor(locale);
    return value.trim().isEmpty ? null : value;
  }

  /// The display text in the default form content locale.
  String get text => textFor(defaultFormContentLocale);

  /// The input hint in the default form content locale, or null when empty.
  String? get placeholder => placeholderFor(defaultFormContentLocale);
}

/// A condition on another answer that controls question visibility.
class QuestionVisibilityRule {
  /// The identifier of this question visibility rule. Null until the record has been
  /// saved.
  final int? id;

  /// The identifier of the associated survey.
  final int surveyId;

  /// The identifier of the question whose visibility is controlled.
  final int targetQuestionId;

  /// The identifier of the question whose answer is tested.
  final int sourceQuestionId;

  /// The comparison applied to the source answer.
  final VisibilityOperator operator;

  /// The text or choice identifier to compare with the source answer.
  final Object? value;

  /// When this record was created.
  final DateTime? createdAt;

  /// When this record was last updated.
  final DateTime? updatedAt;

  /// Creates QuestionVisibilityRule with the supplied values.
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

  /// Decodes QuestionVisibilityRule from its JSON representation.
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

  /// Returns the JSON representation used by the API.
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

  /// Returns a copy with the supplied changes. Set clearValue to remove the
  /// comparison value instead of preserving it.
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

/// A localized answer option belonging to a choice question.
class Choice {
  /// The identifier of this choice. Null until the record has been saved.
  final int? id;

  /// The identifier of the associated question.
  final int questionId;

  /// Display text indexed by locale code.
  final LocalizedText textTranslations;

  /// The position of this item in its ordered question or choice list.
  final int orderIndex;

  /// An optional application-defined value for this choice.
  final String? value;

  /// Creates Choice with the supplied values.
  const Choice({
    this.id,
    required this.questionId,
    required this.textTranslations,
    required this.orderIndex,
    this.value,
  });

  /// Decodes Choice from its JSON representation.
  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
    id: json['id'] == null ? null : _int(json['id']),
    questionId: _int(json['questionId']),
    textTranslations: LocalizedText.fromJson(json['textTranslations']),
    orderIndex: _int(json['orderIndex']),
    value: _optionalString(json['value']),
  );

  /// Returns the JSON representation used by the API.
  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'questionId': questionId,
    'textTranslations': textTranslations.toJson(),
    'orderIndex': orderIndex,
    'value': value,
  });

  /// Returns a copy with the supplied non-null values replacing the current values.
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

  /// Returns display text for the requested locale with translation fallback.
  String textFor(String locale) => textTranslations.valueFor(locale);

  /// The display text in the default form content locale.
  String get text => textFor(defaultFormContentLocale);
}

/// A question definition and its choices for creation or AI generation.
class QuestionWithChoices {
  /// Display text indexed by locale code.
  final LocalizedText textTranslations;

  /// The input format used to collect the answer.
  final QuestionType type;

  /// Whether the respondent must answer this question.
  final bool isRequired;

  /// Input hints indexed by locale code.
  final LocalizedText placeholderTranslations;

  /// The minimum accepted text length, or null when no minimum is set.
  final int? minLength;

  /// The maximum accepted text length, or null when no maximum is set.
  final int? maxLength;

  /// The minimum number of choices or uploaded files required, if set.
  final int? minSelected;

  /// The maximum number of choices or uploaded files allowed, if set.
  final int? maxSelected;

  /// Whether all visibility rules or any one rule must match.
  final VisibilityConditionMode visibilityConditionMode;

  /// Localized text for each choice in display order.
  final List<LocalizedText> choiceTranslations;

  /// Creates QuestionWithChoices with the supplied values.
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

  /// Decodes QuestionWithChoices from its JSON representation.
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

  /// Returns the JSON representation used by the API.
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

  /// The display text in the default form content locale.
  String get text => textTranslations.valueFor(defaultFormContentLocale);

  /// The input hint in the default form content locale, or null when empty.
  String? get placeholder {
    final value = placeholderTranslations.valueFor(defaultFormContentLocale);
    return value.trim().isEmpty ? null : value;
  }

  /// The choice labels in the default form content locale.
  List<String> get choices => choiceTranslations
      .map((translations) => translations.valueFor(defaultFormContentLocale))
      .toList();
}
