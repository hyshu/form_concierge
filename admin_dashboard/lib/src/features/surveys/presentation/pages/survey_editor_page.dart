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

  const SurveyEditorPage({super.key, this.surveyId});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final formManager = use(surveyFormManagerCapsule);
    final questionManager = use(questionListManagerCapsule);
    final surveyListManager = use(surveyListCapsule);
    final controllers = use(surveyFormControllersCapsule);
    final publicConfig = use(publicConfigCapsule);
    final client = use(clientCapsule);
    final (defaultLocaleOverride, setDefaultLocaleOverride) = use
        .state<String?>(null);

    final isNewSurvey = surveyId == null;
    final formState = formManager.getState(surveyId);
    final questionState = isNewSurvey
        ? null
        : questionManager.getState(surveyId!);
    final geminiEnabled = publicConfig.state.geminiEnabled;
    final role = client.auth.signedInUser?.role;
    final canWriteSurveys = role == AdminRole.admin || role == AdminRole.editor;
    final canManageUsers = role == AdminRole.admin;

    // Load survey and questions on first build (only for existing surveys)
    if (use.isFirstBuild() && !isNewSurvey) {
      formManager.loadSurvey(surveyId!);
      questionManager.loadQuestions(surveyId!);
    }

    // Populate form when survey is loaded (track previous to detect change)
    final prevSurvey = use.previous(formState.survey);
    if (formState.survey != null && prevSurvey == null) {
      // Schedule for after build to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controllers.populateFrom(formState.survey!);
      });
    }

    if (!isNewSurvey &&
        (formState.isLoading ||
            (formState.survey == null && formState.error == null))) {
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
    final activeDefaultLocale =
        defaultLocaleOverride ??
        survey?.defaultLocale ??
        defaultFormContentLocale;
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

    final canEdit =
        canWriteSurveys &&
        (isNewSurvey || survey!.status != SurveyStatus.archived);

    return HuxAdminShell(
      title: isNewSurvey ? context.tr('New Survey') : survey!.title,
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
              if (!isNewSurvey && !canEdit) ...[
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
                            'This survey is archived. You cannot edit the questions.',
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
                formState,
                survey,
                isNewSurvey,
                onDefaultLocaleChanged: setDefaultLocaleOverride,
              ),
              const SizedBox(height: 48),
              if (isNewSurvey)
                DraftQuestionsSection(
                  formManager: formManager,
                  formState: formState,
                  geminiEnabled: geminiEnabled,
                  primaryLocale: activeDefaultLocale,
                )
              else
                QuestionList(
                  surveyId: surveyId!,
                  questions: questionState!.questions,
                  choicesByQuestion: questionState.choicesByQuestion,
                  visibilityRules: questionState.visibilityRules,
                  primaryLocale: activeDefaultLocale,
                  isLoading: questionState.isLoading,
                  enabled: canEdit,
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
    SurveyFormState formState,
    Survey? survey,
    bool isNewSurvey, {
    required void Function(String? locale) onDefaultLocaleChanged,
  }) {
    return SurveyForm(
      controllers: controllers,
      existingSurvey: survey,
      isSaving: formState.isSaving,
      error: formState.error,
      onDefaultLocaleChanged: onDefaultLocaleChanged,
      onSave:
          ({
            required String defaultLocale,
            required String slug,
            required String? customDomain,
            required LocalizedText titleTranslations,
            required LocalizedText descriptionTranslations,
          }) async {
            if (isNewSurvey) {
              final created = await formManager.createSurveyWithQuestions(
                defaultLocale: defaultLocale,
                slug: slug,
                customDomain: customDomain,
                titleTranslations: titleTranslations,
                descriptionTranslations: descriptionTranslations,
              );
              if (created != null && context.mounted) {
                await surveyListManager.loadSurveys();
                if (context.mounted) {
                  context.go('/admin');
                }
              }
            } else {
              final updated = survey!.copyWith(
                defaultLocale: defaultLocale,
                slug: slug,
                customDomain: customDomain,
                clearCustomDomain: customDomain == null,
                titleTranslations: titleTranslations,
                descriptionTranslations: descriptionTranslations,
                updatedAt: DateTime.now(),
              );
              await formManager.updateSurvey(updated);
            }
          },
    );
  }

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
