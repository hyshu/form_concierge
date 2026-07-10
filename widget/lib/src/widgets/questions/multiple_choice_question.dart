import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

class MultipleChoiceQuestion extends StatelessWidget {
  final Question question;
  final List<Choice> choices;
  final List<int> selectedChoiceIds;
  final String locale;
  final ValueChanged<List<int>> onChanged;

  const MultipleChoiceQuestion({
    super.key,
    required this.question,
    required this.choices,
    required this.selectedChoiceIds,
    required this.locale,
    required this.onChanged,
  });

  @override
  Widget build(context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (question.minSelected != null || question.maxSelected != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            FormContentMessages.selectionHint(
              locale,
              minSelected: question.minSelected,
              maxSelected: question.maxSelected,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ...choices.map((choice) {
        final isSelected = selectedChoiceIds.contains(choice.id);

        return CheckboxListTile(
          title: Text(choice.textFor(locale)),
          value: isSelected,
          onChanged:
              !isSelected &&
                  question.maxSelected != null &&
                  selectedChoiceIds.length >= question.maxSelected!
              ? null
              : (checked) {
                  final newIds = List<int>.from(selectedChoiceIds);
                  if (checked == true) {
                    newIds.add(choice.id!);
                  } else {
                    newIds.remove(choice.id);
                  }
                  onChanged(newIds);
                },
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }),
    ],
  );
}
