import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'single_choice_question.dart';
import 'multiple_choice_question.dart';
import 'text_single_question.dart';
import 'text_multi_line_question.dart';
import 'image_upload_question.dart';

/// Selects the input widget for a question and displays validation feedback.
class QuestionWidget extends StatelessWidget {
  /// The question whose input is displayed.
  final Question question;

  /// The choices available for this question.
  final List<Choice> choices;

  /// The current value displayed by the input.
  final AnswerValue value;

  /// The error message, when the operation could not complete.
  final String? error;

  /// The locale used to display the form content.
  final String locale;

  /// Called with the updated value when the input changes.
  final ValueChanged<AnswerValue> onChanged;

  /// The API client used to load data and submit changes.
  final Client? client;

  /// Ensures an anonymous session exists before uploading media, when provided.
  final Future<void> Function()? ensureAuthenticated;

  /// An optional transformation applied to each image before upload.
  final ProcessSurveyImage? processImage;

  /// Creates QuestionWidget with the supplied values.
  const QuestionWidget({
    super.key,
    required this.question,
    required this.choices,
    required this.value,
    this.error,
    required this.locale,
    required this.onChanged,
    this.client,
    this.ensureAuthenticated,
    this.processImage,
  });

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                question.textFor(locale),
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

  Widget _buildQuestionInput() => switch (question.type) {
    QuestionType.singleChoice => SingleChoiceQuestion(
      choices: choices,
      selectedChoiceId: value as int?,
      locale: locale,
      onChanged: onChanged,
    ),
    QuestionType.multipleChoice => MultipleChoiceQuestion(
      question: question,
      choices: choices,
      selectedChoiceIds: (value as List<int>?) ?? [],
      locale: locale,
      onChanged: onChanged,
    ),
    QuestionType.textSingle => TextSingleQuestion(
      placeholder: question.placeholderFor(locale),
      minLength: question.minLength,
      maxLength: question.maxLength,
      value: value as String?,
      onChanged: onChanged,
    ),
    QuestionType.textMultiLine => TextMultiLineQuestion(
      placeholder: question.placeholderFor(locale),
      minLength: question.minLength,
      maxLength: question.maxLength,
      value: value as String?,
      onChanged: onChanged,
    ),
    QuestionType.imageUpload =>
      client == null
          ? Text(
              'Image upload requires a Client',
              style: TextStyle(color: ThemeData.light().colorScheme.error),
            )
          : ImageUploadQuestion(
              client: client!,
              maxFiles: question.maxSelected ?? 3,
              fileKeys: (value as List<String>?) ?? const [],
              locale: locale,
              ensureAuthenticated: ensureAuthenticated,
              processImage: processImage,
              onChanged: onChanged,
            ),
  };
}
