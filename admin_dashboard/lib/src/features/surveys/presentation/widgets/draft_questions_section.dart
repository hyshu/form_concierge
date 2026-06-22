import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/localization/app_localizations.dart';
import '../capsules/survey_form_capsule.dart';
import '../models/draft_question.dart';
import 'ai_prompt_input.dart';
import 'ai_question_preview_dialog.dart';
import 'draft_question_editor.dart';
import 'question_form_dialog.dart';

class DraftQuestionsSection extends StatelessWidget {
  const DraftQuestionsSection({
    super.key,
    required this.formManager,
    required this.formState,
    required this.geminiEnabled,
  });

  final SurveyFormManager formManager;
  final SurveyFormState formState;
  final bool geminiEnabled;

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
        if (draftQuestions.isEmpty && geminiEnabled)
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
                enabled: !formState.isSaving,
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
              OutlinedButton.icon(
                onPressed: formState.isSaving
                    ? null
                    : () => _showAddDialog(context),
                icon: const Icon(Icons.add),
                label: Text(context.tr('Add Question')),
              ),
            ],
          ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    QuestionFormDialog.show(
      context,
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
              firstChoiceTranslations: _defaultChoiceTranslations(1),
              secondChoiceTranslations: _defaultChoiceTranslations(2),
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

LocalizedText _defaultChoiceTranslations(int number) => LocalizedText({
  'en': 'Choice $number',
  'ja': '選択肢 $number',
  'zh-Hans': '选项 $number',
  'zh-Hant': '選項 $number',
  'ko': '선택지 $number',
  'de': 'Auswahl $number',
});

class _EmptyDraftQuestions extends StatelessWidget {
  const _EmptyDraftQuestions({required this.isSaving, required this.onAdd});

  final bool isSaving;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.help_outline,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('No questions yet'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('Add questions to your survey'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isSaving ? null : onAdd,
            icon: const Icon(Icons.add),
            label: Text(context.tr('Add Question')),
          ),
        ],
      ),
    );
  }
}
