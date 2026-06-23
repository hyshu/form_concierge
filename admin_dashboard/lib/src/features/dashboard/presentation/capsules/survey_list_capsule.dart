import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/manager_operation.dart';

/// State for the survey list.
class SurveyListState {
  final List<ProjectWithSurveys> projects;
  final bool isLoading;
  final String? error;

  const SurveyListState({
    this.projects = const [],
    this.isLoading = true,
    this.error,
  });

  factory SurveyListState.initial() => const SurveyListState();

  List<Survey> get surveys =>
      projects.expand((project) => project.surveys).toList();

  SurveyListState copyWith({
    List<ProjectWithSurveys>? projects,
    bool? isLoading,
    String? error,
  }) => SurveyListState(
    projects: projects ?? this.projects,
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

  /// Load all projects and surveys for the current user.
  Future<void> loadProjects() async {
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final projects = await _client.projectAdmin.list();
      _setState(state.copyWith(projects: projects, isLoading: false));
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          isLoading: false,
          error: 'Failed to load projects: $e',
        ),
      );
    }
  }

  Future<void> loadSurveys() async {
    await loadProjects();
  }

  Future<ProjectWithSurveys?> getProject(int projectId) async {
    try {
      return _client.projectAdmin.getById(projectId);
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          error: 'Failed to load project: $e',
        ),
      );
      return null;
    }
  }

  Future<Project?> createProject(Project project) async {
    return runAndReload(
      action: () => _client.projectAdmin.create(project),
      reload: loadProjects,
      setError: _setError,
      errorMessage: 'Failed to create project',
    );
  }

  Future<Project?> updateProject(Project project) async {
    return runAndReload(
      action: () => _client.projectAdmin.update(project),
      reload: loadProjects,
      setError: _setError,
      errorMessage: 'Failed to update project',
    );
  }

  Future<bool> deleteProject(int projectId) async {
    return runVoidAndReload(
      action: () => _client.projectAdmin.delete(projectId),
      reload: loadSurveys,
      setError: _setError,
      errorMessage: 'Failed to delete project',
    );
  }

  /// Delete a survey by ID.
  Future<bool> deleteSurvey(int surveyId) async {
    return runVoidAndReload(
      action: () => _client.surveyAdmin.delete(surveyId),
      reload: loadSurveys,
      setError: _setError,
      errorMessage: 'Failed to delete survey',
    );
  }

  /// Publish a survey.
  Future<bool> publishSurvey(int surveyId) async {
    return runVoidAndReload(
      action: () => _client.surveyAdmin.publish(surveyId),
      reload: loadSurveys,
      setError: _setError,
      errorMessage: 'Failed to publish survey',
    );
  }

  /// Close a survey.
  Future<bool> closeSurvey(int surveyId) async {
    return runVoidAndReload(
      action: () => _client.surveyAdmin.close(surveyId),
      reload: loadSurveys,
      setError: _setError,
      errorMessage: 'Failed to close survey',
    );
  }

  /// Reopen a closed survey.
  Future<bool> reopenSurvey(int surveyId) async {
    return runVoidAndReload(
      action: () => _client.surveyAdmin.reopen(surveyId),
      reload: loadSurveys,
      setError: _setError,
      errorMessage: 'Failed to reopen survey',
    );
  }

  Future<bool> updateSurveyWebEnabled(Survey survey, bool enabled) async {
    return runVoidAndReload(
      action: () => _client.surveyAdmin.update(
        survey.copyWith(webEnabled: enabled, updatedAt: DateTime.now()),
      ),
      reload: loadSurveys,
      setError: _setError,
      errorMessage: 'Failed to update web publication',
    );
  }

  void _setError(String error) {
    _setState(state.copyWith(error: error));
  }

  /// Clear any error message.
  void clearError() {
    _setState(state.copyWith(error: null));
  }
}
