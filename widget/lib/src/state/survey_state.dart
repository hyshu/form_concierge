import 'package:form_concierge_client/form_concierge_client.dart';

enum SurveyViewState { loading, ready, submitting, completed, error }

class SurveyState {
  final SurveyViewState viewState;
  final Survey? survey;
  final List<Question> questions;
  final List<QuestionVisibilityRule> visibilityRules;
  final Map<int, List<Choice>> choicesByQuestion;
  final Map<int, dynamic> answers;
  final Map<int, String> validationErrors;
  final String? errorMessage;

  const SurveyState({
    this.viewState = SurveyViewState.loading,
    this.survey,
    this.questions = const [],
    this.visibilityRules = const [],
    this.choicesByQuestion = const {},
    this.answers = const {},
    this.validationErrors = const {},
    this.errorMessage,
  });

  SurveyState copyWith({
    SurveyViewState? viewState,
    Survey? survey,
    List<Question>? questions,
    List<QuestionVisibilityRule>? visibilityRules,
    Map<int, List<Choice>>? choicesByQuestion,
    Map<int, dynamic>? answers,
    Map<int, String>? validationErrors,
    String? errorMessage,
  }) {
    return SurveyState(
      viewState: viewState ?? this.viewState,
      survey: survey ?? this.survey,
      questions: questions ?? this.questions,
      visibilityRules: visibilityRules ?? this.visibilityRules,
      choicesByQuestion: choicesByQuestion ?? this.choicesByQuestion,
      answers: answers ?? this.answers,
      validationErrors: validationErrors ?? this.validationErrors,
      errorMessage: errorMessage,
    );
  }
}
