import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';

/// State for aggregated results.
class AggregatedResultsState {
  /// The aggregated survey results, when available.
  final SurveyResults? results;

  /// Available choices indexed by question identifier.
  final Map<int, List<Choice>> choicesByQuestion;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// The error message, when the operation could not complete.
  final String? error;

  /// Creates AggregatedResultsState with the supplied values.
  const AggregatedResultsState({
    this.results,
    this.choicesByQuestion = const {},
    this.isLoading = true,
    this.error,
  });

  /// Creates the initial state before any data has been loaded.
  factory AggregatedResultsState.initial() => const AggregatedResultsState();

  /// Returns a copy with the supplied state changes.
  AggregatedResultsState copyWith({
    SurveyResults? results,
    Map<int, List<Choice>>? choicesByQuestion,
    bool? isLoading,
    String? error,
  }) => AggregatedResultsState(
    results: results ?? this.results,
    choicesByQuestion: choicesByQuestion ?? this.choicesByQuestion,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

/// Capsule using keyed state pattern for per-survey aggregated results.
KeyedStateAccessors<int, AggregatedResultsState> aggregatedResultsStateCapsule(
  CapsuleHandle use,
) => createKeyedState(use, AggregatedResultsState.initial);

/// Capsule that provides the aggregated results manager.
AggregatedResultsManager aggregatedResultsManagerCapsule(CapsuleHandle use) {
  final (getState, setState) = use(aggregatedResultsStateCapsule);
  final client = use(clientCapsule);

  return AggregatedResultsManager(
    getState: getState,
    setState: setState,
    client: client,
  );
}

/// Manager class for aggregated results operations.
class AggregatedResultsManager {
  /// Reads the current state for the supplied record identifier.
  final AggregatedResultsState Function(int surveyId) getState;
  final void Function(int surveyId, AggregatedResultsState state) _setState;
  final Client _client;

  /// Creates AggregatedResultsManager with the supplied values.
  AggregatedResultsManager({
    required this.getState,
    required this._setState,
    required this._client,
  });

  /// Load aggregated results for a survey.
  Future<void> loadResults(int surveyId) async {
    _setState(
      surveyId,
      getState(surveyId).copyWith(isLoading: true, error: null),
    );

    try {
      final results = await _client.responseAnalytics.getAggregatedResults(
        surveyId,
      );

      // Load choices to map IDs to text
      final choicesByQuestion = <int, List<Choice>>{};
      for (final questionResult in results.questionResults) {
        if (questionResult.choiceCounts != null) {
          final choices = await _client.questionAdmin.getChoicesForQuestion(
            questionResult.questionId,
          );
          choicesByQuestion[questionResult.questionId] = choices;
        }
      }

      _setState(
        surveyId,
        getState(surveyId).copyWith(
          results: results,
          choicesByQuestion: choicesByQuestion,
          isLoading: false,
        ),
      );
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isLoading: false,
          error: 'Failed to load results: $e',
        ),
      );
    }
  }

  /// Clear error for a survey.
  void clearError(int surveyId) =>
      _setState(surveyId, getState(surveyId).copyWith(error: null));
}
