import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:universal_web/web.dart' as web;

import '../state/survey_state.dart';
import '../utils/anonymous_storage.dart';
import '../utils/device_info.dart';
import '../utils/preferred_locales.dart';
import '../utils/ssr_payload.dart';
import '../utils/turnstile.dart';
import '../utils/validation.dart';
import 'survey_loading.dart';
import 'survey_error.dart';
import 'survey_completed.dart';
import 'survey_content.dart';
import 'turnstile_captcha.dart';
import 'not_found_page.dart';

class SurveyClient extends StatefulComponent {
  const SurveyClient({
    required this.serverUrl,
    this.surveyJson,
    this.questionsJson = const [],
    this.visibilityRulesJson = const [],
    this.choicesByQuestionJson = const {},
    this.projectJson,
    this.projectSlug,
    this.surveySlug,
    this.surveyId,
    this.domain,
    super.key,
  });

  final Map<String, dynamic>? projectJson;
  final Map<String, dynamic>? surveyJson;
  final List<Map<String, dynamic>> questionsJson;
  final List<Map<String, dynamic>> visibilityRulesJson;
  final Map<String, List<Map<String, dynamic>>> choicesByQuestionJson;
  final String serverUrl;
  final String? projectSlug;
  final String? surveySlug;
  final int? surveyId;
  final String? domain;

  @override
  State<SurveyClient> createState() => SurveyClientState();
}

class SurveyClientState extends State<SurveyClient> {
  late Client _client;
  Project? _project;
  Survey? _survey;
  List<Question> _questions = [];
  List<QuestionVisibilityRule> _visibilityRules = [];
  Map<int, List<Choice>> _choicesByQuestion = {};
  String? _anonymousTokenStorageKey;
  String? _turnstileSiteKey;
  String _locale = defaultFormContentLocale;

  SurveyViewState _viewState = SurveyViewState.loading;
  AnswerValues _answers = {};
  ValidationErrors _validationErrors = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _client = Client(component.serverUrl);

    final surveyJson = component.surveyJson;
    if (surveyJson == null) {
      final payload = readSsrSurveyPayload(
        slug: component.projectSlug,
        domain: component.domain,
      );
      if (payload != null) {
        try {
          _hydratePayload(payload);
          if (_viewState == SurveyViewState.loading) {
            _viewState = SurveyViewState.ready;
          }
          // Restore saved token only — create on submit (lazy).
          _restoreAnonymousToken();
        } on FormatException {
          // Bad SSR payload must not white-screen; fall back to live API load.
          _loadSurvey();
        }
        return;
      }

      _loadSurvey();
      return;
    }

