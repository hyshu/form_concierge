import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../state/survey_state.dart';
import '../utils/anonymous_storage.dart';
import '../utils/device_info.dart';
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
    this.slug,
    this.domain,
    super.key,
  });

  final Map<String, dynamic>? surveyJson;
  final List<Map<String, dynamic>> questionsJson;
  final List<Map<String, dynamic>> visibilityRulesJson;
  final Map<String, List<Map<String, dynamic>>> choicesByQuestionJson;
  final String serverUrl;
  final String? slug;
  final String? domain;

  @override
  State<SurveyClient> createState() => SurveyClientState();
}

class SurveyClientState extends State<SurveyClient> {
  late Client _client;
  Survey? _survey;
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
      _loadSurvey();
      return;
    }

    _hydrateSurvey(
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

  Future<void> _loadSurvey() async {
    setState(() {
      _viewState = SurveyViewState.loading;
      _errorMessage = null;
    });

    try {
      final survey = await _resolveSurvey();
      if (survey == null) {
        setState(() => _viewState = SurveyViewState.notFound);
        return;
      }

      final questions = await _client.survey.getQuestionsForSurvey(survey.id!);
      final visibilityRules =
          await _client.survey.getVisibilityRulesForSurvey(survey.id!);
      final choicesByQuestion =
          await _client.survey.getChoicesByQuestion(questions);

      setState(() {
        _hydrateSurvey(
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

  Future<Survey?> _resolveSurvey() {
    final slug = component.slug?.trim();
    if (slug != null && slug.isNotEmpty) {
      return _client.survey.getBySlug(slug);
    }

    final domain = component.domain?.trim().toLowerCase();
    if (domain != null && domain.isNotEmpty) {
      return _client.survey.getByDomain(domain);
    }

    return Future.value(null);
  }

  void _hydrateSurvey(
    Survey survey,
    List<Question> questions,
    List<QuestionVisibilityRule> visibilityRules,
    Map<int, List<Choice>> choicesByQuestion,
  ) {
    _survey = survey;
    _locale = survey.defaultLocale;
    _questions = questions;
    _visibilityRules = visibilityRules;
    _choicesByQuestion = choicesByQuestion;
    _anonymousTokenStorageKey =
        'form_concierge.anonymous_token.${component.serverUrl}.${survey.slug}';
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
            ? const SurveyLoading()
            : SurveyContent(
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
