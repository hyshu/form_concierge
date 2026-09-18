import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// An input for an answer spanning multiple lines.
class TextMultiLineQuestion extends StatelessComponent {
  /// Creates TextMultiLineQuestion with the supplied values.
  const TextMultiLineQuestion({
    required this.question,
    required this.value,
    required this.locale,
    required this.onChanged,
    this.disabled = false,
    this.invalid = false,
    this.describedById,
    super.key,
  });

  /// The question whose input is displayed.
  final Question question;

  /// The current value displayed by the input.
  final String? value;

  /// The locale used to display the form content.
  final String locale;

  /// Called with the updated value when the input changes.
  final void Function(AnswerValue value) onChanged;

  /// Whether user interaction with this input is disabled.
  final bool disabled;

  /// Whether the input should display its validation error state.
  final bool invalid;

  /// The DOM identifier of additional accessible input guidance, if any.
  final String? describedById;

  /// Builds the HTML components for the current input and state.
  @override
  Component build(context) => div([
    textarea(
      [if (value != null) Component.text(value!)],
      id: 'question_${question.id}',
      name: 'question_${question.id}',
      disabled: disabled,
      classes:
          'w-full px-4 py-3 border border-slate-200 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 focus:outline-none text-sm bg-white resize-y min-h-[120px] placeholder:text-slate-400',
      attributes: {
        if (question.isRequired) 'aria-required': 'true',
        if (invalid) 'aria-invalid': 'true',
        if (describedById != null) 'aria-describedby': describedById!,
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
