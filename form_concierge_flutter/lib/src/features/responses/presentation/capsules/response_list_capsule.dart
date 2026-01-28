import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';
import '../../../../core/constants/pagination.dart';

/// State for the response list.
class ResponseListState {
  final List<SurveyResponse> responses;
  final int totalCount;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int pageSize;

  const ResponseListState({
    this.responses = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.pageSize = kDefaultPageSize,
  });

  factory ResponseListState.initial() => const ResponseListState();

  ResponseListState copyWith({
    List<SurveyResponse>? responses,
    int? totalCount,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? pageSize,
  }) => ResponseListState(
    responses: responses ?? this.responses,
    totalCount: totalCount ?? this.totalCount,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    currentPage: currentPage ?? this.currentPage,
    pageSize: pageSize ?? this.pageSize,
  );

  int get totalPages => (totalCount / pageSize).ceil();
}

/// Capsule using keyed state pattern for per-survey response lists.
KeyedStateAccessors<int, ResponseListState> responseListStateCapsule(
  CapsuleHandle use,
) {
  return createKeyedState(use, ResponseListState.initial);
}

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
    required void Function(int surveyId, ResponseListState state) setState,
    required Client client,
  }) : _setState = setState,
       _client = client;

  /// Load responses for a survey with pagination.
  Future<void> loadResponses(int surveyId, {int page = 0}) async {
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

      _setState(
        surveyId,
        getState(surveyId).copyWith(
          responses: responses,
          totalCount: count,
          isLoading: false,
          currentPage: page,
        ),
      );
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isLoading: false,
          error: 'Failed to load responses: $e',
        ),
      );
    }
  }

  /// Delete a response.
  Future<bool> deleteResponse(int surveyId, int responseId) async {
    try {
      await _client.responseAnalytics.deleteResponse(responseId);
      await loadResponses(surveyId, page: getState(surveyId).currentPage);
      return true;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          error: 'Failed to delete response: $e',
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
