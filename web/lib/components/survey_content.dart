import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import 'questions/question_widget.dart';

class SurveyContent extends StatelessComponent {
  const SurveyContent({
    required this.project,
    required this.survey,
    required this.questions,
    required this.choicesByQuestion,
    required this.answers,
    required this.validationErrors,
    required this.errorMessage,
    required this.locale,
    required this.isSubmitting,
    required this.onAnswerChanged,
    required this.onLocaleChanged,
    required this.onSubmit,
    super.key,
  });

  final Project project;
  final Survey survey;
  final List<Question> questions;
  final Map<int, List<Choice>> choicesByQuestion;
  final Map<int, dynamic> answers;
  final Map<int, String> validationErrors;
  final String? errorMessage;
  final String locale;
  final bool isSubmitting;
  final void Function(int questionId, dynamic value) onAnswerChanged;
  final void Function(String locale) onLocaleChanged;
  final void Function() onSubmit;

  @override
  Component build(BuildContext context) {
    return div(classes: 'max-w-xl mx-auto', [
      // Header card with accent border
      div(
          classes:
              'bg-white rounded-xl shadow-md border border-slate-200 overflow-hidden mb-6',
          [
            // Accent top border
            div(classes: 'h-2', []),
            // Content
            div(classes: 'p-6', [
              h1(classes: 'text-xl font-semibold text-slate-900', [
                Component.text(survey.titleFor(locale)),
              ]),
              if (survey.descriptionFor(locale).isNotEmpty)
                p(classes: 'mt-2 text-sm text-slate-600 leading-relaxed', [
                  Component.text(survey.descriptionFor(locale)),
                ]),
              if (project.supportedLocales.length > 1)
                div(classes: 'mt-4 flex flex-wrap gap-2', [
                  for (final option in project.supportedLocales)
                    button(
                      [Component.text(formContentLocaleLabels[option]!)],
                      classes:
                          'px-3 py-1.5 rounded-lg border text-xs font-medium ${option == locale ? 'border-indigo-600 bg-indigo-50 text-indigo-700' : 'border-slate-200 text-slate-600 hover:border-slate-300'}',
                      onClick: () => onLocaleChanged(option),
                    ),
                ]),
            ]),
          ]),

      // Error message
      if (errorMessage != null)
        div(
            classes:
                'flex items-start gap-3 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl mb-6',
            [
              span(classes: 'text-red-500 flex-shrink-0', [
                Component.text('\u26A0'),
              ]),
              span(classes: 'text-sm', [Component.text(errorMessage!)]),
            ]),

      // Questions
      div(classes: 'space-y-5', [
        for (final question in questions)
          QuestionWidget(
            question: question,
            choices: choicesByQuestion[question.id] ?? [],
            value: answers[question.id],
            error: validationErrors[question.id],
            locale: locale,
            onChanged: (value) => onAnswerChanged(question.id!, value),
          ),
      ]),

      // Submit button
      div(classes: 'mt-8', [
        button(
          [
            if (isSubmitting)
              span(classes: 'inline-block animate-spin mr-2', [
                Component.text('\u21BB'),
              ]),
            Component.text(
              FormContentMessages.text(
                locale,
                isSubmitting ? 'submitting' : 'submit',
              ),
            ),
          ],
          classes:
              'w-full py-3 px-6 bg-indigo-600 text-white font-medium rounded-xl hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm',
          disabled: isSubmitting,
          onClick: isSubmitting ? null : () => onSubmit(),
        ),
      ]),
    ]);
  }
}
