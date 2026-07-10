import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'questions/image_upload_question.dart';

/// Adaptive follow-up interview after the main survey submit.
class FollowUpContent extends StatelessWidget {
  final Client client;
  final Survey survey;
  final FollowUp followUp;
  final Map<String, dynamic> answers;
  final Map<String, String> validationErrors;
  final String? errorMessage;
  final String locale;
  final bool isSubmitting;
  final void Function(String itemId, dynamic value) onAnswerChanged;
  final VoidCallback onSubmit;
  final Future<void> Function()? ensureAuthenticated;
  final ProcessSurveyImage? processImage;

  const FollowUpContent({
    super.key,
    required this.client,
    required this.survey,
    required this.followUp,
    required this.answers,
    required this.validationErrors,
    this.errorMessage,
    required this.locale,
    required this.isSubmitting,
    required this.onAnswerChanged,
    required this.onSubmit,
    this.ensureAuthenticated,
    this.processImage,
  });

  @override
  Widget build(context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          FormContentMessages.text(locale, 'followUpTitle'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          FormContentMessages.text(locale, 'followUpSubtitle'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        for (final item in followUp.items)
          Padding(
            key: ValueKey(item.id),
            padding: const EdgeInsets.only(bottom: 24),
            child: _FollowUpItemField(
              client: client,
              item: item,
              value: answers[item.id],
              error: validationErrors[item.id],
              locale: locale,
              enabled: !isSubmitting,
              ensureAuthenticated: ensureAuthenticated,
              processImage: processImage,
              onChanged: (value) => onAnswerChanged(item.id, value),
            ),
          ),
        if (errorMessage != null) ...[
          Text(errorMessage!, style: TextStyle(color: colorScheme.error)),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: isSubmitting ? null : onSubmit,
          child: Text(
            isSubmitting
                ? FormContentMessages.text(locale, 'followUpSubmitting')
                : FormContentMessages.text(locale, 'followUpContinue'),
          ),
        ),
      ],
    );
  }
}

class _FollowUpItemField extends StatefulWidget {
  final Client client;
  final FollowUpItem item;
  final dynamic value;
  final String? error;
  final String locale;
  final bool enabled;
  final Future<void> Function()? ensureAuthenticated;
  final ProcessSurveyImage? processImage;
  final ValueChanged<dynamic> onChanged;

  const _FollowUpItemField({
    required this.client,
    required this.item,
    required this.value,
    this.error,
    required this.locale,
    this.enabled = true,
    this.ensureAuthenticated,
    this.processImage,
    required this.onChanged,
  });

  @override
  State<_FollowUpItemField> createState() => _FollowUpItemFieldState();
}

class _FollowUpItemFieldState extends State<_FollowUpItemField> {
  late final TextEditingController _textController;

  bool get _isText =>
      widget.item.type == QuestionType.textSingle ||
      widget.item.type == QuestionType.textMultiLine;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: _isText ? (widget.value as String? ?? '') : '',
    );
  }

  @override
  void didUpdateWidget(covariant _FollowUpItemField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isText) {
      final next = widget.value as String? ?? '';
      if (_textController.text != next) {
        _textController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.text,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (item.required)
              Text(
                ' *',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInput(),
        if (widget.error != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.error!,
            style: TextStyle(color: colorScheme.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildInput() {
    final item = widget.item;
    return switch (item.type) {
      QuestionType.singleChoice => RadioGroup<String>(
        groupValue: widget.value as String?,
        onChanged: widget.onChanged,
        child: Column(
          children: item.choices.map((choice) {
            return RadioListTile<String>(
              title: Text(choice.label),
              value: choice.id,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ),
      QuestionType.multipleChoice => Column(
        children: item.choices.map((choice) {
          final selected = (widget.value as List<String>?) ?? const <String>[];
          final isSelected = selected.contains(choice.id);
          return CheckboxListTile(
            title: Text(choice.label),
            value: isSelected,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onChanged: (checked) {
              final next = List<String>.from(selected);
              if (checked == true) {
                if (!next.contains(choice.id)) next.add(choice.id);
              } else {
                next.remove(choice.id);
              }
              widget.onChanged(next);
            },
          );
        }).toList(),
      ),
      QuestionType.textSingle => TextField(
        controller: _textController,
        decoration: InputDecoration(
          hintText: item.placeholder,
          border: const OutlineInputBorder(),
        ),
        textInputAction: TextInputAction.next,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
      ),
      QuestionType.textMultiLine => TextField(
        controller: _textController,
        decoration: InputDecoration(
          hintText: item.placeholder,
          border: const OutlineInputBorder(),
        ),
        minLines: 3,
        maxLines: 6,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
      ),
      QuestionType.imageUpload => ImageUploadQuestion(
        client: widget.client,
        maxFiles: item.maxFiles ?? 1,
        fileKeys: (widget.value as List<String>?) ?? const [],
        locale: widget.locale,
        enabled: widget.enabled,
        ensureAuthenticated: widget.ensureAuthenticated,
        processImage: widget.processImage,
        onChanged: widget.onChanged,
      ),
    };
  }
}
