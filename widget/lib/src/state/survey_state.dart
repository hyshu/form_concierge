import 'package:form_concierge_client/form_concierge_client.dart';

/// The current stage of loading, answering, or submitting a survey.
enum SurveyViewState {
  /// Survey data is being loaded.
  loading,

  /// The form is ready for answers.
  ready,

  /// The main survey response is being submitted.
  submitting,

  /// Adaptive follow-up questions are being generated.
  followUpLoading,

  /// The follow-up interview is ready for answers.
  followUp,

  /// Follow-up answers are being saved.
  followUpSubmitting,

  /// The survey flow has finished successfully.
  completed,

  /// An error prevents the survey from being displayed.
  error,
}

/// The survey data, answers, and progress used to render the form.
class SurveyState {
  /// The current loading, input, submission, or completion stage.
  final SurveyViewState viewState;

  /// The project that contains the survey.
  final Project? project;

  /// The survey displayed by this component or state.
  final Survey? survey;

  /// The survey questions in display order.
  final List<Question> questions;

  /// Conditions that determine which questions are visible.
  final List<QuestionVisibilityRule> visibilityRules;

  /// Available choices indexed by question identifier.
  final Map<int, List<Choice>> choicesByQuestion;

  /// The current answers indexed by question identifier.
  final AnswerValues answers;

  /// Validation messages indexed by question identifier.
  final ValidationErrors validationErrors;

  /// The error message to display, or null when there is no error.
  final String? errorMessage;

  /// The response returned after a successful submission, if any.
  final SurveyResponse? submittedResponse;

  /// The adaptive follow-up interview associated with the response.
  final FollowUp? followUp;

  /// Follow-up answers indexed by interview item identifier.
  final Map<String, dynamic> followUpAnswers;

  /// Validation messages indexed by follow-up item identifier.
  final Map<String, String> followUpValidationErrors;

  /// Creates SurveyState with the supplied values.
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

  /// Returns a copy with the supplied changes. The error message is cleared when
  /// errorMessage is omitted or null.
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
