import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

class MultipleChoiceQuestion extends StatelessComponent {
  const MultipleChoiceQuestion({
    required this.question,
    required this.choices,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final Question question;
  final List<Choice> choices;
  final List<int> value;
  final void Function(dynamic value) onChanged;

  @override
  Component build(BuildContext context) {
    return div(classes: 'space-y-2', [
      for (final choice in choices)
        label([
          input(
            type: InputType.checkbox,
            name: 'question_${question.id}[]',
            value: choice.id.toString(),
            checked: value.contains(choice.id),
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
            Component.text(choice.text),
          ]),
        ],
            classes:
                'flex items-center px-4 py-3 rounded-lg border ${value.contains(choice.id) ? 'border-indigo-500 bg-indigo-50' : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50'} cursor-pointer'),
    ]);
  }
}
