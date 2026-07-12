import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';
import '../models/draft_question.dart';
import 'survey_form_state.dart';

export 'survey_form_controllers.dart';
export 'survey_form_state.dart';

/// Capsule using keyed state pattern for per-survey forms.
KeyedStateAccessors<int?, SurveyFormState> surveyFormStateCapsule(
  CapsuleHandle use,
) => createKeyedState(use, SurveyFormState.initial);

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

/// Manager class for survey form operations.
class SurveyFormManager {
  final SurveyFormState Function(int? surveyId) getState;
  final void Function(int? surveyId, SurveyFormState state) _setState;
  final Client _client;

  SurveyFormManager({
    required this.getState,
    required this._setState,
    required this._client,
  });

  /// Load a survey by ID.
  Future<void> loadSurvey(int surveyId) async {
    _setState(surveyId, getState(surveyId).copyWith(isLoading: true));
    try {
      final survey = await _client.surveyAdmin.getById(surveyId);
      final project = survey == null
          ? null
          : (await _client.projectAdmin.getById(survey.projectId))?.project;
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          survey: survey,
          project: project,
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

  Future<void> loadProject(int projectId, {int? surveyId}) async {
    _setState(surveyId, getState(surveyId).copyWith(isLoading: true));
    try {
      final project = await _client.projectAdmin.getById(projectId);
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          project: project?.project,
          isLoading: false,
        ),
      );
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isLoading: false,
          error: 'Failed to load project: $e',
        ),
      );
    }
  }

  /// Create a new survey.
  Future<Survey?> createSurvey({
    required int projectId,
    required String slug,
    required LocalizedText titleTranslations,
    required LocalizedText descriptionTranslations,
    bool followUpEnabled = false,
    String? followUpPrompt,
    bool captchaEnabled = true,
  }) async {
    _setState(null, getState(null).copyWith(isSaving: true, error: null));
    try {
      final created = await _client.surveyAdmin.create(
        _draftSurvey(
          projectId: projectId,
          slug: slug,
          titleTranslations: titleTranslations,
          descriptionTranslations: descriptionTranslations,
          followUpEnabled: followUpEnabled,
          followUpPrompt: followUpPrompt,
          captchaEnabled: captchaEnabled,
        ),
      );
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
  void clearError(int? surveyId) =>
      _setState(surveyId, getState(surveyId).copyWith(error: null));

  // Draft Questions Management (for create survey page)

  /// Add a draft question.
  void addDraftQuestion({
    required LocalizedText textTranslations,
    required QuestionType type,
    required bool isRequired,
    required LocalizedText placeholderTranslations,
    int? minLength,
    int? maxLength,
    int? minSelected,
    int? maxSelected,
    required LocalizedText firstChoiceTranslations,
    required LocalizedText secondChoiceTranslations,
  }) {
    final newQuestion = DraftQuestion.create(
      textTranslations: textTranslations,
      type: type,
      isRequired: isRequired,
      placeholderTranslations: placeholderTranslations,
      minLength: minLength,
      maxLength: maxLength,
      minSelected: minSelected,
      maxSelected: maxSelected,
      firstChoiceTranslations: firstChoiceTranslations,
      secondChoiceTranslations: secondChoiceTranslations,
    );
    _setDraftQuestions((questions) => [...questions, newQuestion]);
  }

  /// Update a draft question.
  void updateDraftQuestion({
    required String tempId,
    required LocalizedText textTranslations,
    required QuestionType type,
    required bool isRequired,
    required LocalizedText placeholderTranslations,
    int? minLength,
    int? maxLength,
    int? minSelected,
    int? maxSelected,
  }) => _updateDraftQuestion(
    tempId,
    (question) => DraftQuestion(
      tempId: question.tempId,
      textTranslations: textTranslations,
      type: type,
      isRequired: isRequired,
      placeholderTranslations: placeholderTranslations,
      minLength: minLength,
      maxLength: maxLength,
      minSelected: minSelected,
      maxSelected: maxSelected,
      choices: question.choices,
    ),
  );

  /// Delete a draft question.
  void deleteDraftQuestion(String tempId) => _setDraftQuestions(
    (questions) => questions.where((q) => q.tempId != tempId).toList(),
  );

  /// Reorder draft questions.
  void reorderDraftQuestions(int oldIndex, int newIndex) {
    final state = getState(null);
    final questions = List<DraftQuestion>.from(state.draftQuestions);
    final item = questions.removeAt(oldIndex);
    questions.insert(newIndex, item);
    _setState(null, state.copyWith(draftQuestions: questions));
  }

  /// Add a choice to a draft question.
  void addChoiceToDraftQuestion(
    String questionTempId,
    LocalizedText choiceTranslations,
  ) => _updateDraftQuestion(
    questionTempId,
    (question) => question.copyWith(
      choices: [
        ...question.choices,
        DraftChoice.create(textTranslations: choiceTranslations),
      ],
    ),
  );

  /// Update a choice in a draft question.
  void updateDraftChoice(
    String questionTempId,
    String choiceTempId,
    LocalizedText textTranslations,
  ) => _updateDraftQuestion(
    questionTempId,
    (question) => question.copyWith(
      choices: question.choices.map((choice) {
        return choice.tempId == choiceTempId
            ? choice.copyWith(textTranslations: textTranslations)
            : choice;
      }).toList(),
    ),
  );

  /// Delete a choice from a draft question.
  void deleteDraftChoice(String questionTempId, String choiceTempId) =>
      _updateDraftQuestion(
        questionTempId,
        (question) => question.copyWith(
          choices: question.choices
              .where((choice) => choice.tempId != choiceTempId)
              .toList(),
        ),
      );

  /// Create a new survey with questions.
  Future<Survey?> createSurveyWithQuestions({
    required int projectId,
    required String slug,
    required LocalizedText titleTranslations,
    required LocalizedText descriptionTranslations,
    bool followUpEnabled = false,
    String? followUpPrompt,
    bool captchaEnabled = true,
  }) async {
    final state = getState(null);
    _setState(null, state.copyWith(isSaving: true, error: null));
    try {
      final questions = state.draftQuestions
          .map((q) => q.toQuestionWithChoices())
          .toList();

      final created = await _client.surveyAdmin.createWithQuestions(
        _draftSurvey(
          projectId: projectId,
          slug: slug,
          titleTranslations: titleTranslations,
          descriptionTranslations: descriptionTranslations,
          followUpEnabled: followUpEnabled,
          followUpPrompt: followUpPrompt,
          captchaEnabled: captchaEnabled,
        ),
        questions,
      );
      _setState(
        null,
        SurveyFormState.initial().copyWith(isSaving: false),
      );
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

  Survey _draftSurvey({
    required int projectId,
    required String slug,
    required LocalizedText titleTranslations,
    required LocalizedText descriptionTranslations,
    bool followUpEnabled = false,
    String? followUpPrompt,
    bool captchaEnabled = true,
  }) {
    final now = DateTime.now();
    return Survey(
      projectId: projectId,
      slug: slug,
      titleTranslations: titleTranslations,
      descriptionTranslations: descriptionTranslations,
      status: SurveyStatus.draft,
      followUpEnabled: followUpEnabled,
      followUpPrompt: followUpPrompt,
      captchaEnabled: captchaEnabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  void _setDraftQuestions(
    List<DraftQuestion> Function(List<DraftQuestion> questions) update,
  ) {
    final state = getState(null);
    _setState(
      null,
      state.copyWith(draftQuestions: update(state.draftQuestions)),
    );
  }

  void _updateDraftQuestion(
    String tempId,
    DraftQuestion Function(DraftQuestion question) update,
  ) => _setDraftQuestions(
    (questions) => questions.map((question) {
      return question.tempId == tempId ? update(question) : question;
    }).toList(),
  );

  // AI Generation Methods

  /// Generate questions using AI from a natural language prompt.
  ///
  /// The generated questions are stored in [SurveyFormState.generatedQuestions]
  /// for preview. Call [applyGeneratedQuestions] to apply them to draftQuestions.
  Future<void> generateQuestions(String prompt) async {
    final state = getState(null);
    _setState(
      null,
      state.copyWith(
        isGenerating: true,
        clearGenerationError: true,
        clearGeneratedQuestions: true,
      ),
    );

    try {
      final questions = await _client.aiAdmin.generateSurveyQuestions(prompt);
      final draftQuestions = questions
          .map(DraftQuestion.fromQuestionWithChoices)
          .toList();

      _setState(
        null,
        getState(null).copyWith(
          isGenerating: false,
          generatedQuestions: draftQuestions,
        ),
      );
    } on Exception catch (e) {
      _setState(
        null,
        getState(null).copyWith(
          isGenerating: false,
          generationError: 'Failed to generate questions: $e',
        ),
      );
    }
  }

  /// Apply the generated questions to draftQuestions.
  void applyGeneratedQuestions() {
    final state = getState(null);
    if (state.generatedQuestions == null) return;

    _setState(
      null,
      state.copyWith(
        draftQuestions: [...state.draftQuestions, ...state.generatedQuestions!],
        clearGeneratedQuestions: true,
      ),
    );
  }

  /// Clear the generated questions preview.
  void clearGeneratedQuestions() => _setState(
    null,
    getState(null).copyWith(
      clearGeneratedQuestions: true,
      clearGenerationError: true,
    ),
  );
}
