import 'package:flutter/material.dart';

/// An input for an answer spanning multiple lines.
class TextMultiLineQuestion extends StatefulWidget {
  /// Hint text displayed when the text input is empty.
  final String? placeholder;

  /// The minimum accepted text length, or null when no minimum is set.
  final int? minLength;

  /// The maximum accepted text length, or null when no maximum is set.
  final int? maxLength;

  /// The current value displayed by the input.
  final String? value;

  /// Called with the updated value when the input changes.
  final ValueChanged<String> onChanged;

  /// Creates TextMultiLineQuestion with the supplied values.
  const TextMultiLineQuestion({
    super.key,
    this.placeholder,
    this.minLength,
    this.maxLength,
    this.value,
    required this.onChanged,
  });

  /// Creates the mutable state used by this widget.
  @override
  State<TextMultiLineQuestion> createState() => _TextMultiLineQuestionState();
}

class _TextMultiLineQuestionState extends State<TextMultiLineQuestion> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(context) => TextField(
    controller: _controller,
    decoration: InputDecoration(
      hintText: widget.placeholder,
      border: const OutlineInputBorder(),
      counterText: widget.maxLength != null ? null : '',
    ),
    maxLength: widget.maxLength,
    maxLines: 5,
    minLines: 3,
    onChanged: widget.onChanged,
  );
}
