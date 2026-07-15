import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';
import 'package:hux/hux.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/public_config_capsule.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_admin_shell.dart';
import '../../../../core/widgets/hux_states.dart';
import '../../../dashboard/presentation/capsules/survey_list_capsule.dart';
import '../capsules/question_list_capsule.dart';
import '../capsules/survey_form_capsule.dart';
import '../widgets/draft_questions_section.dart';
import '../widgets/question_list.dart';
import '../widgets/survey_form.dart';

/// Page for creating or editing a survey and its questions.
class SurveyEditorPage extends RearchConsumer {
  final int? surveyId;
  final int? projectId;

  const SurveyEditorPage({super.key, this.surveyId, this.projectId});

  @override
  Widget build(context, use) {
    final formManager = use(surveyFormManagerCapsule);
    final questionManager = use(questionListManagerCapsule);
    final surveyListManager = use(surveyListCapsule);
    final controllers = use(surveyFormControllersCapsule);
    final surveyFormKey = use.memo(
      () => GlobalKey<SurveyFormWidgetState>(),
      [surveyId, projectId],
    );
    final publicConfig = use(publicConfigCapsule);
    final client = use(clientCapsule);

    final isNewSurvey = surveyId == null;
    final formState = formManager.getState(surveyId);
    final questionState = isNewSurvey
        ? null
        : questionManager.getState(surveyId!);
    final aiGenerationEnabled = publicConfig.state.aiGenerationEnabled;
    final role = client.auth.signedInUser?.role;
    final canWriteSurveys = role == AdminRole.admin || role == AdminRole.editor;
    final canManageUsers = role == AdminRole.admin;

    // Load survey and questions on first build (only for existing surveys)
    if (use.isFirstBuild()) {
      publicConfig.loadConfig();
      if (isNewSurvey && projectId != null) {
        controllers.clear();
        formManager.loadProject(projectId!);
      } else if (!isNewSurvey) {
        formManager.loadSurvey(surveyId!);
        questionManager.loadQuestions(surveyId!);
      }
    }

    if ((!isNewSurvey || projectId != null) &&
        (formState.isLoading ||
            (formState.project == null && formState.error == null) ||
            (!isNewSurvey &&
                formState.survey == null &&
                formState.error == null))) {
      return HuxAdminShell(
        title: context.tr('Loading...'),
        selectedItemId: 'surveys',
        showUsers: canManageUsers,
        showSettings: canManageUsers,
        onBack: () => context.go('/admin'),
        child: HuxLoadingState(
          message: context.tr('Loading...'),
          maxWidth: 720,
        ),
      );
    }

    final survey = formState.survey;
    final project = formState.project;
    final activeDefaultLocale =
        project?.defaultLocale ?? defaultFormContentLocale;
    final activeLocales = project?.supportedLocales ?? formContentLocaleCodes;
    if (isNewSurvey && (projectId == null || project == null)) {
      return HuxAdminShell(
        title: context.tr('Project not found'),
        selectedItemId: 'surveys',
        showUsers: canManageUsers,
        showSettings: canManageUsers,
        onBack: () => context.go('/admin'),
        child: HuxPageBody(
          child: HuxErrorState(
            message: context.tr('Project not found'),
            onRetry: () => context.go('/admin'),
          ),
        ),
      );
    }
    if (!isNewSurvey && survey == null) {
      return HuxAdminShell(
        title: context.tr('Survey Not Found'),
        selectedItemId: 'surveys',
        showUsers: canManageUsers,
        showSettings: canManageUsers,
        onBack: () => context.go('/admin'),
        child: HuxPageBody(
          child: HuxErrorState(
            message: context.tr('Survey not found'),
            onRetry: () => context.go('/admin'),
          ),
        ),
      );
    }

    final canEditSurvey =
        canWriteSurveys &&
        (isNewSurvey || survey!.status != SurveyStatus.archived);
    final canEditQuestions =
        canEditSurvey &&
        (isNewSurvey || survey!.status != SurveyStatus.published);
    final questionsLockedByStatus =
        !isNewSurvey &&
        (survey!.status == SurveyStatus.published ||
            survey.status == SurveyStatus.archived);

    return HuxAdminShell(
      title: isNewSurvey
          ? context.tr('New Survey')
          : survey!.titleFor(activeDefaultLocale),
      selectedItemId: 'surveys',
      showUsers: canManageUsers,
      showSettings: canManageUsers,
      onBack: () => context.go('/admin'),
      actions: [
        if (!isNewSurvey &&
            canWriteSurveys &&
            survey!.status == SurveyStatus.draft)
          HuxButton(
            onPressed: _canPublish(questionState!)
                ? () => _publishSurvey(context, surveyListManager)
                : null,
            icon: LucideIcons.upload,
            child: Text(context.tr('Publish')),
          ),
      ],
      child: SafeArea(
        child: HuxPageBody(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (questionsLockedByStatus) ...[
                HuxCard(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        color: HuxTokens.iconSecondary(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr(
                            survey.status == SurveyStatus.published
                                ? 'This survey is published. Stop publishing before editing its questions.'
                                : 'This survey is archived. You cannot edit the questions.',
                          ),
                          style: TextStyle(
                            color: HuxTokens.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _buildSurveyForm(
                context,
                formManager,
                surveyListManager,
                controllers,
                surveyFormKey,
                formState,
                survey,
                isNewSurvey,
                activeDefaultLocale,
                activeLocales,
                aiGenerationEnabled,
                client,
              ),
              const SizedBox(height: 32),
              if (isNewSurvey) ...[
                DraftQuestionsSection(
                  formManager: formManager,
                  formState: formState,
                  aiGenerationEnabled: aiGenerationEnabled,
                  aiTranslateEnabled: aiGenerationEnabled,
                  onTranslate: aiGenerationEnabled
                      ? _translateWithClient(client)
                      : null,
                  primaryLocale: activeDefaultLocale,
                  locales: activeLocales,
                ),
                const SizedBox(height: 24),
                HuxButton(
                  onPressed: formState.isSaving
                      ? null
                      : () {
                          surveyFormKey.currentState?.submit();
                        },
                  isLoading: formState.isSaving,
                  width: HuxButtonWidth.expand,
                  icon: LucideIcons.plus,
                  child: Text(context.tr('Create Survey')),
                ),
              ] else
                QuestionList(
                  surveyId: surveyId!,
                  questions: questionState!.questions,
                  choicesByQuestion: questionState.choicesByQuestion,
                  visibilityRules: questionState.visibilityRules,
                  primaryLocale: activeDefaultLocale,
                  locales: activeLocales,
                  isLoading: questionState.isLoading,
                  enabled: canEditQuestions,
                  canChangeQuestionType: survey!.status == SurveyStatus.draft,
                  aiTranslateEnabled: aiGenerationEnabled && canEditQuestions,
                  onTranslate: aiGenerationEnabled && canEditQuestions
                      ? _translateWithClient(client)
                      : null,
                  onAddQuestion:
                      ({
                        required LocalizedText textTranslations,
                        required QuestionType type,
                        required bool isRequired,
                        required LocalizedText placeholderTranslations,
                        int? minLength,
                        int? maxLength,
                        int? minSelected,
                        int? maxSelected,
                        required VisibilityConditionMode
                        visibilityConditionMode,
                      }) {
                        questionManager.createQuestion(
                          surveyId: surveyId!,
                          textTranslations: textTranslations,
                          type: type,
                          isRequired: isRequired,
                          placeholderTranslations: placeholderTranslations,
                          minLength: minLength,
                          maxLength: maxLength,
                          minSelected: minSelected,
                          maxSelected: maxSelected,
                          visibilityConditionMode: visibilityConditionMode,
                        );
                      },
                  onEditQuestion:
                      (
                        question, {
                        required LocalizedText textTranslations,
                        required QuestionType type,
                        required bool isRequired,
                        required LocalizedText placeholderTranslations,
                        int? minLength,
                        int? maxLength,
                        int? minSelected,
                        int? maxSelected,
                        required VisibilityConditionMode
                        visibilityConditionMode,
                      }) {
                        final updated = Question(
                          id: question.id,
                          surveyId: question.surveyId,
                          textTranslations: textTranslations,
                          type: type,
                          orderIndex: question.orderIndex,
                          isRequired: isRequired,
                          placeholderTranslations: placeholderTranslations,
                          minLength: minLength,
                          maxLength: maxLength,
                          minSelected: minSelected,
                          maxSelected: maxSelected,
                          visibilityConditionMode: visibilityConditionMode,
                          isDeleted: question.isDeleted,
                        );
                        questionManager.updateQuestion(updated);
                      },
                  onDeleteQuestion: (question) {
                    questionManager.deleteQuestion(surveyId!, question.id!);
                  },
                  onAddChoice: (questionId, textTranslations) {
                    questionManager.createChoice(
                      questionId: questionId,
                      surveyId: surveyId!,
                      textTranslations: textTranslations,
                    );
                  },
                  onUpdateChoice: (choice, textTranslations) {
                    final updated = choice.copyWith(
                      textTranslations: textTranslations,
                    );
                    questionManager.updateChoice(updated, surveyId!);
                  },
                  onDeleteChoice: (choice) {
                    questionManager.deleteChoice(choice.id!, surveyId!);
                  },
                  onSaveVisibility:
                      ({
                        required question,
                        required mode,
                        required rules,
                      }) async {
                        await questionManager.saveVisibilityRules(
                          surveyId: surveyId!,
                          targetQuestion: question,
                          conditionMode: mode,
                          targetRules: rules,
                        );
                      },
                ),
              if (questionState?.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  context.trMessage(questionState!.error!),
                  style: TextStyle(
                    color: HuxTokens.textDestructive(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyForm(
    BuildContext context,
    SurveyFormManager formManager,
    SurveyListManager surveyListManager,
    SurveyFormControllers controllers,
    GlobalKey<SurveyFormWidgetState> surveyFormKey,
    SurveyFormState formState,
    Survey? survey,
    bool isNewSurvey,
    String primaryLocale,
    Iterable<String> locales,
    bool aiTranslateEnabled,
    Client client,
  ) => SurveyForm(
    key: surveyFormKey,
    controllers: controllers,
    existingSurvey: survey,
    isSaving: formState.isSaving,
    error: formState.error,
    primaryLocale: primaryLocale,
    locales: locales,
    showSubmitButton: !isNewSurvey,
    aiTranslateEnabled: aiTranslateEnabled,
    aiGenerationEnabled: aiTranslateEnabled,
    followUpEnabled: survey?.followUpEnabled ?? false,
    captchaEnabled: survey?.captchaConfigurationEnabled ?? true,
    onTranslate: aiTranslateEnabled ? _translateWithClient(client) : null,
    onSave:
        ({
          required String slug,
          required LocalizedText titleTranslations,
          required LocalizedText descriptionTranslations,
          required bool followUpEnabled,
          required String? followUpPrompt,
          required bool captchaEnabled,
        }) async {
          if (isNewSurvey) {
            final created = await formManager.createSurveyWithQuestions(
              projectId: projectId!,
              slug: slug,
              titleTranslations: titleTranslations,
              descriptionTranslations: descriptionTranslations,
              followUpEnabled: followUpEnabled,
              followUpPrompt: followUpPrompt,
              captchaEnabled: captchaEnabled,
            );
            if (created != null && context.mounted) {
              await surveyListManager.loadSurveys();
              if (context.mounted) {
                context.go('/admin');
              }
            }
          } else {
            final updated = survey!.copyWith(
              slug: slug,
              titleTranslations: titleTranslations,
              descriptionTranslations: descriptionTranslations,
              followUpEnabled: followUpEnabled,
              followUpPrompt: followUpPrompt,
              clearFollowUpPrompt: followUpPrompt == null,
              captchaConfigurationEnabled: captchaEnabled,
              updatedAt: DateTime.now(),
            );
            await formManager.updateSurvey(updated);
          }
        },
  );

  SurveyLocalizedTranslate _translateWithClient(Client client) =>
      ({
        required String sourceLocale,
        required String sourceText,
        required List<String> targetLocales,
        required String fieldKind,
      }) async {
        try {
          return await client.aiAdmin.translateLocalizedText(
            sourceLocale: sourceLocale,
            sourceText: sourceText,
            targetLocales: targetLocales,
            fieldKind: fieldKind,
          );
        } catch (error) {
          throw Exception('Failed to translate: $error');
        }
      };

  /// Returns true if the survey can be published.
  bool _canPublish(QuestionListState state) {
    if (state.questions.isEmpty) return false;

    for (final question in state.questions) {
      if (question.type.usesChoices) {
        final choices = state.choicesByQuestion[question.id] ?? [];
        if (choices.isEmpty) return false;
      }
    }

    return true;
  }

  Future<void> _publishSurvey(
    BuildContext context,
    SurveyListManager manager,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => HuxDialog(
        title: context.tr('Publish Survey'),
        content: Text(context.tr('Publish survey confirmation')),
        showCloseButton: false,
        actions: [
          HuxButton(
            onPressed: () => Navigator.pop(context, false),
            variant: HuxButtonVariant.secondary,
            child: Text(context.tr('Cancel')),
          ),
          HuxButton(
            onPressed: () => Navigator.pop(context, true),
            icon: LucideIcons.upload,
            child: Text(context.tr('Publish')),
          ),
        ],
      ),
    );

    if (confirmed == true && surveyId != null) {
      final success = await manager.publishSurvey(surveyId!);
      if (success && context.mounted) {
        context.go('/admin');
      }
    }
  }
}
