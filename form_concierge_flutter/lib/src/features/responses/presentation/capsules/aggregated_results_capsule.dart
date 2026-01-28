import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';

/// State for aggregated results.
class AggregatedResultsState {
  final SurveyResults? results;
  final Map<int, List<QuestionOption>> optionsByQuestion;
  final bool isLoading;
  final String? error;

  const AggregatedResultsState({
    this.results,
    this.optionsByQuestion = const {},
    this.isLoading = false,
    this.error,
  });

  factory AggregatedResultsState.initial() => const AggregatedResultsState();

  AggregatedResultsState copyWith({
    SurveyResults? results,
    Map<int, List<QuestionOption>>? optionsByQuestion,
    bool? isLoading,
    String? error,
  }) => AggregatedResultsState(
    results: results ?? this.results,
    optionsByQuestion: optionsByQuestion ?? this.optionsByQuestion,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

/// Capsule using keyed state pattern for per-survey aggregated results.
KeyedStateAccessors<int, AggregatedResultsState> aggregatedResultsStateCapsule(
  CapsuleHandle use,
) {
  return createKeyedState(use, AggregatedResultsState.initial);
}

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
  final AggregatedResultsState Function(int surveyId) getState;
  final void Function(int surveyId, AggregatedResultsState state) _setState;
  final Client _client;

  AggregatedResultsManager({
    required this.getState,
    required void Function(int surveyId, AggregatedResultsState state) setState,
    required Client client,
  }) : _setState = setState,
       _client = client;

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

      // Load options to map IDs to text
      final optionsByQuestion = <int, List<QuestionOption>>{};
      for (final questionResult in results.questionResults) {
        if (questionResult.optionCounts != null) {
          final options = await _client.questionAdmin.getOptionsForQuestion(
            questionResult.questionId,
          );
          optionsByQuestion[questionResult.questionId] = options;
        }
      }

      _setState(
        surveyId,
        getState(surveyId).copyWith(
          results: results,
          optionsByQuestion: optionsByQuestion,
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
  void clearError(int surveyId) {
    _setState(surveyId, getState(surveyId).copyWith(error: null));
  }
}
