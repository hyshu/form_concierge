import 'package:form_concierge_client/form_concierge_client.dart';

import '../models/draft_question.dart';

/// State for the survey form.
class SurveyFormState {
  /// The survey displayed by this component or state.
  final Survey? survey;

  /// The project that contains the survey.
  final Project? project;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// Whether a save operation is in progress.
  final bool isSaving;

  /// The error message, when the operation could not complete.
  final String? error;

  /// The unsaved questions currently included in the survey draft.
  final List<DraftQuestion> draftQuestions;

  /// Whether AI question generation is in progress.
  final bool isGenerating;

  /// The latest generated question drafts waiting for review, if any.
  final List<DraftQuestion>? generatedQuestions;

  /// The error from the latest AI generation attempt, if any.
  final String? generationError;

  /// Creates SurveyFormState with the supplied values.
  const SurveyFormState({
    this.survey,
    this.project,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.draftQuestions = const [],
    this.isGenerating = false,
    this.generatedQuestions,
    this.generationError,
  });

  /// Creates the initial state before any data has been loaded.
  factory SurveyFormState.initial() => const SurveyFormState();

  /// Returns a copy with the supplied state changes.
  SurveyFormState copyWith({
    Survey? survey,
    Project? project,
    bool? isLoading,
    bool? isSaving,
    String? error,
    List<DraftQuestion>? draftQuestions,
    bool? isGenerating,
    List<DraftQuestion>? generatedQuestions,
    String? generationError,
    bool clearGeneratedQuestions = false,
    bool clearGenerationError = false,
  }) => SurveyFormState(
    survey: survey ?? this.survey,
    project: project ?? this.project,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    error: error,
    draftQuestions: draftQuestions ?? this.draftQuestions,
    isGenerating: isGenerating ?? this.isGenerating,
    generatedQuestions: clearGeneratedQuestions
        ? null
        : (generatedQuestions ?? this.generatedQuestions),
    generationError: clearGenerationError
        ? null
        : (generationError ?? this.generationError),
  );
}
