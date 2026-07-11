import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import 'single_choice_question.dart';
import 'multiple_choice_question.dart';
import 'text_single_question.dart';
import 'text_multi_line_question.dart';
import 'image_upload_question.dart';

class QuestionWidget extends StatelessComponent {
  const QuestionWidget({
    required this.question,
    required this.choices,
    required this.value,
    required this.error,
    required this.locale,
    required this.onChanged,
    required this.client,
    required this.ensureAuthenticated,
    this.disabled = false,
    super.key,
  });

  final Question question;
  final List<Choice> choices;
  final AnswerValue value;
  final String? error;
  final String locale;

  /// Disables all inputs (e.g. while the response is being submitted, so the
  /// visible form cannot drift from the payload in flight).
  final bool disabled;

  final void Function(AnswerValue value) onChanged;
  final Client client;
  final Future<void> Function() ensureAuthenticated;

  bool get _isChoiceGroup =>
      question.type == QuestionType.singleChoice ||
      question.type == QuestionType.multipleChoice;

  String get _errorId => 'question_${question.id}_error';

  @override
  Component build(context) {
    final hasError = error != null;
    final labelChildren = [
      span(classes: 'text-sm font-medium text-slate-800', [
        Component.text(question.textFor(locale)),
      ]),
      if (question.isRequired)
        span(
          classes: 'text-red-500 ml-1 text-sm',
          attributes: const {'aria-hidden': 'true'},
          [Component.text('*')],
        ),
    ];

    final body = [
      // Question input based on type
      _buildQuestionInput(),

      // Error message (assertive live region so screen readers announce it)
      if (hasError)
        div(
            id: _errorId,
            classes: 'mt-3 flex items-center gap-2 text-sm text-red-600',
            attributes: const {'role': 'alert'},
            [
              span(
                classes: 'flex-shrink-0',
                attributes: const {'aria-hidden': 'true'},
                [Component.text('⚠')],
              ),
              span([Component.text(error!)]),
            ]),
    ];

    return div(
        id: 'question_card_${question.id}',
        classes:
            'bg-white rounded-xl shadow-md border ${hasError ? 'border-red-300' : 'border-slate-200'} p-5',
        [
          if (_isChoiceGroup)
            fieldset(
              attributes: {
                if (hasError) 'aria-describedby': _errorId,
                if (question.isRequired) 'aria-required': 'true',
              },
              [
                legend(classes: 'mb-4', labelChildren),
                ...body,
              ],
            )
          else if (question.type == QuestionType.imageUpload) ...[
            // The picker renders its own <label>; this is just the heading.
            div(classes: 'mb-4', labelChildren),
            ...body,
          ] else ...[
            label(
              classes: 'block mb-4',
              attributes: {'for': 'question_${question.id}'},
              labelChildren,
            ),
            ...body,
          ],
        ]);
  }

  Component _buildQuestionInput() => switch (question.type) {
        QuestionType.singleChoice => SingleChoiceQuestion(
            question: question,
            choices: choices,
            value: value as int?,
            locale: locale,
            onChanged: onChanged,
            disabled: disabled,
          ),
        QuestionType.multipleChoice => MultipleChoiceQuestion(
            question: question,
            choices: choices,
            value: (value as List<dynamic>?)?.cast<int>() ?? [],
            locale: locale,
            onChanged: onChanged,
            disabled: disabled,
          ),
        QuestionType.textSingle => TextSingleQuestion(
            question: question,
            value: value as String?,
            locale: locale,
            onChanged: onChanged,
            disabled: disabled,
            invalid: error != null,
            describedById: error != null ? _errorId : null,
          ),
        QuestionType.textMultiLine => TextMultiLineQuestion(
            question: question,
            value: value as String?,
            locale: locale,
            onChanged: onChanged,
            disabled: disabled,
            invalid: error != null,
            describedById: error != null ? _errorId : null,
          ),
        QuestionType.imageUpload => ImageUploadQuestion(
            client: client,
            question: question,
            value: (value as List<String>?) ?? const [],
            locale: locale,
            onChanged: onChanged,
            ensureAuthenticated: ensureAuthenticated,
            disabled: disabled,
          ),
      };
}
