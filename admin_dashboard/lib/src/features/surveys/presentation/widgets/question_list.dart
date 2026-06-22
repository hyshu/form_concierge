import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import 'question_form_dialog.dart';
import 'question_list_tile.dart';
import 'visibility_rule_editor.dart';

/// Widget displaying the list of questions for a survey.
class QuestionList extends StatelessWidget {
  final int surveyId;
  final List<Question> questions;
  final Map<int, List<Choice>> choicesByQuestion;
  final List<QuestionVisibilityRule> visibilityRules;
  final bool isLoading;
  final bool enabled;
  final void Function({
    required LocalizedText textTranslations,
    required QuestionType type,
    required bool isRequired,
    required LocalizedText placeholderTranslations,
    int? minLength,
    int? maxLength,
    int? minSelected,
    int? maxSelected,
    required VisibilityConditionMode visibilityConditionMode,
  })
  onAddQuestion;
  final void Function(
    Question question, {
    required LocalizedText textTranslations,
    required QuestionType type,
    required bool isRequired,
    required LocalizedText placeholderTranslations,
    int? minLength,
    int? maxLength,
    int? minSelected,
    int? maxSelected,
    required VisibilityConditionMode visibilityConditionMode,
  })
  onEditQuestion;
  final void Function(Question question) onDeleteQuestion;
  final void Function(int questionId, LocalizedText textTranslations)
  onAddChoice;
  final void Function(Choice choice, LocalizedText textTranslations)
  onUpdateChoice;
  final void Function(Choice choice) onDeleteChoice;
  final Future<void> Function({
    required Question question,
    required VisibilityConditionMode mode,
    required List<QuestionVisibilityRule> rules,
  })
  onSaveVisibility;

  const QuestionList({
    super.key,
    required this.surveyId,
    required this.questions,
    required this.choicesByQuestion,
    required this.visibilityRules,
    required this.isLoading,
    required this.enabled,
    required this.onAddQuestion,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
    required this.onAddChoice,
    required this.onUpdateChoice,
    required this.onDeleteChoice,
    required this.onSaveVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (questions.isEmpty)
          Container(
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
                  onPressed: enabled ? () => _showAddDialog(context) : null,
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('Add Question')),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              ...questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final questionRules = visibilityRules
                    .where((rule) => rule.targetQuestionId == question.id)
                    .toList();
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuestionListTile(
                            question: question,
                            choices: choicesByQuestion[question.id] ?? [],
                            visibilityRules: questionRules,
                            visibilityRuleEditor: VisibilityRuleEditor(
                              surveyId: surveyId,
                              targetQuestion: question,
                              sourceQuestions: questions
                                  .where(
                                    (candidate) =>
                                        candidate.orderIndex <
                                        question.orderIndex,
                                  )
                                  .toList(),
                              choicesByQuestion: choicesByQuestion,
                              rules: questionRules,
                              enabled: enabled,
                              onSave: ({required mode, required rules}) =>
                                  onSaveVisibility(
                                    question: question,
                                    mode: mode,
                                    rules: rules,
                                  ),
                            ),
                            enabled: enabled,
                            onEdit: () => _showEditDialog(context, question),
                            onDelete: () => _confirmDelete(context, question),
                            onAddChoice: (text) =>
                                onAddChoice(question.id!, text),
                            onUpdateChoice: onUpdateChoice,
                            onDeleteChoice: onDeleteChoice,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: enabled ? () => _showAddDialog(context) : null,
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
            onAddQuestion(
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
    );
  }

  void _showEditDialog(BuildContext context, Question question) {
    QuestionFormDialog.show(
      context,
      existingQuestion: question,
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
            onEditQuestion(
              question,
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
    );
  }

  Future<void> _confirmDelete(BuildContext context, Question question) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: context.tr('Delete Question'),
      content: context.tr('Delete question confirmation', {
        'question': question.text,
      }),
    );

    if (confirmed) {
      onDeleteQuestion(question);
    }
  }
}
