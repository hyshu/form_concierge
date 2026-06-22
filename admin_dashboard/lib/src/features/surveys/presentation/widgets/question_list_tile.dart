import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/extensions/question_type_presentation.dart';
import 'choice_editor.dart';

/// List tile for displaying a question with its choices.
class QuestionListTile extends StatelessWidget {
  final Question question;
  final List<Choice> choices;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(String text) onAddChoice;
  final void Function(Choice choice, String newText) onUpdateChoice;
  final void Function(Choice choice) onDeleteChoice;

  const QuestionListTile({
    super.key,
    required this.question,
    required this.choices,
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
                        question.type.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled) ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                    tooltip: 'Edit question',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    onPressed: onDelete,
                    tooltip: 'Delete question',
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
                'Placeholder: ${question.placeholder}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
