import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

class SingleChoiceQuestion extends StatelessComponent {
  const SingleChoiceQuestion({
    required this.question,
    required this.choices,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final Question question;
  final List<Choice> choices;
  final int? value;
  final void Function(dynamic value) onChanged;

  @override
  Component build(BuildContext context) {
    return div(classes: 'space-y-2', [
      for (final choice in choices)
        label([
          input(
            type: InputType.radio,
            name: 'question_${question.id}',
            value: choice.id.toString(),
            checked: value == choice.id,
            classes: 'w-4 h-4 text-indigo-600 accent-indigo-600 flex-shrink-0',
            onChange: (bool? checked) {
              if (checked == true) {
                onChanged(choice.id);
              }
            },
          ),
          span(classes: 'ml-3 text-sm text-slate-700', [
            Component.text(choice.text),
          ]),
        ],
            classes:
                'flex items-center px-4 py-3 rounded-lg border ${value == choice.id ? 'border-indigo-500 bg-indigo-50' : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50'} cursor-pointer'),
    ]);
  }
}
