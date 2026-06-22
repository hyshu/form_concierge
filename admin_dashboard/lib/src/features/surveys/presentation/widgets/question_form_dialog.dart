import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/extensions/question_type_presentation.dart';
import '../../../../core/localization/app_localizations.dart';
import 'localized_text_field_group.dart';

/// Dialog for creating/editing a question.
class QuestionFormDialog extends StatefulWidget {
  final Question? existingQuestion;
  final String primaryLocale;
  final void Function({
    required LocalizedText textTranslations,
    required QuestionType type,
    required bool isRequired,
    required LocalizedText placeholderTranslations,
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
    this.primaryLocale = defaultFormContentLocale,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    Question? existingQuestion,
    String primaryLocale = defaultFormContentLocale,
    required void Function({
      required LocalizedText textTranslations,
      required QuestionType type,
      required bool isRequired,
      required LocalizedText placeholderTranslations,
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
        primaryLocale: primaryLocale,
        onSave: onSave,
      ),
    );
  }

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _textControllers;
  late final Map<String, TextEditingController> _placeholderControllers;
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
    _textControllers = {
      for (final locale in formContentLocaleCodes)
        locale: TextEditingController(
          text:
              widget.existingQuestion?.textTranslations.valueFor(locale) ?? '',
        ),
    };
    _placeholderControllers = {
      for (final locale in formContentLocaleCodes)
        locale: TextEditingController(
          text:
              widget.existingQuestion?.placeholderTranslations.valueFor(
                locale,
              ) ??
              '',
        ),
    };
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
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final controller in _placeholderControllers.values) {
      controller.dispose();
    }
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
        context.tr(
          widget.existingQuestion != null ? 'Edit Question' : 'Add Question',
        ),
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
                Text(
                  context.tr('Localized question text'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                LocalizedTextFieldGroup(
                  controllers: _textControllers,
                  primaryLocale: widget.primaryLocale,
                  labelText: context.tr('Question text'),
                  hintText: context.tr('Enter your question'),
                  maxLines: 2,
                  requiredMessage: context.tr('Question text is required'),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('Question Type'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownMenu<QuestionType>(
                  initialSelection: _type,
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: QuestionType.values.map((type) {
                    return DropdownMenuEntry(
                      value: type,
                      label: context.tr(type.label),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.tr('Localized placeholders'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LocalizedTextFieldGroup(
                        controllers: _placeholderControllers,
                        primaryLocale: widget.primaryLocale,
                        labelText: context.tr('Placeholder (optional)'),
                        hintText: context.tr(
                          'Placeholder text for the input',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _NumberField(
                              controller: _minLengthController,
                              label: context.tr('Min length'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumberField(
                              controller: _maxLengthController,
                              label: context.tr('Max length'),
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
                          label: context.tr('Min selections'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumberField(
                          controller: _maxSelectedController,
                          label: context.tr('Max selections'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                DropdownMenu<VisibilityConditionMode>(
                  initialSelection: _visibilityConditionMode,
                  expandedInsets: EdgeInsets.zero,
                  label: Text(context.tr('Visibility rule match')),
                  dropdownMenuEntries: [
                    DropdownMenuEntry(
                      value: VisibilityConditionMode.all,
                      label: context.tr('All rules'),
                    ),
                    DropdownMenuEntry(
                      value: VisibilityConditionMode.any,
                      label: context.tr('Any rule'),
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
                  title: Text(context.tr('Required')),
                  subtitle: Text(
                    context.tr('Respondents must answer this question'),
                  ),
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
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            context.tr(widget.existingQuestion != null ? 'Save' : 'Add'),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(
        textTranslations: localizedTextFromControllers(
          _textControllers,
          primaryLocale: widget.primaryLocale,
        ),
        type: _type,
        isRequired: _isRequired,
        placeholderTranslations: _type.usesTextAnswer
            ? localizedTextFromControllers(
                _placeholderControllers,
                primaryLocale: widget.primaryLocale,
                fallbackEmptyToPrimary: false,
              )
            : LocalizedText.filled(''),
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
          return context.tr('Use 0 or more');
        }
        return null;
      },
    );
  }
}
