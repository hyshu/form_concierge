import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../state/survey_state.dart';
import '../utils/anonymous_storage.dart';
import '../utils/device_info.dart';
import '../utils/ssr_payload.dart';
import '../utils/validation.dart';
import 'survey_loading.dart';
import 'survey_error.dart';
import 'survey_completed.dart';
import 'survey_content.dart';
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
  final int? surveyId;
  final String? domain;

  @override
  State<SurveyClient> createState() => SurveyClientState();
}

class SurveyClientState extends State<SurveyClient> {
  late Client _client;
  Project? _project;
  Survey? _survey;
  List<Survey> _surveys = [];
  List<Question> _questions = [];
  List<QuestionVisibilityRule> _visibilityRules = [];
  Map<int, List<Choice>> _choicesByQuestion = {};
  String? _anonymousTokenStorageKey;
  String _locale = defaultFormContentLocale;

  SurveyViewState _viewState = SurveyViewState.loading;
  Map<int, dynamic> _answers = {};
  Map<int, String> _validationErrors = {};
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
        _hydratePayload(payload);
        _viewState = SurveyViewState.ready;
        _ensureAnonymousAccount();
        return;
      }

      _loadSurvey();
      return;
    }

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
    _ensureAnonymousAccount();
  }

  void _hydratePayload(Map<String, dynamic> payload) {
    final project = Project.fromJson(
      Map<String, dynamic>.from(payload['project'] as Map),
    );
    final surveys = (payload['surveys'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Survey.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    if (payload['survey'] == null) {
      _project = project;
      _surveys = surveys;
      _locale = project.defaultLocale;
      return;
    }

    final choicesByQuestion = (payload['choicesByQuestion'] as Map? ?? {})
        .map<String, List<Choice>>(
          (key, value) => MapEntry(
            key.toString(),
            (value as List? ?? const [])
                .whereType<Map>()
                .map((item) => Choice.fromJson(Map<String, dynamic>.from(item)))
                .toList(),
          ),
        )
        .map((key, value) => MapEntry(int.parse(key), value));

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
          _project = project.project;
          _surveys = project.surveys;
          _locale = project.project.defaultLocale;
          _viewState = SurveyViewState.ready;
        });
        return;
      }

      final questions = await _client.survey.getQuestionsForSurvey(survey.id!);
      final visibilityRules =
          await _client.survey.getVisibilityRulesForSurvey(survey.id!);
      final choicesByQuestion =
          await _client.survey.getChoicesByQuestion(questions);

      setState(() {
        _hydrateSurvey(
          project.project,
          survey,
          questions,
          visibilityRules,
          choicesByQuestion,
        );
        _viewState = SurveyViewState.ready;
      });
      await _ensureAnonymousAccount();
    } on Exception catch (error) {
      setState(() {
        _viewState = SurveyViewState.error;
        _errorMessage = error is ApiException
            ? error.message
            : FormContentMessages.text(_locale, 'errorOccurred');
      });
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
    _surveys = [survey];
    _locale = project.defaultLocale;
    _questions = questions;
    _visibilityRules = visibilityRules;
    _choicesByQuestion = choicesByQuestion;
    _anonymousTokenStorageKey =
        'form_concierge.anonymous_token.${component.serverUrl}.${project.slug}.${survey.id}';
  }

  Future<bool> _ensureAnonymousAccount() async {
    final storageKey = _anonymousTokenStorageKey;
    if (storageKey == null) return false;
    if (!_client.anonymous.isAuthenticated) {
      final savedToken = readAnonymousToken(storageKey);
      if (savedToken != null && savedToken.isNotEmpty) {
        _client.anonymous.useToken(savedToken);
      }
    }
    if (_client.anonymous.isAuthenticated) return true;
    try {
      final session = await _client.anonymous.createAccount();
      writeAnonymousToken(storageKey, session.token);
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

  void _updateAnswer(int questionId, dynamic value) {
    setState(() {
      final updatedAnswers = Map<int, dynamic>.from(_answers)
        ..[questionId] = value;
      final visible = resolveVisibleQuestions(
        _questions,
        _visibilityRules,
        updatedAnswers,
      );
      _answers = pruneHiddenAnswers(updatedAnswers, visible);
      _validationErrors = Map.from(_validationErrors)..remove(questionId);
    });
  }

  Future<void> _submit() async {
    final survey = _survey;
    if (survey == null) return;

    final visible = resolveVisibleQuestions(
      _questions,
      _visibilityRules,
      _answers,
    );
    final errors = validateAnswers(_answers, visible, _locale);

    if (errors.isNotEmpty) {
      setState(() {
        _validationErrors = errors;
      });
      return;
    }

    setState(() {
      _viewState = SurveyViewState.submitting;
    });

    try {
      final hasAnonymousAccount = await _ensureAnonymousAccount();
      if (!hasAnonymousAccount) return;

      final answers = buildAnswers(_answers, visible);
      await _client.survey.submitResponse(
        surveyId: survey.id!,
        answers: answers,
        deviceInfo: _deviceInfo(),
      );

      setState(() {
        _viewState = SurveyViewState.completed;
      });
    } on Exception catch (_) {
      setState(() {
        _viewState = SurveyViewState.ready;
        _errorMessage = FormContentMessages.text(_locale, 'submitFailed');
      });
    }
  }

  DeviceInfo _deviceInfo() {
    return buildDeviceInfo();
  }

  @override
  Component build(BuildContext context) {
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
            message: _errorMessage ??
                FormContentMessages.text(_locale, 'errorOccurred'),
            onRetry: _loadSurvey,
          ),
        SurveyViewState.ready || SurveyViewState.submitting => survey == null
            ? project == null
                ? const SurveyLoading()
                : _ProjectSurveyList(
                    project: project,
                    surveys: _surveys,
                    locale: _locale,
                  )
            : SurveyContent(
                project: project!,
                survey: survey,
                questions: visibleQuestions,
                choicesByQuestion: _choicesByQuestion,
                answers: _answers,
                validationErrors: _validationErrors,
                errorMessage: _errorMessage,
                locale: _locale,
                isSubmitting: _viewState == SurveyViewState.submitting,
                onAnswerChanged: _updateAnswer,
                onLocaleChanged: (locale) {
                  setState(() {
                    _locale = locale;
                    _validationErrors = {};
                    _errorMessage = null;
                  });
                },
                onSubmit: _submit,
              ),
        SurveyViewState.completed => survey == null
            ? const SurveyLoading()
            : SurveyCompleted(
                survey: survey,
                locale: _locale,
              ),
      },
    ]);
  }
}

