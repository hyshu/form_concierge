import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';
import '../../../../core/capsules/manager_operation.dart';

/// State for the question list.
class QuestionListState {
  final List<Question> questions;
  final Map<int, List<Choice>> choicesByQuestion;
  final List<QuestionVisibilityRule> visibilityRules;
  final bool isLoading;
  final String? error;

  const QuestionListState({
    this.questions = const [],
    this.choicesByQuestion = const {},
    this.visibilityRules = const [],
    this.isLoading = true,
    this.error,
  });

  factory QuestionListState.initial() => const QuestionListState();

  QuestionListState copyWith({
    List<Question>? questions,
    Map<int, List<Choice>>? choicesByQuestion,
    List<QuestionVisibilityRule>? visibilityRules,
    bool? isLoading,
    String? error,
  }) => QuestionListState(
    questions: questions ?? this.questions,
    choicesByQuestion: choicesByQuestion ?? this.choicesByQuestion,
    visibilityRules: visibilityRules ?? this.visibilityRules,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

/// Capsule using keyed state pattern for per-survey question lists.
KeyedStateAccessors<int, QuestionListState> questionListStateCapsule(
  CapsuleHandle use,
) => createKeyedState(use, QuestionListState.initial);

/// Capsule that provides the question list manager.
QuestionListManager questionListManagerCapsule(CapsuleHandle use) {
  final (getState, setState) = use(questionListStateCapsule);
  final client = use(clientCapsule);

  return QuestionListManager(
    getState: getState,
    setState: setState,
    client: client,
  );
}

/// Manager class for question list operations.
class QuestionListManager {
  final QuestionListState Function(int surveyId) getState;
  final void Function(int surveyId, QuestionListState state) _setState;
  final Client _client;

  QuestionListManager({
    required this.getState,
    required this._setState,
    required this._client,
  });

  /// Load all questions for a survey.
  Future<void> loadQuestions(int surveyId) async {
    _setState(
      surveyId,
      getState(surveyId).copyWith(isLoading: true, error: null),
    );
    try {
      final questions = await _client.questionAdmin.getForSurvey(surveyId);

      final choicesByQuestion = await _client.questionAdmin
          .getChoicesByQuestion(questions);
      final visibilityRules = await _client.surveyAdmin.getVisibilityRules(
        surveyId,
      );

      _setState(
        surveyId,
        getState(surveyId).copyWith(
          questions: questions,
          choicesByQuestion: choicesByQuestion,
          visibilityRules: visibilityRules,
          isLoading: false,
        ),
      );
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isLoading: false,
          error: 'Failed to load questions: $e',
        ),
      );
    }
  }

  /// Create a new question.
  Future<Question?> createQuestion({
    required int surveyId,
    required LocalizedText textTranslations,
    required QuestionType type,
    bool isRequired = true,
    required LocalizedText placeholderTranslations,
    int? minLength,
    int? maxLength,
    int? minSelected,
    int? maxSelected,
    VisibilityConditionMode visibilityConditionMode =
        VisibilityConditionMode.all,
  }) => _runAndReload(
    surveyId,
    () {
      final question = Question(
        surveyId: surveyId,
        textTranslations: textTranslations,
        type: type,
        orderIndex: getState(surveyId).questions.length,
        isRequired: isRequired,
        placeholderTranslations: placeholderTranslations,
        minLength: minLength,
        maxLength: maxLength,
        minSelected: minSelected,
        maxSelected: maxSelected,
        visibilityConditionMode: visibilityConditionMode,
      );
      return _client.questionAdmin.create(question);
    },
    'Failed to create question',
  );

  /// Update an existing question.
  Future<Question?> updateQuestion(Question question) => _runAndReload(
    question.surveyId,
    () => _client.questionAdmin.update(question),
    'Failed to update question',
  );

  /// Delete a question.
  Future<bool> deleteQuestion(int surveyId, int questionId) =>
      _runBoolAndReload(
        surveyId,
        () => _client.questionAdmin.delete(questionId),
        'Failed to delete question',
      );

  /// Reorder questions.
  Future<bool> reorderQuestions(int surveyId, List<int> questionIds) =>
      _runBoolAndReload(
        surveyId,
        () => _client.questionAdmin.reorder(surveyId, questionIds),
        'Failed to reorder questions',
      );

  /// Create a new choice for a question.
  Future<Choice?> createChoice({
    required int questionId,
    required int surveyId,
    required LocalizedText textTranslations,
  }) => _runAndReload(
    surveyId,
    () {
      final choice = Choice(
        questionId: questionId,
        textTranslations: textTranslations,
        orderIndex:
            getState(surveyId).choicesByQuestion[questionId]?.length ?? 0,
      );
      return _client.choiceAdmin.create(choice);
    },
    'Failed to create choice',
  );

  /// Update a choice.
  Future<Choice?> updateChoice(
    Choice choice,
    int surveyId,
  ) => _runAndReload(
    surveyId,
    () => _client.choiceAdmin.update(choice),
    'Failed to update choice',
  );

  /// Delete a choice.
  Future<bool> deleteChoice(int choiceId, int surveyId) => _runBoolAndReload(
    surveyId,
    () => _client.choiceAdmin.delete(choiceId),
    'Failed to delete choice',
  );

  Future<bool> saveVisibilityRules({
    required int surveyId,
    required Question targetQuestion,
    required VisibilityConditionMode conditionMode,
    required List<QuestionVisibilityRule> targetRules,
  }) async {
    try {
      final updatedQuestion = targetQuestion.copyWith(
        visibilityConditionMode: conditionMode,
      );
      await _client.questionAdmin.update(updatedQuestion);
      final currentRules = getState(surveyId).visibilityRules;
      final otherRules = currentRules.where(
        (rule) => rule.targetQuestionId != targetQuestion.id,
      );
      await _client.surveyAdmin.replaceVisibilityRules(
        surveyId,
        [...otherRules, ...targetRules],
      );
      await loadQuestions(surveyId);
      return true;
    } on Exception catch (e) {
      _setError(surveyId, 'Failed to save visibility rules: $e');
      return false;
    }
  }

  Future<T?> _runAndReload<T>(
    int surveyId,
    Future<T> Function() action,
    String errorMessage,
  ) => runAndReload(
    action: action,
    reload: () => loadQuestions(surveyId),
    setError: (error) => _setError(surveyId, error),
    errorMessage: errorMessage,
  );

  Future<bool> _runBoolAndReload(
    int surveyId,
    Future<void> Function() action,
    String errorMessage,
  ) => runVoidAndReload(
    action: action,
    reload: () => loadQuestions(surveyId),
    setError: (error) => _setError(surveyId, error),
    errorMessage: errorMessage,
  );

  /// Clear error for a survey.
  void clearError(int surveyId) =>
      _setState(surveyId, getState(surveyId).copyWith(error: null));

  void _setError(int surveyId, String error) =>
      _setState(surveyId, getState(surveyId).copyWith(error: error));
}
