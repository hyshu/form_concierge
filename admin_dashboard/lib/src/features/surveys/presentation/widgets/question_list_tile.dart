import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/extensions/question_type_presentation.dart';
import '../../../../core/localization/app_localizations.dart';
import 'choice_editor.dart';

/// List tile for displaying a question with its choices.
class QuestionListTile extends StatelessWidget {
  final Question question;
  final List<Choice> choices;
  final List<QuestionVisibilityRule> visibilityRules;
  final Widget visibilityRuleEditor;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(LocalizedText textTranslations) onAddChoice;
  final void Function(Choice choice, LocalizedText textTranslations)
  onUpdateChoice;
  final void Function(Choice choice) onDeleteChoice;

  const QuestionListTile({
    super.key,
    required this.question,
    required this.choices,
    required this.visibilityRules,
    required this.visibilityRuleEditor,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
    required this.onAddChoice,
    required this.onUpdateChoice,
    required this.onDeleteChoice,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final usesChoices = question.type.usesChoices;
    final validationSummary = _validationSummary(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  question.type.icon,
                  size: 24,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              question.text,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (question.isRequired)
                            Text(
                              '*',
                              style: TextStyle(
                                color: colorScheme.error,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(question.type.label),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (validationSummary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          validationSummary,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                      if (visibilityRules.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.tr(
                            visibilityRules.length == 1
                                ? 'Visible when {count} rule matches'
                                : 'Visible when {count} rules match',
                            {'count': visibilityRules.length},
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.primary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (enabled) ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                    tooltip: context.tr('Edit question'),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    onPressed: onDelete,
                    tooltip: context.tr('Delete question'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            if (usesChoices) ...[
              const SizedBox(height: 16),
              ChoiceEditor(
                choices: choices,
                enabled: enabled,
                onAdd: onAddChoice,
                onUpdate: onUpdateChoice,
                onDelete: onDeleteChoice,
              ),
            ],
            if (!usesChoices && question.placeholder != null) ...[
              const SizedBox(height: 8),
              Text(
                context.tr('Placeholder: {placeholder}', {
                  'placeholder': question.placeholder,
                }),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            visibilityRuleEditor,
          ],
        ),
      ),
    );
  }

  String? _validationSummary(BuildContext context) {
    if (question.type.usesTextAnswer) {
      final parts = [
        if (question.minLength != null)
          context.tr('min {value}', {'value': question.minLength}),
        if (question.maxLength != null)
          context.tr('max {value}', {'value': question.maxLength}),
      ];
      return parts.isEmpty
          ? null
          : context.tr('Length: {summary}', {'summary': parts.join(', ')});
    }
    if (question.type == QuestionType.multipleChoice) {
      final parts = [
        if (question.minSelected != null)
          context.tr('min {value}', {'value': question.minSelected}),
        if (question.maxSelected != null)
          context.tr('max {value}', {'value': question.maxSelected}),
      ];
      return parts.isEmpty
          ? null
          : context.tr('Selections: {summary}', {'summary': parts.join(', ')});
    }
    return null;
  }
}
