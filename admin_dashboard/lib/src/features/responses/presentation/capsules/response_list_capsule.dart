import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';
import '../../../../core/capsules/manager_operation.dart';
import '../../../../core/constants/pagination.dart';

/// State for the response list.
class ResponseListState {
  final List<SurveyResponse> responses;
  final int totalCount;
  final bool isLoading;
  final bool isExporting;
  final String? error;
  final int currentPage;
  final int pageSize;
  final List<Question> questions;
  final Map<int, List<Choice>> choicesByQuestion;
  final Map<int, List<Answer>> answersByResponseId;
  final Set<int> loadingAnswerIds;
  final Map<int, String> answerErrorsByResponseId;

  const ResponseListState({
    this.responses = const [],
    this.totalCount = 0,
    this.isLoading = true,
    this.isExporting = false,
    this.error,
    this.currentPage = 0,
    this.pageSize = kDefaultPageSize,
    this.questions = const [],
    this.choicesByQuestion = const {},
    this.answersByResponseId = const {},
    this.loadingAnswerIds = const {},
    this.answerErrorsByResponseId = const {},
  });

  factory ResponseListState.initial() => const ResponseListState();

  ResponseListState copyWith({
    List<SurveyResponse>? responses,
    int? totalCount,
    bool? isLoading,
    bool? isExporting,
    String? error,
    int? currentPage,
    int? pageSize,
    List<Question>? questions,
    Map<int, List<Choice>>? choicesByQuestion,
    Map<int, List<Answer>>? answersByResponseId,
    Set<int>? loadingAnswerIds,
    Map<int, String>? answerErrorsByResponseId,
  }) => ResponseListState(
    responses: responses ?? this.responses,
    totalCount: totalCount ?? this.totalCount,
    isLoading: isLoading ?? this.isLoading,
    isExporting: isExporting ?? this.isExporting,
    error: error,
    currentPage: currentPage ?? this.currentPage,
    pageSize: pageSize ?? this.pageSize,
    questions: questions ?? this.questions,
    choicesByQuestion: choicesByQuestion ?? this.choicesByQuestion,
    answersByResponseId: answersByResponseId ?? this.answersByResponseId,
    loadingAnswerIds: loadingAnswerIds ?? this.loadingAnswerIds,
    answerErrorsByResponseId:
        answerErrorsByResponseId ?? this.answerErrorsByResponseId,
  );

  int get totalPages => (totalCount / pageSize).ceil();
}

/// Capsule using keyed state pattern for per-survey response lists.
KeyedStateAccessors<int, ResponseListState> responseListStateCapsule(
  CapsuleHandle use,
) => createKeyedState(use, ResponseListState.initial);

/// Capsule that provides the response list manager.
ResponseListManager responseListManagerCapsule(CapsuleHandle use) {
  final (getState, setState) = use(responseListStateCapsule);
  final client = use(clientCapsule);

  return ResponseListManager(
    getState: getState,
    setState: setState,
    client: client,
  );
}

/// Manager class for response list operations.
class ResponseListManager {
  final ResponseListState Function(int surveyId) getState;
  final void Function(int surveyId, ResponseListState state) _setState;
  final Client _client;

  ResponseListManager({
    required this.getState,
    required this._setState,
    required this._client,
  });

  /// Monotonic token per survey so stale page loads cannot overwrite newer ones.
  final Map<int, int> _loadGenerations = {};

