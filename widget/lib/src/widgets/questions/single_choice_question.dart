import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

class SingleChoiceQuestion extends StatelessWidget {
  final List<Choice> choices;
  final int? selectedChoiceId;
  final ValueChanged<int?> onChanged;

  const SingleChoiceQuestion({
    super.key,
    required this.choices,
    required this.selectedChoiceId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: choices.map((choice) {
        return RadioListTile<int>(
          title: Text(choice.text),
          value: choice.id!,
          groupValue: selectedChoiceId,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
