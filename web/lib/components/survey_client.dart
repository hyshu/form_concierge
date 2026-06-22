import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../state/survey_state.dart';
import '../state/auth_state.dart';
import '../utils/anonymous_storage.dart';
import '../utils/device_info.dart';
import '../utils/validation.dart';
import 'survey_loading.dart';
import 'survey_error.dart';
import 'survey_completed.dart';
import 'survey_content.dart';
import 'auth/auth_view.dart';

@client
class SurveyClient extends StatefulComponent {
  const SurveyClient({
    required this.surveyJson,
    required this.questionsJson,
    required this.choicesByQuestionJson,
    required this.serverUrl,
    super.key,
  });

  final Map<String, dynamic> surveyJson;
  final List<Map<String, dynamic>> questionsJson;
  final Map<String, List<Map<String, dynamic>>> choicesByQuestionJson;
  final String serverUrl;

  @override
  State<SurveyClient> createState() => SurveyClientState();
}

class SurveyClientState extends State<SurveyClient> {
  late Survey _survey;
  late List<Question> _questions;
  late Map<int, List<Choice>> _choicesByQuestion;
  late Client _client;
  late String _anonymousTokenStorageKey;

  SurveyViewState _viewState = SurveyViewState.ready;
  SurveyAuthState _authState = const SurveyAuthState();
  Map<int, dynamic> _answers = {};
  Map<int, String> _validationErrors = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Decode data passed from server
    _survey = Survey.fromJson(component.surveyJson);
    _questions =
        component.questionsJson.map((j) => Question.fromJson(j)).toList();
    _choicesByQuestion = component.choicesByQuestionJson.map(
      (k, v) =>
          MapEntry(int.parse(k), v.map((j) => Choice.fromJson(j)).toList()),
    );

    // Initialize client
    _client = Client(component.serverUrl);
    _anonymousTokenStorageKey =
        'form_concierge.anonymous_token.${component.serverUrl}.${_survey.slug}';
    final savedToken = readAnonymousToken(_anonymousTokenStorageKey);
    if (savedToken != null && savedToken.isNotEmpty) {
      _client.anonymous.useToken(savedToken);
    }

    _ensureAnonymousAccount();
  }

  Future<bool> _ensureAnonymousAccount() async {
    if (_client.anonymous.isAuthenticated) return true;
    try {
      final session = await _client.anonymous.createAccount();
      writeAnonymousToken(_anonymousTokenStorageKey, session.token);
      return true;
    } on Exception catch (_) {
      setState(() {
        _viewState = SurveyViewState.error;
        _errorMessage = 'Failed to start anonymous session.';
      });
      return false;
    }
  }

  void _updateAnswer(int questionId, dynamic value) {
    setState(() {
      _answers = Map.from(_answers)..[questionId] = value;
      _validationErrors = Map.from(_validationErrors)..remove(questionId);
    });
  }

  Future<void> _submit() async {
    final errors = validateAnswers(_answers, _questions);

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

      final answers = buildAnswers(_answers, _questions);
      await _client.survey.submitResponse(
        surveyId: _survey.id!,
        answers: answers,
        deviceInfo: _deviceInfo(),
      );

      setState(() {
        _viewState = SurveyViewState.completed;
      });
    } catch (e) {
      setState(() {
        _viewState = SurveyViewState.ready;
        _errorMessage = 'Failed to submit survey. Please try again.';
      });
    }
  }

  DeviceInfo _deviceInfo() {
    return buildDeviceInfo();
  }

  void _onAuthSuccess() {
    setState(() {
      _authState = _authState.copyWith(isAuthenticated: true);
      _viewState = SurveyViewState.ready;
    });
  }

  void _onAuthStateChanged(SurveyAuthState newState) {
    setState(() {
      _authState = newState;
    });
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'survey-wrapper', [
      switch (_viewState) {
        SurveyViewState.loading => const SurveyLoading(),
        SurveyViewState.error => SurveyError(
            message: _errorMessage ?? 'An error occurred',
            onRetry: () => setState(() => _viewState = SurveyViewState.ready),
          ),
        SurveyViewState.authRequired => AuthView(
            client: _client,
            authState: _authState,
            onAuthStateChanged: _onAuthStateChanged,
            onAuthSuccess: _onAuthSuccess,
          ),
        SurveyViewState.ready || SurveyViewState.submitting => SurveyContent(
            survey: _survey,
            questions: _questions,
            choicesByQuestion: _choicesByQuestion,
            answers: _answers,
            validationErrors: _validationErrors,
            errorMessage: _errorMessage,
            isSubmitting: _viewState == SurveyViewState.submitting,
            onAnswerChanged: _updateAnswer,
            onSubmit: _submit,
          ),
        SurveyViewState.completed => SurveyCompleted(survey: _survey),
      },
    ]);
  }
}