  /// Load responses for a survey with pagination.
  Future<void> loadResponses(int surveyId, {int page = 0}) async {
    final generation = (_loadGenerations[surveyId] ?? 0) + 1;
    _loadGenerations[surveyId] = generation;
    final state = getState(surveyId);
    _setState(
      surveyId,
      state.copyWith(isLoading: true, currentPage: page, error: null),
    );

    try {
      final responses = await _client.responseAnalytics.getResponses(
        surveyId,
        limit: state.pageSize,
        offset: page * state.pageSize,
      );
      final count = await _client.responseAnalytics.getResponseCount(surveyId);
      // Question labels are needed when expanding individual answer content.
      final questions = state.questions.isEmpty
          ? await _client.questionAdmin.getForSurvey(surveyId)
          : state.questions;
      final choicesByQuestion = state.choicesByQuestion.isEmpty
          ? await _client.questionAdmin.getChoicesByQuestion(questions)
          : state.choicesByQuestion;

      if (_loadGenerations[surveyId] != generation) return;
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          responses: responses,
          totalCount: count,
          isLoading: false,
          currentPage: page,
          questions: questions,
          choicesByQuestion: choicesByQuestion,
        ),
      );
    } on Exception catch (e) {
      if (_loadGenerations[surveyId] != generation) return;
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isLoading: false,
          error: 'Failed to load responses: $e',
        ),
      );
    }
  }

  /// Lazy-load answers for one response when its ExpansionTile is opened.
  Future<void> loadAnswersForResponse(int surveyId, int responseId) async {
    final state = getState(surveyId);
    if (state.answersByResponseId.containsKey(responseId) ||
        state.loadingAnswerIds.contains(responseId)) {
      return;
    }

    final loading = {...state.loadingAnswerIds, responseId};
    final errors = Map<int, String>.from(state.answerErrorsByResponseId)
      ..remove(responseId);
    _setState(
      surveyId,
      state.copyWith(
        loadingAnswerIds: loading,
        answerErrorsByResponseId: errors,
      ),
    );

    try {
      final answers = await _client.responseAnalytics.getAnswersForResponse(
        responseId,
      );
      final current = getState(surveyId);
      final nextAnswers = Map<int, List<Answer>>.from(
        current.answersByResponseId,
      )..[responseId] = answers;
      final nextLoading = {...current.loadingAnswerIds}..remove(responseId);
      _setState(
        surveyId,
        current.copyWith(
          answersByResponseId: nextAnswers,
          loadingAnswerIds: nextLoading,
        ),
      );
    } on Exception catch (e) {
      final current = getState(surveyId);
      final nextLoading = {...current.loadingAnswerIds}..remove(responseId);
      final nextErrors = Map<int, String>.from(
        current.answerErrorsByResponseId,
      )..[responseId] = 'Failed to load answers: $e';
      _setState(
        surveyId,
        current.copyWith(
          loadingAnswerIds: nextLoading,
          answerErrorsByResponseId: nextErrors,
        ),
      );
    }
  }

  /// Delete a response.
  Future<bool> deleteResponse(int surveyId, int responseId) async {
    return _runAndReloadCurrentPage(
      surveyId,
      () => _client.responseAnalytics.deleteResponse(responseId),
      'Failed to delete response',
    );
  }

  /// Send an admin reply to the anonymous account behind a response.
  Future<bool> sendReply(
    int surveyId,
    int responseId,
    String body,
  ) => _runAndReloadCurrentPage(
    surveyId,
    () => _client.responseAnalytics.createReply(responseId, body),
    'Failed to send reply',
  );

  Future<ResponseExportFile?> exportResponses(
    int surveyId,
    ResponseExportFormat format,
  ) async {
    _setState(
      surveyId,
      getState(surveyId).copyWith(isExporting: true, error: null),
    );
    try {
      final file = await _client.responseAnalytics.exportResponses(
        surveyId,
        format: format,
      );
      _setState(
        surveyId,
        getState(surveyId).copyWith(isExporting: false),
      );
      return file;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isExporting: false,
          error: 'Failed to export responses: $e',
        ),
      );
      return null;
    }
  }

  Future<bool> _runAndReloadCurrentPage(
    int surveyId,
    Future<void> Function() action,
    String errorMessage,
  ) async {
    final page = getState(surveyId).currentPage;
    return runVoidAndReload(
      action: action,
      reload: () => loadResponses(surveyId, page: page),
      setError: (error) => _setError(surveyId, error),
      errorMessage: errorMessage,
    );
  }

  /// Clear error for a survey.
  void clearError(int surveyId) =>
      _setState(surveyId, getState(surveyId).copyWith(error: null));

  void _setError(int surveyId, String error) =>
      _setState(surveyId, getState(surveyId).copyWith(error: error));
}
