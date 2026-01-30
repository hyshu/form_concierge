import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../state/survey_state.dart';
import '../state/auth_state.dart';
import '../utils/answer_builder.dart';
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

    // Check auth requirement
    if (_survey.authRequirement == AuthRequirement.authenticated) {
      _checkAuthentication();
    }
  }

  Future<void> _checkAuthentication() async {
    // On web, check for stored session in localStorage
    // For now, just show auth form if authenticated is required
    setState(() {
      _viewState = SurveyViewState.authRequired;
    });
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
      final answers = buildAnswers(_answers, _questions);
      await _client.survey.submitResponse(
        surveyId: _survey.id!,
        answers: answers,
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
