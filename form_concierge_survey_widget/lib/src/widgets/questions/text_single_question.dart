import 'package:flutter/material.dart';

class TextSingleQuestion extends StatefulWidget {
  final String? placeholder;
  final int? minLength;
  final int? maxLength;
  final String? value;
  final ValueChanged<String> onChanged;

  const TextSingleQuestion({
    super.key,
    this.placeholder,
    this.minLength,
    this.maxLength,
    this.value,
    required this.onChanged,
  });

  @override
  State<TextSingleQuestion> createState() => _TextSingleQuestionState();
}

class _TextSingleQuestionState extends State<TextSingleQuestion> {
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
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        border: const OutlineInputBorder(),
        counterText: widget.maxLength != null ? null : '',
      ),
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
    );
  }
}
