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

  @override
  Component build(context) {
    final hasError = error != null;
    return div(
        classes:
            'bg-white rounded-xl shadow-md border ${hasError ? 'border-red-300' : 'border-slate-200'} p-5',
        [
          // Question label
          div(classes: 'mb-4', [
            span(classes: 'text-sm font-medium text-slate-800', [
              Component.text(question.textFor(locale)),
            ]),
            if (question.isRequired)
              span(classes: 'text-red-500 ml-1 text-sm', [Component.text('*')]),
          ]),

          // Question input based on type
          _buildQuestionInput(),

          // Error message
          if (hasError)
            div(classes: 'mt-3 flex items-center gap-2 text-sm text-red-600', [
              span(classes: 'flex-shrink-0', [Component.text('\u26A0')]),
              span([Component.text(error!)]),
            ]),
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
          ),
        QuestionType.textMultiLine => TextMultiLineQuestion(
            question: question,
            value: value as String?,
            locale: locale,
            onChanged: onChanged,
            disabled: disabled,
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
