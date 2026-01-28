import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';

/// State for the question list.
class QuestionListState {
  final List<Question> questions;
  final Map<int, List<QuestionOption>> optionsByQuestion;
  final bool isLoading;
  final String? error;

  const QuestionListState({
    this.questions = const [],
    this.optionsByQuestion = const {},
    this.isLoading = false,
    this.error,
  });

  factory QuestionListState.initial() => const QuestionListState();

  QuestionListState copyWith({
    List<Question>? questions,
    Map<int, List<QuestionOption>>? optionsByQuestion,
    bool? isLoading,
    String? error,
  }) => QuestionListState(
    questions: questions ?? this.questions,
    optionsByQuestion: optionsByQuestion ?? this.optionsByQuestion,
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

      // Load options for choice questions
      final optionsByQuestion = <int, List<QuestionOption>>{};
      for (final question in questions) {
        if (question.type == QuestionType.singleChoice ||
            question.type == QuestionType.multipleChoice) {
          optionsByQuestion[question.id!] = await _client.questionAdmin
              .getOptionsForQuestion(question.id!);
        }
      }

      _setState(
        surveyId,
        getState(surveyId).copyWith(
          questions: questions,
          optionsByQuestion: optionsByQuestion,
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

  /// Create a new option for a question.
  Future<QuestionOption?> createOption({
    required int questionId,
    required int surveyId,
    required String text,
  }) async {
    try {
      final option = QuestionOption(
        questionId: questionId,
        text: text,
        orderIndex:
            getState(surveyId).optionsByQuestion[questionId]?.length ?? 0,
      );
      final created = await _client.questionOptionAdmin.create(option);
      await loadQuestions(surveyId);
      return created;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          error: 'Failed to create option: $e',
        ),
      );
      return null;
    }
  }

  /// Update an option.
  Future<QuestionOption?> updateOption(
    QuestionOption option,
    int surveyId,
  ) async {
    try {
      final updated = await _client.questionOptionAdmin.update(option);
      await loadQuestions(surveyId);
      return updated;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          error: 'Failed to update option: $e',
        ),
      );
      return null;
    }
  }

  /// Delete an option.
  Future<bool> deleteOption(int optionId, int surveyId) async {
    try {
      await _client.questionOptionAdmin.delete(optionId);
      await loadQuestions(surveyId);
      return true;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          error: 'Failed to delete option: $e',
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
