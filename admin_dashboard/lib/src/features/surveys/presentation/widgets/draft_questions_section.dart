import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_states.dart';
import '../capsules/survey_form_capsule.dart';
import '../models/draft_question.dart';
import 'ai_prompt_input.dart';
import 'ai_question_preview_dialog.dart';
import 'draft_question_editor.dart';
import 'localized_text_helpers.dart';
import 'question_form_dialog.dart';
import 'survey_form.dart';

class DraftQuestionsSection extends StatelessWidget {
  const DraftQuestionsSection({
    super.key,
    required this.formManager,
    required this.formState,
    required this.aiGenerationEnabled,
    this.aiTranslateEnabled = false,
    this.onTranslate,
    required this.primaryLocale,
    required this.locales,
  });

  final SurveyFormManager formManager;
  final SurveyFormState formState;
  final bool aiGenerationEnabled;
  final bool aiTranslateEnabled;
  final SurveyLocalizedTranslate? onTranslate;
  final String primaryLocale;
  final Iterable<String> locales;

  @override
  Widget build(BuildContext context) {
    final draftQuestions = formState.draftQuestions;

    if (formState.generatedQuestions != null &&
        formState.generatedQuestions!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AiQuestionPreviewDialog.show(
          context,
          questions: formState.generatedQuestions!,
          onApply: formManager.applyGeneratedQuestions,
          onCancel: formManager.clearGeneratedQuestions,
        );
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.tr('Questions'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16),
        if (draftQuestions.isEmpty && aiGenerationEnabled)
          AiPromptInput(
            isGenerating: formState.isGenerating,
            error: formState.generationError,
            onGenerate: formManager.generateQuestions,
            onAddManually: () => _showAddDialog(context),
            isSaving: formState.isSaving,
          )
        else if (draftQuestions.isEmpty)
          _EmptyDraftQuestions(
            isSaving: formState.isSaving,
            onAdd: () => _showAddDialog(context),
          )
        else
          Column(
            children: [
              DraftQuestionEditor(
                questions: draftQuestions,
                primaryLocale: primaryLocale,
                locales: locales,
                enabled: !formState.isSaving,
                aiTranslateEnabled: aiTranslateEnabled,
                onTranslate: onTranslate,
                onEdit: (question) => _showEditDialog(context, question),
                onDelete: (question) =>
                    formManager.deleteDraftQuestion(question.tempId),
                onReorder: formManager.reorderDraftQuestions,
                onAddChoice: (question, textTranslations) =>
                    formManager.addChoiceToDraftQuestion(
                      question.tempId,
                      textTranslations,
                    ),
                onUpdateChoice: (question, choice, textTranslations) =>
                    formManager.updateDraftChoice(
                      question.tempId,
                      choice.tempId,
                      textTranslations,
                    ),
                onDeleteChoice: (question, choice) => formManager
                    .deleteDraftChoice(question.tempId, choice.tempId),
              ),
              const SizedBox(height: 16),
              HuxButton(
                onPressed: formState.isSaving
                    ? null
                    : () => _showAddDialog(context),
                variant: HuxButtonVariant.outline,
                icon: LucideIcons.plus,
                child: Text(context.tr('Add Question')),
              ),
            ],
          ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    QuestionFormDialog.show(
      context,
      primaryLocale: primaryLocale,
      locales: locales,
      aiTranslateEnabled: aiTranslateEnabled,
      onTranslate: onTranslate,
      onSave:
          ({
            required LocalizedText textTranslations,
            required QuestionType type,
            required bool isRequired,
            required LocalizedText placeholderTranslations,
            int? minLength,
            int? maxLength,
            int? minSelected,
            int? maxSelected,
            required VisibilityConditionMode visibilityConditionMode,
          }) {
            formManager.addDraftQuestion(
              textTranslations: textTranslations,
              type: type,
              isRequired: isRequired,
              placeholderTranslations: placeholderTranslations,
              minLength: minLength,
              maxLength: maxLength,
              minSelected: minSelected,
              maxSelected: maxSelected,
              firstChoiceTranslations: _defaultChoiceTranslations(1, locales),
              secondChoiceTranslations: _defaultChoiceTranslations(2, locales),
            );
          },
    );
  }

  void _showEditDialog(BuildContext context, DraftQuestion question) {
    final tempQuestion = Question(
      surveyId: 0,
      textTranslations: question.textTranslations,
      type: question.type,
      orderIndex: 0,
      isRequired: question.isRequired,
      placeholderTranslations: question.placeholderTranslations,
      minLength: question.minLength,
      maxLength: question.maxLength,
      minSelected: question.minSelected,
      maxSelected: question.maxSelected,
    );

    QuestionFormDialog.show(
      context,
      existingQuestion: tempQuestion,
      primaryLocale: primaryLocale,
      locales: locales,
      aiTranslateEnabled: aiTranslateEnabled,
      onTranslate: onTranslate,
      onSave:
          ({
            required LocalizedText textTranslations,
            required QuestionType type,
            required bool isRequired,
            required LocalizedText placeholderTranslations,
            int? minLength,
            int? maxLength,
            int? minSelected,
            int? maxSelected,
            required VisibilityConditionMode visibilityConditionMode,
          }) {
            formManager.updateDraftQuestion(
              tempId: question.tempId,
              textTranslations: textTranslations,
              type: type,
              isRequired: isRequired,
              placeholderTranslations: placeholderTranslations,
              minLength: minLength,
              maxLength: maxLength,
              minSelected: minSelected,
              maxSelected: maxSelected,
            );
          },
    );
  }
}

LocalizedText _defaultChoiceTranslations(
  int number,
  Iterable<String> locales,
) {
  final labels = {
    'en': 'Choice $number',
    'ja': '選択肢 $number',
    'zh-Hans': '选项 $number',
    'zh-Hant': '選項 $number',
    'ko': '선택지 $number',
    'de': 'Auswahl $number',
    'es': 'Opción $number',
    'fr': 'Choix $number',
    'it': 'Scelta $number',
    'th': 'ตัวเลือก $number',
    'tr': 'Seçenek $number',
  };
  return LocalizedText({
    for (final locale in orderedFormContentLocales(locales))
      locale: labels[locale] ?? 'Choice $number',
  });
}

class _EmptyDraftQuestions extends StatelessWidget {
  const _EmptyDraftQuestions({required this.isSaving, required this.onAdd});

  final bool isSaving;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return HuxEmptyState(
      icon: LucideIcons.circleHelp,
      title: context.tr('No questions yet'),
      message: context.tr('Add questions to your survey'),
      action: HuxButton(
        onPressed: isSaving ? null : onAdd,
        icon: LucideIcons.plus,
        child: Text(context.tr('Add Question')),
      ),
    );
  }
}
