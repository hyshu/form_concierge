import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

/// Dialog for creating/editing a question.
class QuestionFormDialog extends StatefulWidget {
  final Question? existingQuestion;
  final void Function({
    required String text,
    required QuestionType type,
    required bool isRequired,
    String? placeholder,
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
  late QuestionType _type;
  late bool _isRequired;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.existingQuestion?.text ?? '',
    );
    _placeholderController = TextEditingController(
      text: widget.existingQuestion?.placeholder ?? '',
    );
    _type = widget.existingQuestion?.type ?? QuestionType.singleChoice;
    _isRequired = widget.existingQuestion?.isRequired ?? true;
  }

  @override
  void dispose() {
    _textController.dispose();
    _placeholderController.dispose();
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
                      label: _labelForType(type),
                      leadingIcon: Icon(_iconForType(type), size: 20),
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
                if (_type == QuestionType.textSingle ||
                    _type == QuestionType.textMultiLine)
                  TextFormField(
                    controller: _placeholderController,
                    decoration: const InputDecoration(
                      labelText: 'Placeholder (optional)',
                      hintText: 'Placeholder text for the input',
                    ),
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
      );
      Navigator.pop(context);
    }
  }

  IconData _iconForType(QuestionType type) {
    return switch (type) {
      QuestionType.singleChoice => Icons.radio_button_checked,
      QuestionType.multipleChoice => Icons.check_box,
      QuestionType.textSingle => Icons.short_text,
      QuestionType.textMultiLine => Icons.notes,
    };
  }

  String _labelForType(QuestionType type) {
    return switch (type) {
      QuestionType.singleChoice => 'Single Choice',
      QuestionType.multipleChoice => 'Multiple Choice',
      QuestionType.textSingle => 'Short Text',
      QuestionType.textMultiLine => 'Long Text',
    };
  }
}
