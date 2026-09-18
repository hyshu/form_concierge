import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/hux_states.dart';
import 'question_form_dialog.dart';
import 'question_list_tile.dart';
import 'survey_form.dart';
import 'visibility_rule_editor.dart';

/// Widget displaying the list of questions for a survey.
class QuestionList extends StatelessWidget {
  /// The identifier of the associated survey.
  final int surveyId;

  /// The survey questions in display order.
  final List<Question> questions;

  /// Available choices indexed by question identifier.
  final Map<int, List<Choice>> choicesByQuestion;

  /// Conditions that determine which questions are visible.
  final List<QuestionVisibilityRule> visibilityRules;

  /// The main locale used to display and edit localized content.
  final String primaryLocale;

  /// The locales available for editing or displaying translated content.
  final Iterable<String> locales;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// Whether the control is available for interaction.
  final bool enabled;

  /// Whether existing questions may be changed to a different input type.
  final bool canChangeQuestionType;

  /// Whether AI-assisted translation controls are available.
  final bool aiTranslateEnabled;

  /// Called when the user requests a translation of the displayed content.
  final SurveyLocalizedTranslate? onTranslate;

  /// Called with the definition of a new question to add.
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

  /// Called with the revised definition of an existing question.
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

  /// Called when a survey question should be removed.
  final void Function(Question question) onDeleteQuestion;

  /// Called when a new localized choice should be added to a question.
  final void Function(int questionId, LocalizedText textTranslations)
  onAddChoice;

  /// Called when an existing choice's localized text should be replaced.
  final void Function(Choice choice, LocalizedText textTranslations)
  onUpdateChoice;

  /// Called when an existing choice should be removed.
  final void Function(Choice choice) onDeleteChoice;

  /// Called with the revised visibility mode and rules for a question.
  final Future<void> Function({
    required Question question,
    required VisibilityConditionMode mode,
    required List<QuestionVisibilityRule> rules,
  })
  onSaveVisibility;

  /// Creates QuestionList with the supplied values.
  const QuestionList({
    super.key,
    required this.surveyId,
    required this.questions,
    required this.choicesByQuestion,
    required this.visibilityRules,
    this.primaryLocale = defaultFormContentLocale,
    this.locales = formContentLocaleCodes,
    required this.isLoading,
    required this.enabled,
    this.canChangeQuestionType = true,
    this.aiTranslateEnabled = false,
    this.onTranslate,
    required this.onAddQuestion,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
    required this.onAddChoice,
    required this.onUpdateChoice,
    required this.onDeleteChoice,
    required this.onSaveVisibility,
  });

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            context.tr('Questions'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          if (isLoading) const HuxLoading(size: HuxLoadingSize.small),
        ],
      ),
      const SizedBox(height: 16),
      if (isLoading && questions.isEmpty)
        HuxLoadingState(
          message: context.tr('Loading...'),
          size: HuxLoadingSize.medium,
          padding: EdgeInsets.zero,
        )
      else if (questions.isEmpty)
        HuxEmptyState(
          icon: LucideIcons.circleHelp,
          title: context.tr('No questions yet'),
          message: context.tr('Add questions to your survey'),
          action: HuxButton(
            onPressed: enabled ? () => _showAddDialog(context) : null,
            icon: LucideIcons.plus,
            child: Text(context.tr('Add Question')),
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
                          color: HuxTokens.primary(
                            context,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: HuxTokens.primary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuestionListTile(
                          question: question,
                          choices: choicesByQuestion[question.id] ?? [],
                          primaryLocale: primaryLocale,
                          locales: locales,
                          visibilityRules: questionRules,
                          visibilityRuleEditor: VisibilityRuleEditor(
                            surveyId: surveyId,
                            targetQuestion: question,
                            primaryLocale: primaryLocale,
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
                          aiTranslateEnabled: aiTranslateEnabled,
                          onTranslate: onTranslate,
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
            HuxButton(
              onPressed: enabled ? () => _showAddDialog(context) : null,
              variant: HuxButtonVariant.outline,
              icon: LucideIcons.plus,
              child: Text(context.tr('Add Question')),
            ),
          ],
        ),
    ],
  );

  void _showAddDialog(BuildContext context) => QuestionFormDialog.show(
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

  void _showEditDialog(BuildContext context, Question question) =>
      QuestionFormDialog.show(
        context,
        existingQuestion: question,
        canChangeType: canChangeQuestionType,
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

  Future<void> _confirmDelete(BuildContext context, Question question) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: context.tr('Delete Question'),
      content: context.tr('Delete question confirmation', {
        'question': question.textFor(primaryLocale),
      }),
    );

    if (confirmed) onDeleteQuestion(question);
  }
}
