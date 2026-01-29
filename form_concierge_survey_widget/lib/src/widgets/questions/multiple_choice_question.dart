import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

class MultipleChoiceQuestion extends StatelessWidget {
  final List<QuestionOption> options;
  final List<int> selectedOptionIds;
  final ValueChanged<List<int>> onChanged;

  const MultipleChoiceQuestion({
    super.key,
    required this.options,
    required this.selectedOptionIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = selectedOptionIds.contains(option.id);

        return CheckboxListTile(
          title: Text(option.text),
          value: isSelected,
          onChanged: (checked) {
            final newIds = List<int>.from(selectedOptionIds);
            if (checked == true) {
              newIds.add(option.id!);
            } else {
              newIds.remove(option.id);
            }
            onChanged(newIds);
          },
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}
