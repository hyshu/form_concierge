import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

class MultipleChoiceQuestion extends StatelessWidget {
  final Question question;
  final List<Choice> choices;
  final List<int> selectedChoiceIds;
  final ValueChanged<List<int>> onChanged;

  const MultipleChoiceQuestion({
    super.key,
    required this.question,
    required this.choices,
    required this.selectedChoiceIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.minSelected != null || question.maxSelected != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _selectionHint(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ...choices.map((choice) {
          final isSelected = selectedChoiceIds.contains(choice.id);

          return CheckboxListTile(
            title: Text(choice.text),
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

  String _selectionHint() {
    final parts = [
      if (question.minSelected != null) 'min ${question.minSelected}',
      if (question.maxSelected != null) 'max ${question.maxSelected}',
    ];
    return 'Select ${parts.join(', ')}';
  }
}
