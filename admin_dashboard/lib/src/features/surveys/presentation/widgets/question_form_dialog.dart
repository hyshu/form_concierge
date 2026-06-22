import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

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
    return HuxDialog(
      title: context.tr(
        widget.existingQuestion != null ? 'Edit Question' : 'Add Question',
      ),
      size: HuxDialogSize.large,
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(text: context.tr('Localized question text')),
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
                _SectionTitle(text: context.tr('Question Type')),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: HuxDropdown<QuestionType>(
                    value: _type,
                    useItemWidgetAsValue: true,
                    items: QuestionType.values.map((type) {
                      return HuxDropdownItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon, size: 18),
                            const SizedBox(width: 8),
                            Text(context.tr(type.label)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _type = value),
                  ),
                ),
                const SizedBox(height: 16),
                if (_type.usesTextAnswer) ...[
                  _SectionTitle(text: context.tr('Localized placeholders')),
                  const SizedBox(height: 8),
                  LocalizedTextFieldGroup(
                    controllers: _placeholderControllers,
                    primaryLocale: widget.primaryLocale,
                    labelText: context.tr('Placeholder (optional)'),
                    hintText: context.tr('Placeholder text for the input'),
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
                ] else if (_type == QuestionType.multipleChoice)
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
                _SectionTitle(text: context.tr('Visibility rule match')),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: HuxDropdown<VisibilityConditionMode>(
                    value: _visibilityConditionMode,
                    useItemWidgetAsValue: true,
                    items: [
                      HuxDropdownItem(
                        value: VisibilityConditionMode.all,
                        child: Text(context.tr('All rules')),
                      ),
                      HuxDropdownItem(
                        value: VisibilityConditionMode.any,
                        child: Text(context.tr('Any rule')),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _visibilityConditionMode = value),
                  ),
                ),
                const SizedBox(height: 16),
                HuxCard(
                  backgroundColor: HuxTokens.surfaceSecondary(context),
                  child: Row(
                    children: [
                      HuxSwitch(
                        value: _isRequired,
                        onChanged: (value) =>
                            setState(() => _isRequired = value),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('Required')),
                            const SizedBox(height: 4),
                            Text(
                              context.tr(
                                'Respondents must answer this question',
                              ),
                              style: TextStyle(
                                color: HuxTokens.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        HuxButton(
          onPressed: () => Navigator.pop(context),
          variant: HuxButtonVariant.secondary,
          child: Text(context.tr('Cancel')),
        ),
        HuxButton(
          onPressed: _submit,
          icon: widget.existingQuestion != null
              ? LucideIcons.save
              : LucideIcons.plus,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleSmall);
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return HuxInput(
      controller: controller,
      label: label,
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
