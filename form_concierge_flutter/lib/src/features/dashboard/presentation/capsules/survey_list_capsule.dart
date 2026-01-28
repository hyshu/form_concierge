import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';

/// State for the survey list.
class SurveyListState {
  final List<Survey> surveys;
  final bool isLoading;
  final String? error;

  const SurveyListState({
    this.surveys = const [],
    this.isLoading = false,
    this.error,
  });

  factory SurveyListState.initial() => const SurveyListState();

  SurveyListState copyWith({
    List<Survey>? surveys,
    bool? isLoading,
    String? error,
  }) => SurveyListState(
    surveys: surveys ?? this.surveys,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

/// Capsule that manages the survey list.
SurveyListManager surveyListCapsule(CapsuleHandle use) {
  final (state, setState) = use.state(SurveyListState.initial());
  final client = use(clientCapsule);

  return SurveyListManager(
    state: state,
    setState: setState,
    client: client,
  );
}

/// Manager class for survey list operations.
class SurveyListManager {
  final SurveyListState state;
  final void Function(SurveyListState) _setState;
  final Client _client;

  SurveyListManager({
    required this.state,
    required void Function(SurveyListState) setState,
    required Client client,
  }) : _setState = setState,
       _client = client;

  /// Load all surveys for the current user.
  Future<void> loadSurveys() async {
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final surveys = await _client.surveyAdmin.list();
      _setState(state.copyWith(surveys: surveys, isLoading: false));
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          isLoading: false,
          error: 'Failed to load surveys: $e',
        ),
      );
    }
  }

  /// Delete a survey by ID.
  Future<bool> deleteSurvey(int surveyId) async {
    try {
      await _client.surveyAdmin.delete(surveyId);
      await loadSurveys();
      return true;
    } on Exception catch (e) {
      _setState(state.copyWith(error: 'Failed to delete survey: $e'));
      return false;
    }
  }

  /// Publish a survey.
  Future<bool> publishSurvey(int surveyId) async {
    try {
      await _client.surveyAdmin.publish(surveyId);
      await loadSurveys();
      return true;
    } on Exception catch (e) {
      _setState(state.copyWith(error: 'Failed to publish survey: $e'));
      return false;
    }
  }

  /// Close a survey.
  Future<bool> closeSurvey(int surveyId) async {
    try {
      await _client.surveyAdmin.close(surveyId);
      await loadSurveys();
      return true;
    } on Exception catch (e) {
      _setState(state.copyWith(error: 'Failed to close survey: $e'));
      return false;
    }
  }

  /// Reopen a closed survey.
  Future<bool> reopenSurvey(int surveyId) async {
    try {
      await _client.surveyAdmin.reopen(surveyId);
      await loadSurveys();
      return true;
    } on Exception catch (e) {
      _setState(state.copyWith(error: 'Failed to reopen survey: $e'));
      return false;
    }
  }

  /// Clear any error message.
  void clearError() {
    _setState(state.copyWith(error: null));
  }
}
