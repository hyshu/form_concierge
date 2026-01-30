import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'single_choice_question.dart';
import 'multiple_choice_question.dart';
import 'text_single_question.dart';
import 'text_multi_line_question.dart';

class QuestionWidget extends StatelessWidget {
  final Question question;
  final List<Choice> choices;
  final dynamic value;
  final String? error;
  final ValueChanged<dynamic> onChanged;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.choices,
    required this.value,
    this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                question.text,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (question.isRequired)
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
        _buildQuestionInput(),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(color: colorScheme.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionInput() {
    return switch (question.type) {
      QuestionType.singleChoice => SingleChoiceQuestion(
        choices: choices,
        selectedChoiceId: value as int?,
        onChanged: onChanged,
      ),
      QuestionType.multipleChoice => MultipleChoiceQuestion(
        choices: choices,
        selectedChoiceIds: (value as List<int>?) ?? [],
        onChanged: onChanged,
      ),
      QuestionType.textSingle => TextSingleQuestion(
        placeholder: question.placeholder,
        minLength: question.minLength,
        maxLength: question.maxLength,
        value: value as String?,
        onChanged: onChanged,
      ),
      QuestionType.textMultiLine => TextMultiLineQuestion(
        placeholder: question.placeholder,
        minLength: question.minLength,
        maxLength: question.maxLength,
        value: value as String?,
        onChanged: onChanged,
      ),
    };
  }
}
