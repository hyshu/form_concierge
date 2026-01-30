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

      // Load choices for choice questions
      final choicesByQuestion = <int, List<Choice>>{};
      for (final question in questions) {
        if (question.type == QuestionType.singleChoice ||
            question.type == QuestionType.multipleChoice) {
          choicesByQuestion[question.id!] = await _client.questionAdmin
              .getChoicesForQuestion(question.id!);
        }
      }

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
    try {
      final question = Question(
        surveyId: surveyId,
        text: text,
        type: type,
        orderIndex: getState(surveyId).questions.length,
        isRequired: isRequired,
        placeholder: placeholder,
      );
      final created = await _client.questionAdmin.create(question);
      await loadQuestions(surveyId);
      return created;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          error: 'Failed to create question: $e',
        ),
      );
      return null;
    }
  }

  /// Update an existing question.
  Future<Question?> updateQuestion(Question question) async {
    try {
      final updated = await _client.questionAdmin.update(question);
      await loadQuestions(question.surveyId);
      return updated;
    } on Exception catch (e) {
      _setState(
        question.surveyId,
        getState(question.surveyId).copyWith(
          error: 'Failed to update question: $e',
        ),
      );
      return null;
    }
  }

  /// Delete a question.
  Future<bool> deleteQuestion(int surveyId, int questionId) async {
    try {
      await _client.questionAdmin.delete(questionId);
      await loadQuestions(surveyId);
      return true;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          error: 'Failed to delete question: $e',
        ),
      );
      return false;
    }
  }

  /// Reorder questions.
  Future<bool> reorderQuestions(int surveyId, List<int> questionIds) async {
    try {
      await _client.questionAdmin.reorder(surveyId, questionIds);
      await loadQuestions(surveyId);
      return true;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          error: 'Failed to reorder questions: $e',
        ),
      );
      return false;
    }
  }

  /// Create a new choice for a question.
  Future<Choice?> createChoice({
    required int questionId,
    required int surveyId,
    required String text,
  }) async {
    try {
      final choice = Choice(
        questionId: questionId,
        text: text,
        orderIndex:
            getState(surveyId).choicesByQuestion[questionId]?.length ?? 0,
      );
      final created = await _client.choiceAdmin.create(choice);
      await loadQuestions(surveyId);
      return created;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          error: 'Failed to create choice: $e',
        ),
      );
      return null;
    }
  }

  /// Update a choice.
  Future<Choice?> updateChoice(
    Choice choice,
    int surveyId,
  ) async {
    try {
      final updated = await _client.choiceAdmin.update(choice);
      await loadQuestions(surveyId);
      return updated;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          error: 'Failed to update choice: $e',
        ),
      );
      return null;
    }
  }

  /// Delete a choice.
  Future<bool> deleteChoice(int choiceId, int surveyId) async {
    try {
      await _client.choiceAdmin.delete(choiceId);
      await loadQuestions(surveyId);
      return true;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          error: 'Failed to delete choice: $e',
        ),
      );
      return false;
    }
  }

  /// Clear error for a survey.
  void clearError(int surveyId) {
    _setState(surveyId, getState(surveyId).copyWith(error: null));
  }
}
