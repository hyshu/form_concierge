import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

const int _kMaxTextResponsesPreview = 10;

/// Card displaying results for a single question.
class QuestionResultCard extends StatelessWidget {
  final QuestionResult result;
  final List<Choice> choices;
  final int totalResponses;

  const QuestionResultCard({
    super.key,
    required this.result,
    required this.choices,
    required this.totalResponses,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconForType(result.questionType),
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.questionText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (result.choiceCounts != null)
              _buildChoicesTable(context)
            else if (result.textResponses != null)
              _buildTextResponses(context),
          ],
        ),
      ),
    );
  }

  Widget _buildChoicesTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Sort choices by orderIndex
    final sortedChoices = List<Choice>.from(choices)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: colorScheme.outlineVariant),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text(
                'Choice',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text(
                'Count',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text(
                '%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        ...sortedChoices.map((choice) {
          final count = result.choiceCounts![choice.id] ?? 0;
          final percentage = totalResponses > 0
              ? (count / totalResponses * 100).toStringAsFixed(1)
              : '0.0';

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Text(choice.text),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Text(
                  '$percentage%',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTextResponses(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final responses = result.textResponses ?? [];

    if (responses.isEmpty) {
      return Text(
        'No text responses',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${responses.length} response${responses.length == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...responses
            .take(_kMaxTextResponsesPreview)
            .map(
              (response) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(response),
              ),
            ),
        if (responses.length > _kMaxTextResponsesPreview)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... and ${responses.length - _kMaxTextResponsesPreview} more responses',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
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
}