    try {
      _hydrateSurvey(
        Project.fromJson(component.projectJson!),
        Survey.fromJson(surveyJson),
        component.questionsJson.map((j) => Question.fromJson(j)).toList(),
        component.visibilityRulesJson
            .map((j) => QuestionVisibilityRule.fromJson(j))
            .toList(),
        component.choicesByQuestionJson.map(
          (k, v) =>
              MapEntry(int.parse(k), v.map((j) => Choice.fromJson(j)).toList()),
        ),
      );
      _viewState = SurveyViewState.ready;
      _restoreAnonymousToken();
    } on FormatException {
      _loadSurvey();
    }
  }

  void _hydratePayload(Map<String, dynamic> payload) {
    final project = Project.fromJson(
      Map<String, dynamic>.from(payload['project'] as Map),
    );
    if (payload['survey'] == null) {
      _project = project;
      _locale = _resolveLocale(project);
      _viewState = SurveyViewState.notFound;
      return;
    }

    final choicesPayload = payload['choicesByQuestion'];
    if (choicesPayload != null && choicesPayload is! Map) {
      throw const FormatException('Expected choicesByQuestion object');
    }
    final choicesByQuestion = (choicesPayload as Map? ?? const {})
        .map<int, List<Choice>>((key, value) {
          if (key is! String) {
            throw FormatException(
              'Expected choice question id key, got ${key.runtimeType}',
            );
          }
          if (value is! List) {
            throw FormatException(
              'Expected choice list, got ${value.runtimeType}',
            );
          }
          return MapEntry(
            int.parse(key),
            value.map((item) {
              if (item is! Map) {
                throw FormatException(
                  'Expected choice object, got ${item.runtimeType}',
                );
              }
              return Choice.fromJson(Map<String, dynamic>.from(item));
            }).toList(),
          );
        });

    final siteKey = payload['turnstileSiteKey'];
    if (siteKey is String && siteKey.isNotEmpty) {
      _turnstileSiteKey = siteKey;
    }

    _hydrateSurvey(
      project,
      Survey.fromJson(Map<String, dynamic>.from(payload['survey'] as Map)),
      (payload['questions'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Question.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      (payload['visibilityRules'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => QuestionVisibilityRule.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      choicesByQuestion,
    );
  }

  Future<void> _loadSurvey() async {
    setState(() {
      _viewState = SurveyViewState.loading;
      _errorMessage = null;
    });

    try {
      final project = await _resolveProject();
      if (project == null || project.surveys.isEmpty) {
        setState(() => _viewState = SurveyViewState.notFound);
        return;
      }

      final survey = _selectSurvey(project);
      if (survey == null) {
        setState(() {
          _viewState = SurveyViewState.notFound;
        });
        return;
      }

      final questions = await _client.survey.getQuestionsForSurvey(survey.id!);
      final visibilityRules = await _client.survey.getVisibilityRulesForSurvey(
        survey.id!,
      );
      final choicesByQuestion = await _client.survey.getChoicesByQuestion(
        questions,
      );
      final turnstileSiteKey = survey.captchaRequired
          ? await _loadTurnstileSiteKey()
          : null;

      setState(() {
        _turnstileSiteKey = turnstileSiteKey;
        _hydrateSurvey(
          project.project,
          survey,
          questions,
          visibilityRules,
          choicesByQuestion,
        );
        _viewState = SurveyViewState.ready;
      });
      // Restore only; create anonymously on submit to avoid orphan accounts.
      _restoreAnonymousToken();
    } on Exception catch (error) {
      setState(() {
        _viewState = SurveyViewState.error;
        _errorMessage = error is ApiException
            ? error.message
            : FormContentMessages.text(_locale, 'errorOccurred');
      });
    }
  }

  Future<String?> _loadTurnstileSiteKey() async {
    try {
      final config = await _client.config.getPublicConfig();
      final key = config.turnstileSiteKey?.trim();
      return key == null || key.isEmpty ? null : key;
    } on Exception {
      return null;
    }
  }

  Future<PublicProject?> _resolveProject() async {
    final slug = component.projectSlug?.trim();
    if (slug != null && slug.isNotEmpty) {
      final project = await _client.survey.getProjectBySlug(slug);
      if (project != null) return project;
    }

    final domain = component.domain?.trim().toLowerCase();
    if (domain != null && domain.isNotEmpty) {
      return _client.survey.getProjectByDomain(domain);
    }

    return null;
  }

  Survey? _selectSurvey(PublicProject project) {
    final surveySlug = component.surveySlug?.trim();
    if (surveySlug != null && surveySlug.isNotEmpty) {
      for (final survey in project.surveys) {
        if (survey.slug == surveySlug) return survey;
      }
      return null;
    }
    final surveyId = component.surveyId;
    if (surveyId == null) {
      return project.surveys.length == 1 ? project.surveys.first : null;
    }
    for (final survey in project.surveys) {
      if (survey.id == surveyId) return survey;
    }
    return null;
  }

  void _hydrateSurvey(
    Project project,
    Survey survey,
    List<Question> questions,
    List<QuestionVisibilityRule> visibilityRules,
    Map<int, List<Choice>> choicesByQuestion,
  ) {
    _project = project;
    _survey = survey;
    _locale = _resolveLocale(project);
    _questions = questions;
    _visibilityRules = visibilityRules;
    _choicesByQuestion = choicesByQuestion;
    _anonymousTokenStorageKey =
        'form_concierge.anonymous_token.${component.serverUrl}.${project.slug}.${survey.id}';
  }

  String _resolveLocale(Project project) => resolveFormContentLocale(
    preferredLocales: browserPreferredLocales(),
    supportedLocales: project.supportedLocales,
    defaultLocale: project.defaultLocale,
  );

  void _restoreAnonymousToken() {
    final storageKey = _anonymousTokenStorageKey;
    if (storageKey == null) return;
    if (_client.anonymous.isAuthenticated) return;
    final savedToken = readAnonymousToken(storageKey);
    if (savedToken != null && savedToken.isNotEmpty) {
      _client.anonymous.useToken(savedToken);
    }
  }

  Future<bool> _ensureAnonymousAccount() async {
    try {
      await _ensureAuthenticated();
      return true;
    } on Exception catch (_) {
      setState(() {
        _viewState = SurveyViewState.error;
        _errorMessage = FormContentMessages.text(
          _locale,
          'anonymousStartFailed',
        );
      });
      return false;
    }
  }

  /// Create/restore anonymous session for media upload and submit.
  Future<void> _ensureAuthenticated() async {
    final storageKey = _anonymousTokenStorageKey;
    if (storageKey == null) {
      throw StateError('Anonymous storage key is not ready');
    }
    _restoreAnonymousToken();
    if (_client.anonymous.isAuthenticated) return;
    final session = await _client.anonymous.createAccount();
    writeAnonymousToken(storageKey, session.token);
  }

  void _updateAnswer(int questionId, AnswerValue value) {
    setState(() {
      final change = applyAnswerChange(
        answers: _answers,
        validationErrors: _validationErrors,
        questions: _questions,
        visibilityRules: _visibilityRules,
        questionId: questionId,
        value: value,
      );
      _answers = change.answers;
      _validationErrors = change.validationErrors;
    });
  }

  /// Move keyboard/screen-reader focus to the first invalid question.
  void _focusFirstError(List<Question> visible, ValidationErrors errors) {
    for (final question in visible) {
      if (!errors.containsKey(question.id)) continue;
      final card = web.document.getElementById('question_card_${question.id}');
      if (card == null) return;
      card.scrollIntoView();
      final target = card.querySelector('input, textarea, button');
      if (target != null) (target as web.HTMLElement).focus();
      return;
    }
  }

  Future<void> _submit() async {
    final survey = _survey;
    if (survey == null) return;
    if (_viewState == SurveyViewState.submitting) return;

    final visible = resolveVisibleQuestions(
      _questions,
      _visibilityRules,
      _answers,
    );
    final errors = validateAnswers(_answers, visible, _locale);

    if (errors.isNotEmpty) {
      setState(() {
        _validationErrors = errors;
        _errorMessage = null;
      });
      _focusFirstError(visible, errors);
      return;
    }

    // Require CAPTCHA before entering "submitting" so a missing check never
    // leaves the button stuck on a spinner.
    final captchaRequired =
        survey.captchaRequired &&
        _turnstileSiteKey != null &&
        _turnstileSiteKey!.isNotEmpty;
    final captchaToken = captchaRequired ? getTurnstileResponse() : null;
    if (captchaRequired && (captchaToken == null || captchaToken.isEmpty)) {
      setState(() {
        _errorMessage = FormContentMessages.text(_locale, 'captchaRequired');
      });
      _focusCaptcha();
      return;
    }

    setState(() {
      _viewState = SurveyViewState.submitting;
      _errorMessage = null;
    });

    try {
      final hasAnonymousAccount = await _ensureAnonymousAccount();
      if (!hasAnonymousAccount) return;

      final answers = buildAnswers(_answers, visible);
      final idempotencyKey = generateIdempotencyKey();
      try {
        await _client.survey.submitResponse(
          surveyId: survey.id!,
          answers: answers,
          deviceInfo: _deviceInfo(),
          captchaToken: captchaToken,
          idempotencyKey: idempotencyKey,
        );
      } on ApiException catch (e) {
        // Stale localStorage token (e.g. after DB rebuild) → recreate once.
        if (e.statusCode != 401) rethrow;
        await _resetAnonymousAccount();
        final recreated = await _ensureAnonymousAccount();
        if (!recreated) return;
        await _client.survey.submitResponse(
          surveyId: survey.id!,
          answers: answers,
          deviceInfo: _deviceInfo(),
          captchaToken: captchaToken,
          idempotencyKey: idempotencyKey,
        );
      }

      if (!mounted) return;
      setState(() {
        _viewState = SurveyViewState.completed;
      });
    } on Object catch (_) {
      // Catch Errors from JS interop as well as Exceptions, otherwise the
      // UI can remain stuck on SurveyViewState.submitting forever.
      resetTurnstile();
      if (!mounted) return;
      setState(() {
        _viewState = SurveyViewState.ready;
        _errorMessage = FormContentMessages.text(_locale, 'submitFailed');
      });
    }
  }

  void _focusCaptcha() {
    final el = web.document.getElementById(TurnstileCaptcha.containerId);
    el?.scrollIntoView();
  }

  Future<void> _resetAnonymousAccount() async {
    final storageKey = _anonymousTokenStorageKey;
    _client.anonymous.clear();
    if (storageKey != null) {
      clearAnonymousToken(storageKey);
    }
  }

  DeviceInfo _deviceInfo() => buildDeviceInfo();

  @override
  Component build(context) {
    final survey = _survey;
    final project = _project;
    final visibleQuestions = resolveVisibleQuestions(
      _questions,
      _visibilityRules,
      _answers,
    );
    return div(classes: 'survey-wrapper', [
      switch (_viewState) {
        SurveyViewState.loading => const SurveyLoading(),
        SurveyViewState.notFound => const NotFoundPage(),
        SurveyViewState.error => SurveyError(
          locale: _locale,
          message:
              _errorMessage ??
              FormContentMessages.text(_locale, 'errorOccurred'),
          onRetry: _loadSurvey,
        ),
        SurveyViewState.ready || SurveyViewState.submitting =>
          survey == null
              ? const NotFoundPage()
              : SurveyContent(
                  client: _client,
                  project: project!,
                  survey: survey,
                  questions: visibleQuestions,
                  choicesByQuestion: _choicesByQuestion,
                  answers: _answers,
                  validationErrors: _validationErrors,
                  errorMessage: _errorMessage,
                  locale: _locale,
                  isSubmitting: _viewState == SurveyViewState.submitting,
                  turnstileSiteKey: survey.captchaRequired
                      ? _turnstileSiteKey
                      : null,
                  onAnswerChanged: _updateAnswer,
                  onLocaleChanged: (locale) {
                    setState(() {
                      _locale = locale;
                      _validationErrors = {};
                      _errorMessage = null;
                    });
                  },
                  onSubmit: _submit,
                  ensureAuthenticated: _ensureAuthenticated,
                ),
        SurveyViewState.completed =>
          survey == null
              ? const NotFoundPage()
              : SurveyCompleted(survey: survey, locale: _locale),
      },
    ]);
  }
}