class _ProjectSurveyList extends StatelessComponent {
  const _ProjectSurveyList({
    required this.project,
    required this.surveys,
    required this.locale,
  });

  final Project project;
  final List<Survey> surveys;
  final String locale;

  @override
  Component build(BuildContext context) {
    return div(classes: 'max-w-xl mx-auto', [
      div(
          classes:
              'bg-white rounded-xl shadow-md border border-slate-200 p-6 mb-6',
          [
            h1(classes: 'text-xl font-semibold text-slate-900', [
              Component.text(project.nameFor(locale)),
            ]),
            if ((project.description ?? '').isNotEmpty)
              p(classes: 'mt-2 text-sm text-slate-600 leading-relaxed', [
                Component.text(project.description!),
              ]),
          ]),
      div(classes: 'space-y-3', [
        for (final survey in surveys)
          a(
            [
              h2(classes: 'font-medium text-slate-900', [
                Component.text(survey.titleFor(locale)),
              ]),
              if (survey.descriptionFor(locale).trim().isNotEmpty)
                p(classes: 'mt-2 text-sm text-slate-600', [
                  Component.text(survey.descriptionFor(locale)),
                ]),
            ],
            href: '/${project.slug}/${survey.id}',
            classes:
                'block bg-white rounded-xl shadow-md border border-slate-200 p-5 hover:border-indigo-300',
          ),
      ]),
    ]);
  }
}
