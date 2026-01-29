import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'questions/question_widget.dart';

class SurveyContent extends StatelessWidget {
  final Survey survey;
  final List<Question> questions;
  final Map<int, List<QuestionOption>> optionsByQuestion;
  final Map<int, dynamic> answers;
  final Map<int, String> validationErrors;
  final String? errorMessage;
  final bool isSubmitting;
  final void Function(int questionId, dynamic value) onAnswerChanged;
  final VoidCallback onSubmit;

  const SurveyContent({
    super.key,
    required this.survey,
    required this.questions,
    required this.optionsByQuestion,
    required this.answers,
    required this.validationErrors,
    this.errorMessage,
    required this.isSubmitting,
    required this.onAnswerChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(survey.title, style: Theme.of(context).textTheme.headlineSmall),
          if (survey.description != null && survey.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              survey.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                errorMessage!,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...questions.map((question) {
            final options = optionsByQuestion[question.id] ?? [];
            final error = validationErrors[question.id];

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: QuestionWidget(
                question: question,
                options: options,
                value: answers[question.id],
                error: error,
                onChanged: (value) => onAnswerChanged(question.id!, value),
              ),
            );
          }),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
