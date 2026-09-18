import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

/// An input that lets the respondent select several choices.
class MultipleChoiceQuestion extends StatelessWidget {
  /// The question whose input is displayed.
  final Question question;

  /// The choices available for this question.
  final List<Choice> choices;

  /// The identifiers of the selected answer choices.
  final List<int> selectedChoiceIds;

  /// The locale used to display the form content.
  final String locale;

  /// Called with the updated value when the input changes.
  final ValueChanged<List<int>> onChanged;

  /// Creates MultipleChoiceQuestion with the supplied values.
  const MultipleChoiceQuestion({
    super.key,
    required this.question,
    required this.choices,
    required this.selectedChoiceIds,
    required this.locale,
    required this.onChanged,
  });

  /// Builds the widget tree for the current input and state.
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
