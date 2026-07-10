import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

class TextMultiLineQuestion extends StatelessComponent {
  const TextMultiLineQuestion({
    required this.question,
    required this.value,
    required this.locale,
    required this.onChanged,
    super.key,
  });

  final Question question;
  final String? value;
  final String locale;
  final void Function(AnswerValue value) onChanged;

  @override
  Component build(context) => div([
        textarea(
          [if (value != null) Component.text(value!)],
          id: 'question_${question.id}',
          name: 'question_${question.id}',
          classes:
              'w-full px-4 py-3 border border-slate-200 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 focus:outline-none text-sm bg-white resize-y min-h-[120px] placeholder:text-slate-400',
          attributes: {
            if (question.placeholderFor(locale) != null)
              'placeholder': question.placeholderFor(locale)!,
            if (question.minLength != null)
              'minlength': question.minLength.toString(),
            if (question.maxLength != null)
              'maxlength': question.maxLength.toString(),
            'rows': '4',
          },
          onInput: (String newValue) => onChanged(newValue),
        ),
        if (question.maxLength != null)
          div(classes: 'mt-1.5 text-right text-xs text-slate-400', [
            Component.text('${(value?.length ?? 0)}/${question.maxLength}'),
          ]),
      ]);
}
