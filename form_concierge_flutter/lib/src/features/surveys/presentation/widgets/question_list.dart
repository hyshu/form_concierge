import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/widgets/confirm_delete_dialog.dart';
import 'question_form_dialog.dart';
import 'question_list_tile.dart';

/// Widget displaying the list of questions for a survey.
class QuestionList extends StatelessWidget {
  final int surveyId;
  final List<Question> questions;
  final Map<int, List<QuestionOption>> optionsByQuestion;
  final bool isLoading;
  final bool enabled;
  final void Function({
    required String text,
    required QuestionType type,
    required bool isRequired,
    String? placeholder,
  })
  onAddQuestion;
  final void Function(
    Question question, {
    required String text,
    required QuestionType type,
    required bool isRequired,
    String? placeholder,
  })
  onEditQuestion;
  final void Function(Question question) onDeleteQuestion;
  final void Function(int questionId, String text) onAddOption;
  final void Function(QuestionOption option, String newText) onUpdateOption;
  final void Function(QuestionOption option) onDeleteOption;

  const QuestionList({
    super.key,
    required this.surveyId,
    required this.questions,
    required this.optionsByQuestion,
    required this.isLoading,
    required this.enabled,
    required this.onAddQuestion,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
    required this.onAddOption,
    required this.onUpdateOption,
    required this.onDeleteOption,
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
              'Questions',
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
                  'No questions yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add questions to your survey',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: enabled ? () => _showAddDialog(context) : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
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
                            options: optionsByQuestion[question.id] ?? [],
                            enabled: enabled,
                            onEdit: () => _showEditDialog(context, question),
                            onDelete: () => _confirmDelete(context, question),
                            onAddOption: (text) =>
                                onAddOption(question.id!, text),
                            onUpdateOption: onUpdateOption,
                            onDeleteOption: onDeleteOption,
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
                label: const Text('Add Question'),
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
            required String text,
            required QuestionType type,
            required bool isRequired,
            String? placeholder,
          }) {
            onAddQuestion(
              text: text,
              type: type,
              isRequired: isRequired,
              placeholder: placeholder,
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
            required String text,
            required QuestionType type,
            required bool isRequired,
            String? placeholder,
          }) {
            onEditQuestion(
              question,
              text: text,
              type: type,
              isRequired: isRequired,
              placeholder: placeholder,
            );
          },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Question question) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete Question',
      content:
          'Are you sure you want to delete this question?\n\n'
          '"${question.text}"\n\n'
          'This will also delete any responses to this question.',
    );

    if (confirmed) {
      onDeleteQuestion(question);
    }
  }
}
