import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'questions/question_widget.dart';

class SurveyContent extends StatelessWidget {
  final Survey survey;
  final List<Question> questions;
  final Map<int, List<Choice>> choicesByQuestion;
  final Map<int, dynamic> answers;
  final Map<int, String> validationErrors;
  final String? errorMessage;
  final String locale;
  final bool isSubmitting;
  final void Function(int questionId, dynamic value) onAnswerChanged;
  final ValueChanged<String> onLocaleChanged;
  final VoidCallback onSubmit;

  const SurveyContent({
    super.key,
    required this.survey,
    required this.questions,
    required this.choicesByQuestion,
    required this.answers,
    required this.validationErrors,
    this.errorMessage,
    required this.locale,
    required this.isSubmitting,
    required this.onAnswerChanged,
    required this.onLocaleChanged,
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
          Text(
            survey.titleFor(locale),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (survey.descriptionFor(locale).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              survey.descriptionFor(locale),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (survey.supportedLocales.length > 1) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: locale,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final option in survey.supportedLocales)
                  DropdownMenuItem(
                    value: option,
                    child: Text(formContentLocaleLabels[option]!),
                  ),
              ],
              onChanged: isSubmitting
                  ? null
                  : (value) {
                      if (value != null) onLocaleChanged(value);
                    },
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
            final choices = choicesByQuestion[question.id] ?? [];
            final error = validationErrors[question.id];

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: QuestionWidget(
                question: question,
                choices: choices,
                value: answers[question.id],
                error: error,
                locale: locale,
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
                : Text(FormContentMessages.text(locale, 'submit')),
          ),
        ],
      ),
    );
  }
}
