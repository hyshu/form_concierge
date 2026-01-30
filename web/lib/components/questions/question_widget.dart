import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import 'single_choice_question.dart';
import 'multiple_choice_question.dart';
import 'text_single_question.dart';
import 'text_multi_line_question.dart';

class QuestionWidget extends StatelessComponent {
  const QuestionWidget({
    required this.question,
    required this.choices,
    required this.value,
    required this.error,
    required this.onChanged,
    super.key,
  });

  final Question question;
  final List<Choice> choices;
  final dynamic value;
  final String? error;
  final void Function(dynamic value) onChanged;

  @override
  Component build(BuildContext context) {
    final hasError = error != null;
    return div(
        classes:
            'bg-white rounded-xl shadow-md border ${hasError ? 'border-red-300' : 'border-slate-200'} p-5',
        [
          // Question label
          div(classes: 'mb-4', [
            span(classes: 'text-sm font-medium text-slate-800', [
              Component.text(question.text),
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

  Component _buildQuestionInput() {
    return switch (question.type) {
      QuestionType.singleChoice => SingleChoiceQuestion(
          question: question,
          choices: choices,
          value: value as int?,
          onChanged: onChanged,
        ),
      QuestionType.multipleChoice => MultipleChoiceQuestion(
          question: question,
          choices: choices,
          value: (value as List<dynamic>?)?.cast<int>() ?? [],
          onChanged: onChanged,
        ),
      QuestionType.textSingle => TextSingleQuestion(
          question: question,
          value: value as String?,
          onChanged: onChanged,
        ),
      QuestionType.textMultiLine => TextMultiLineQuestion(
          question: question,
          value: value as String?,
          onChanged: onChanged,
        ),
    };
  }
}
