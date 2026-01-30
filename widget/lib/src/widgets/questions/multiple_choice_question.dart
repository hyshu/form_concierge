import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

class MultipleChoiceQuestion extends StatelessWidget {
  final List<Choice> choices;
  final List<int> selectedChoiceIds;
  final ValueChanged<List<int>> onChanged;

  const MultipleChoiceQuestion({
    super.key,
    required this.choices,
    required this.selectedChoiceIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: choices.map((choice) {
        final isSelected = selectedChoiceIds.contains(choice.id);

        return CheckboxListTile(
          title: Text(choice.text),
          value: isSelected,
          onChanged: (checked) {
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
      }).toList(),
    );
  }
}
