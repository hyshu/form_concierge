import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

/// An input that lets the respondent select one choice.
class SingleChoiceQuestion extends StatelessWidget {
  /// The choices available for this question.
  final List<Choice> choices;

  /// The selected choice identifier, or null when nothing is selected.
  final int? selectedChoiceId;

  /// The locale used to display the form content.
  final String locale;

  /// Called with the updated value when the input changes.
  final ValueChanged<int?> onChanged;

  /// Creates SingleChoiceQuestion with the supplied values.
  const SingleChoiceQuestion({
    super.key,
    required this.choices,
    required this.selectedChoiceId,
    required this.locale,
    required this.onChanged,
  });

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => RadioGroup<int>(
    groupValue: selectedChoiceId,
    onChanged: onChanged,
    child: Column(
      children: choices
          .map(
            (choice) => RadioListTile<int>(
              title: Text(choice.textFor(locale)),
              value: choice.id!,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(),
    ),
  );
}
