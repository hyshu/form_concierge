import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// An input that lets the respondent select several choices.
class MultipleChoiceQuestion extends StatelessComponent {
  /// Creates MultipleChoiceQuestion with the supplied values.
  const MultipleChoiceQuestion({
    required this.question,
    required this.choices,
    required this.value,
    required this.locale,
    required this.onChanged,
    this.disabled = false,
    super.key,
  });

  /// The question whose input is displayed.
  final Question question;

  /// The choices available for this question.
  final List<Choice> choices;

  /// The current value displayed by the input.
  final List<int> value;

  /// The locale used to display the form content.
  final String locale;

  /// Called with the updated value when the input changes.
  final void Function(AnswerValue value) onChanged;

  /// Whether user interaction with this input is disabled.
  final bool disabled;

  /// Builds the HTML components for the current input and state.
  @override
  Component build(context) => div(classes: 'space-y-2', [
    if (question.minSelected != null || question.maxSelected != null)
      div(classes: 'text-xs text-slate-500', [
        Component.text(
          FormContentMessages.selectionHint(
            locale,
            minSelected: question.minSelected,
            maxSelected: question.maxSelected,
          ),
        ),
      ]),
    for (final choice in choices)
      label(
        [
          input(
            type: InputType.checkbox,
            name: 'question_${question.id}[]',
            value: choice.id.toString(),
            checked: value.contains(choice.id),
            disabled:
                disabled ||
                (!value.contains(choice.id) &&
                    question.maxSelected != null &&
                    value.length >= question.maxSelected!),
            classes:
                'w-4 h-4 text-indigo-600 accent-indigo-600 rounded flex-shrink-0',
            onChange: (bool? checked) {
              final newValue = List<int>.from(value);
              if (checked == true) {
                newValue.add(choice.id!);
              } else {
                newValue.remove(choice.id);
              }
              onChanged(newValue);
            },
          ),
          span(classes: 'ml-3 text-sm text-slate-700', [
            Component.text(choice.textFor(locale)),
          ]),
        ],
        classes:
            'flex items-center px-4 py-3 rounded-lg border ${value.contains(choice.id) ? 'border-indigo-500 bg-indigo-50' : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50'} cursor-pointer',
      ),
  ]);
}
