import 'package:form_concierge_client/form_concierge_client.dart';

import '../models/draft_question.dart';

/// State for the survey form.
class SurveyFormState {
  final Survey? survey;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final List<DraftQuestion> draftQuestions;

  final bool isGenerating;
  final List<DraftQuestion>? generatedQuestions;
  final String? generationError;

  const SurveyFormState({
    this.survey,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.draftQuestions = const [],
    this.isGenerating = false,
    this.generatedQuestions,
    this.generationError,
  });

  factory SurveyFormState.initial() => const SurveyFormState();

  SurveyFormState copyWith({
    Survey? survey,
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
