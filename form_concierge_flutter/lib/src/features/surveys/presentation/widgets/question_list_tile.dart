import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'option_editor.dart';

/// List tile for displaying a question with its options.
class QuestionListTile extends StatelessWidget {
  final Question question;
  final List<QuestionOption> options;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(String text) onAddOption;
  final void Function(QuestionOption option, String newText) onUpdateOption;
  final void Function(QuestionOption option) onDeleteOption;

  const QuestionListTile({
    super.key,
    required this.question,
    required this.options,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
    required this.onAddOption,
    required this.onUpdateOption,
    required this.onDeleteOption,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isChoiceType =
        question.type == QuestionType.singleChoice ||
        question.type == QuestionType.multipleChoice;

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
                  _iconForType(question.type),
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
                        _labelForType(question.type),
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
            if (isChoiceType) ...[
              const SizedBox(height: 16),
              OptionEditor(
                options: options,
                enabled: enabled,
                onAdd: onAddOption,
                onUpdate: onUpdateOption,
                onDelete: onDeleteOption,
              ),
            ],
            if (!isChoiceType && question.placeholder != null) ...[
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

  IconData _iconForType(QuestionType type) {
    return switch (type) {
      QuestionType.singleChoice => Icons.radio_button_checked,
      QuestionType.multipleChoice => Icons.check_box,
      QuestionType.textSingle => Icons.short_text,
      QuestionType.textMultiLine => Icons.notes,
    };
  }

  String _labelForType(QuestionType type) {
    return switch (type) {
      QuestionType.singleChoice => 'Single Choice',
      QuestionType.multipleChoice => 'Multiple Choice',
      QuestionType.textSingle => 'Short Text',
      QuestionType.textMultiLine => 'Long Text',
    };
  }
}
