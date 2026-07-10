import 'package:form_concierge_client/form_concierge_client.dart';

enum SurveyViewState {
  loading,
  ready,
  submitting,
  followUpLoading,
  followUp,
  followUpSubmitting,
  completed,
  error,
}

class SurveyState {
  final SurveyViewState viewState;
  final Project? project;
  final Survey? survey;
  final List<Question> questions;
  final List<QuestionVisibilityRule> visibilityRules;
  final Map<int, List<Choice>> choicesByQuestion;
  final AnswerValues answers;
  final ValidationErrors validationErrors;
  final String? errorMessage;
  final SurveyResponse? submittedResponse;
  final FollowUp? followUp;
  final Map<String, dynamic> followUpAnswers;
  final Map<String, String> followUpValidationErrors;

  const SurveyState({
    this.viewState = SurveyViewState.loading,
    this.project,
    this.survey,
    this.questions = const [],
    this.visibilityRules = const [],
    this.choicesByQuestion = const {},
    this.answers = const {},
    this.validationErrors = const {},
    this.errorMessage,
    this.submittedResponse,
    this.followUp,
    this.followUpAnswers = const {},
    this.followUpValidationErrors = const {},
  });

  SurveyState copyWith({
    SurveyViewState? viewState,
    Project? project,
    Survey? survey,
    List<Question>? questions,
    List<QuestionVisibilityRule>? visibilityRules,
    Map<int, List<Choice>>? choicesByQuestion,
    AnswerValues? answers,
    ValidationErrors? validationErrors,
    String? errorMessage,
    SurveyResponse? submittedResponse,
    FollowUp? followUp,
    Map<String, dynamic>? followUpAnswers,
    Map<String, String>? followUpValidationErrors,
  }) {
    return SurveyState(
      viewState: viewState ?? this.viewState,
      project: project ?? this.project,
      survey: survey ?? this.survey,
      questions: questions ?? this.questions,
      visibilityRules: visibilityRules ?? this.visibilityRules,
      choicesByQuestion: choicesByQuestion ?? this.choicesByQuestion,
      answers: answers ?? this.answers,
      validationErrors: validationErrors ?? this.validationErrors,
      errorMessage: errorMessage,
      submittedResponse: submittedResponse ?? this.submittedResponse,
      followUp: followUp ?? this.followUp,
      followUpAnswers: followUpAnswers ?? this.followUpAnswers,
      followUpValidationErrors:
          followUpValidationErrors ?? this.followUpValidationErrors,
    );
  }
}
