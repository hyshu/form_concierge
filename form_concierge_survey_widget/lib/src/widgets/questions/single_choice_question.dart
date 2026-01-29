import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

class SingleChoiceQuestion extends StatelessWidget {
  final List<QuestionOption> options;
  final int? selectedOptionId;
  final ValueChanged<int?> onChanged;

  const SingleChoiceQuestion({
    super.key,
    required this.options,
    required this.selectedOptionId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        return RadioListTile<int>(
          title: Text(option.text),
          value: option.id!,
          groupValue: selectedOptionId,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
