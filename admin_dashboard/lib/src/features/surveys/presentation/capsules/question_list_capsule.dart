import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';

/// State for the question list.
class QuestionListState {
  final List<Question> questions;
  final Map<int, List<Choice>> choicesByQuestion;
  final bool isLoading;
  final String? error;

  const QuestionListState({
    this.questions = const [],
    this.choicesByQuestion = const {},
    this.isLoading = false,
    this.error,
  });

  factory QuestionListState.initial() => const QuestionListState();

  QuestionListState copyWith({
    List<Question>? questions,
    Map<int, List<Choice>>? choicesByQuestion,
    bool? isLoading,
    String? error,
  }) => QuestionListState(
    questions: questions ?? this.questions,
    choicesByQuestion: choicesByQuestion ?? this.choicesByQuestion,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

/// Capsule using keyed state pattern for per-survey question lists.
KeyedStateAccessors<int, QuestionListState> questionListStateCapsule(
  CapsuleHandle use,
) {
  return createKeyedState(use, QuestionListState.initial);
}

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
    required void Function(int surveyId, QuestionListState state) setState,
    required Client client,
  }) : _setState = setState,
       _client = client;

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

      _setState(
        surveyId,
        getState(surveyId).copyWith(
          questions: questions,
          choicesByQuestion: choicesByQuestion,
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
    required String text,
    required QuestionType type,
    bool isRequired = true,
    String? placeholder,
  }) async {
    return _runAndReload(
      surveyId,
      () {
        final question = Question(
          surveyId: surveyId,
          text: text,
          type: type,
          orderIndex: getState(surveyId).questions.length,
          isRequired: isRequired,
          placeholder: placeholder,
        );
        return _client.questionAdmin.create(question);
      },
      'Failed to create question',
    );
  }

  /// Update an existing question.
  Future<Question?> updateQuestion(Question question) async {
    return _runAndReload(
      question.surveyId,
      () => _client.questionAdmin.update(question),
      'Failed to update question',
    );
  }

  /// Delete a question.
  Future<bool> deleteQuestion(int surveyId, int questionId) async {
    return _runBoolAndReload(
      surveyId,
      () => _client.questionAdmin.delete(questionId),
      'Failed to delete question',
    );
  }

  /// Reorder questions.
  Future<bool> reorderQuestions(int surveyId, List<int> questionIds) async {
    return _runBoolAndReload(
      surveyId,
      () => _client.questionAdmin.reorder(surveyId, questionIds),
      'Failed to reorder questions',
    );
  }

  /// Create a new choice for a question.
  Future<Choice?> createChoice({
    required int questionId,
    required int surveyId,
    required String text,
  }) async {
    return _runAndReload(
      surveyId,
      () {
        final choice = Choice(
          questionId: questionId,
          text: text,
          orderIndex:
              getState(surveyId).choicesByQuestion[questionId]?.length ?? 0,
        );
        return _client.choiceAdmin.create(choice);
      },
      'Failed to create choice',
    );
  }

  /// Update a choice.
  Future<Choice?> updateChoice(
    Choice choice,
    int surveyId,
  ) async {
    return _runAndReload(
      surveyId,
      () => _client.choiceAdmin.update(choice),
      'Failed to update choice',
    );
  }

  /// Delete a choice.
  Future<bool> deleteChoice(int choiceId, int surveyId) async {
    return _runBoolAndReload(
      surveyId,
      () => _client.choiceAdmin.delete(choiceId),
      'Failed to delete choice',
    );
  }

  Future<T?> _runAndReload<T>(
    int surveyId,
    Future<T> Function() action,
    String errorMessage,
  ) async {
    try {
      final result = await action();
      await loadQuestions(surveyId);
      return result;
    } on Exception catch (e) {
      _setError(surveyId, '$errorMessage: $e');
      return null;
    }
  }

  Future<bool> _runBoolAndReload(
    int surveyId,
    Future<void> Function() action,
    String errorMessage,
  ) async {
    final result = await _runAndReload(
      surveyId,
      () async {
        await action();
        return true;
      },
      errorMessage,
    );
    return result ?? false;
  }

  /// Clear error for a survey.
  void clearError(int surveyId) {
    _setState(surveyId, getState(surveyId).copyWith(error: null));
  }

  void _setError(int surveyId, String error) {
    _setState(surveyId, getState(surveyId).copyWith(error: error));
  }
}
