import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';

/// State for the survey form.
class SurveyFormState {
  final Survey? survey;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const SurveyFormState({
    this.survey,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  factory SurveyFormState.initial() => const SurveyFormState();

  SurveyFormState copyWith({
    Survey? survey,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) => SurveyFormState(
    survey: survey ?? this.survey,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    error: error,
  );
}

/// Capsule using keyed state pattern for per-survey forms.
KeyedStateAccessors<int?, SurveyFormState> surveyFormStateCapsule(
  CapsuleHandle use,
) {
  return createKeyedState(use, SurveyFormState.initial);
}

/// Capsule that provides the survey form manager.
SurveyFormManager surveyFormManagerCapsule(CapsuleHandle use) {
  final (getState, setState) = use(surveyFormStateCapsule);
  final client = use(clientCapsule);

  return SurveyFormManager(
    getState: getState,
    setState: setState,
    client: client,
  );
}

/// Form controllers for survey editing.
class SurveyFormControllers {
  final TextEditingController title;
  final TextEditingController slug;
  final TextEditingController description;

  SurveyFormControllers({
    required this.title,
    required this.slug,
    required this.description,
  });

  void dispose() {
    title.dispose();
    slug.dispose();
    description.dispose();
  }

  void populateFrom(Survey survey) {
    title.text = survey.title;
    slug.text = survey.slug;
    description.text = survey.description ?? '';
  }
}

/// Capsule for survey form controllers with cleanup.
SurveyFormControllers surveyFormControllersCapsule(CapsuleHandle use) {
  final controllers = use.memo(
    () => SurveyFormControllers(
      title: TextEditingController(),
      slug: TextEditingController(),
      description: TextEditingController(),
    ),
  );

  use.effect(() {
    return controllers.dispose;
  }, []);

  return controllers;
}

/// Manager class for survey form operations.
class SurveyFormManager {
  final SurveyFormState Function(int? surveyId) getState;
  final void Function(int? surveyId, SurveyFormState state) _setState;
  final Client _client;

  SurveyFormManager({
    required this.getState,
    required void Function(int? surveyId, SurveyFormState state) setState,
    required Client client,
  }) : _setState = setState,
       _client = client;

  /// Load a survey by ID.
  Future<void> loadSurvey(int surveyId) async {
    _setState(surveyId, getState(surveyId).copyWith(isLoading: true));
    try {
      final survey = await _client.surveyAdmin.getById(surveyId);
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          survey: survey,
          isLoading: false,
        ),
      );
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isLoading: false,
          error: 'Failed to load survey: $e',
        ),
      );
    }
  }

  /// Create a new survey.
  Future<Survey?> createSurvey({
    required String title,
    required String slug,
    String? description,
    required AuthRequirement authRequirement,
  }) async {
    _setState(null, getState(null).copyWith(isSaving: true, error: null));
    try {
      final survey = Survey(
        slug: slug,
        title: title,
        description: description,
        status: SurveyStatus.draft,
        authRequirement: authRequirement,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final created = await _client.surveyAdmin.create(survey);
      _setState(null, getState(null).copyWith(isSaving: false));
      return created;
    } on Exception catch (e) {
      _setState(
        null,
        getState(null).copyWith(
          isSaving: false,
          error: 'Failed to create survey: $e',
        ),
      );
      return null;
    }
  }

  /// Update an existing survey.
  Future<Survey?> updateSurvey(Survey survey) async {
    _setState(
      survey.id,
      getState(survey.id).copyWith(isSaving: true, error: null),
    );
    try {
      final updated = await _client.surveyAdmin.update(survey);
      _setState(
        survey.id,
        getState(survey.id).copyWith(
          survey: updated,
          isSaving: false,
        ),
      );
      return updated;
    } on Exception catch (e) {
      _setState(
        survey.id,
        getState(survey.id).copyWith(
          isSaving: false,
          error: 'Failed to update survey: $e',
        ),
      );
      return null;
    }
  }

  /// Clear error for a survey.
  void clearError(int? surveyId) {
    _setState(surveyId, getState(surveyId).copyWith(error: null));
  }
}
