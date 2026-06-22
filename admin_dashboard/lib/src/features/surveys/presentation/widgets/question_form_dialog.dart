import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/extensions/question_type_presentation.dart';

/// Dialog for creating/editing a question.
class QuestionFormDialog extends StatefulWidget {
  final Question? existingQuestion;
  final void Function({
    required String text,
    required QuestionType type,
    required bool isRequired,
    String? placeholder,
    int? minLength,
    int? maxLength,
    int? minSelected,
    int? maxSelected,
    required VisibilityConditionMode visibilityConditionMode,
  })
  onSave;

  const QuestionFormDialog({
    super.key,
    this.existingQuestion,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    Question? existingQuestion,
    required void Function({
      required String text,
      required QuestionType type,
      required bool isRequired,
      String? placeholder,
      int? minLength,
      int? maxLength,
      int? minSelected,
      int? maxSelected,
      required VisibilityConditionMode visibilityConditionMode,
    })
    onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => QuestionFormDialog(
        existingQuestion: existingQuestion,
        onSave: onSave,
      ),
    );
  }

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;
  late final TextEditingController _placeholderController;
  late final TextEditingController _minLengthController;
  late final TextEditingController _maxLengthController;
  late final TextEditingController _minSelectedController;
  late final TextEditingController _maxSelectedController;
  late QuestionType _type;
  late bool _isRequired;
  late VisibilityConditionMode _visibilityConditionMode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.existingQuestion?.text ?? '',
    );
    _placeholderController = TextEditingController(
      text: widget.existingQuestion?.placeholder ?? '',
    );
    _minLengthController = TextEditingController(
      text: widget.existingQuestion?.minLength?.toString() ?? '',
    );
    _maxLengthController = TextEditingController(
      text: widget.existingQuestion?.maxLength?.toString() ?? '',
    );
    _minSelectedController = TextEditingController(
      text: widget.existingQuestion?.minSelected?.toString() ?? '',
    );
    _maxSelectedController = TextEditingController(
      text: widget.existingQuestion?.maxSelected?.toString() ?? '',
    );
    _type = widget.existingQuestion?.type ?? QuestionType.singleChoice;
    _isRequired = widget.existingQuestion?.isRequired ?? true;
    _visibilityConditionMode =
        widget.existingQuestion?.visibilityConditionMode ??
        VisibilityConditionMode.all;
  }

  @override
  void dispose() {
    _textController.dispose();
    _placeholderController.dispose();
    _minLengthController.dispose();
    _maxLengthController.dispose();
    _minSelectedController.dispose();
    _maxSelectedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingQuestion != null ? 'Edit Question' : 'Add Question',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Question text',
                    hintText: 'Enter your question',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Question text is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Question Type',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownMenu<QuestionType>(
                  initialSelection: _type,
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: QuestionType.values.map((type) {
                    return DropdownMenuEntry(
                      value: type,
                      label: type.label,
                      leadingIcon: Icon(type.icon, size: 20),
                    );
                  }).toList(),
                  onSelected: (value) {
                    if (value != null) {
                      setState(() {
                        _type = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (_type.usesTextAnswer)
                  Column(
                    children: [
                      TextFormField(
                        controller: _placeholderController,
                        decoration: const InputDecoration(
                          labelText: 'Placeholder (optional)',
                          hintText: 'Placeholder text for the input',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              controller: _minLengthController,
                              label: 'Min length',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              controller: _maxLengthController,
                              label: 'Max length',
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else if (_type == QuestionType.multipleChoice)
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(
                          controller: _minSelectedController,
                          label: 'Min selections',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumberField(
                          controller: _maxSelectedController,
                          label: 'Max selections',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                DropdownMenu<VisibilityConditionMode>(
                  initialSelection: _visibilityConditionMode,
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('Visibility rule match'),
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(
                      value: VisibilityConditionMode.all,
                      label: 'All rules',
                    ),
                    DropdownMenuEntry(
                      value: VisibilityConditionMode.any,
                      label: 'Any rule',
                    ),
                  ],
                  onSelected: (value) {
                    if (value == null) return;
                    setState(() {
                      _visibilityConditionMode = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Required'),
                  subtitle: const Text('Respondents must answer this question'),
                  value: _isRequired,
                  onChanged: (value) {
                    setState(() {
                      _isRequired = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.existingQuestion != null ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(
        text: _textController.text.trim(),
        type: _type,
        isRequired: _isRequired,
        placeholder: _placeholderController.text.trim().isEmpty
            ? null
            : _placeholderController.text.trim(),
        minLength: _parseInt(_minLengthController.text),
        maxLength: _parseInt(_maxLengthController.text),
        minSelected: _parseInt(_minSelectedController.text),
        maxSelected: _parseInt(_maxSelectedController.text),
        visibilityConditionMode: _visibilityConditionMode,
      );
      Navigator.pop(context);
    }
  }

  int? _parseInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return null;
        final parsed = int.tryParse(trimmed);
        if (parsed == null || parsed < 0) {
          return 'Use 0 or more';
        }
        return null;
      },
    );
  }
}
