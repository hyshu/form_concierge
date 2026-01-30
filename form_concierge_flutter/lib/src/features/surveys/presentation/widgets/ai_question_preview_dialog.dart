import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../models/draft_question.dart';

/// Dialog for previewing AI-generated questions before applying them.
class AiQuestionPreviewDialog extends StatelessWidget {
  final List<DraftQuestion> questions;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  const AiQuestionPreviewDialog({
    super.key,
    required this.questions,
    required this.onApply,
    required this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required List<DraftQuestion> questions,
    required VoidCallback onApply,
    required VoidCallback onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AiQuestionPreviewDialog(
        questions: questions,
        onApply: onApply,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Generated Questions'),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${questions.length} questions generated. Review and apply to your survey.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: questions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return _QuestionPreviewTile(
                    index: index + 1,
                    question: question,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel();
          },
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onApply();
          },
          icon: const Icon(Icons.check),
          label: const Text('Apply'),
        ),
      ],
    );
  }
}

class _QuestionPreviewTile extends StatelessWidget {
  final int index;
  final DraftQuestion question;

  const _QuestionPreviewTile({
    required this.index,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _iconForType(question.type),
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _labelForType(question.type),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (question.isRequired) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Required',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  question.text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (question.hasChoices && question.choices.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: question.choices.map((choice) {
                      return Chip(
                        label: Text(
                          choice.text,
                          style: const TextStyle(fontSize: 12),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
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
