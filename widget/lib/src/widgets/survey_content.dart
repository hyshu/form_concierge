import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'questions/image_upload_question.dart';
import 'questions/question_widget.dart';

/// Displays survey questions, validation feedback, and submission controls.
class SurveyContent extends StatefulWidget {
  /// The API client used to load data and submit changes.
  final Client client;

  /// The project that contains the survey.
  final Project project;

  /// The survey displayed by this component or state.
  final Survey survey;

  /// The survey questions in display order.
  final List<Question> questions;

  /// Available choices indexed by question identifier.
  final Map<int, List<Choice>> choicesByQuestion;

  /// The current answers indexed by question identifier.
  final AnswerValues answers;

  /// Validation messages indexed by question identifier.
  final ValidationErrors validationErrors;

  /// The error message to display, or null when there is no error.
  final String? errorMessage;

  /// The locale used to display the form content.
  final String locale;

  /// Whether a submission is in progress and inputs should be disabled.
  final bool isSubmitting;

  /// Whether to display a selector for the form language.
  final bool showLocalePicker;

  /// Called when the respondent changes an answer.
  final void Function(int questionId, AnswerValue value) onAnswerChanged;

  /// Called when the respondent selects a different form language.
  final ValueChanged<String> onLocaleChanged;

  /// Called when the respondent requests submission.
  final VoidCallback onSubmit;

  /// Ensures an anonymous session exists before uploading media, when provided.
  final Future<void> Function()? ensureAuthenticated;

  /// An optional transformation applied to each image before upload.
  final ProcessSurveyImage? processImage;

  /// Optional content displayed below the survey controls.
  final Widget? footer;

  /// Creates SurveyContent with the supplied values.
  const SurveyContent({
    super.key,
    required this.client,
    required this.project,
    required this.survey,
    required this.questions,
    required this.choicesByQuestion,
    required this.answers,
    required this.validationErrors,
    this.errorMessage,
    required this.locale,
    required this.isSubmitting,
    this.showLocalePicker = false,
    required this.onAnswerChanged,
    required this.onLocaleChanged,
    required this.onSubmit,
    this.ensureAuthenticated,
    this.processImage,
    this.footer,
  });

  /// Creates the mutable state used by this widget.
  @override
  State<SurveyContent> createState() => _SurveyContentState();
}

class _SurveyContentState extends State<SurveyContent> {
  final _scrollController = ScrollController();
  final _questionKeys = <int, GlobalKey>{};
  final _submitSectionKey = GlobalKey();

  @override
  void didUpdateWidget(covariant SurveyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final validationChanged =
        !identical(widget.validationErrors, oldWidget.validationErrors) &&
        widget.validationErrors.isNotEmpty;
    final submitErrorAppeared =
        widget.errorMessage != null &&
        widget.errorMessage != oldWidget.errorMessage;
    if (validationChanged || submitErrorAppeared) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (validationChanged) {
          _scrollToFirstValidationError();
        } else if (submitErrorAppeared) {
          _scrollToKey(_submitSectionKey);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyForQuestion(int questionId) =>
      _questionKeys.putIfAbsent(questionId, GlobalKey.new);

  void _scrollToFirstValidationError() {
    for (final question in widget.questions) {
      final id = question.id;
      if (id == null) continue;
      if (!widget.validationErrors.containsKey(id)) continue;
      _scrollToKey(_keyForQuestion(id));
      return;
    }
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.survey.titleFor(widget.locale),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (widget.survey.descriptionFor(widget.locale).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.survey.descriptionFor(widget.locale),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (widget.showLocalePicker &&
              widget.project.supportedLocales.length > 1) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: widget.locale,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final option in widget.project.supportedLocales)
                  DropdownMenuItem(
                    value: option,
                    child: Text(formContentLocaleLabels[option] ?? option),
                  ),
              ],
              onChanged: widget.isSubmitting
                  ? null
                  : (value) {
                      if (value != null) widget.onLocaleChanged(value);
                    },
            ),
          ],
          const SizedBox(height: 24),
          ...widget.questions.map((question) {
            final choices = widget.choicesByQuestion[question.id] ?? [];
            final error = widget.validationErrors[question.id];
            final questionId = question.id;

            return Padding(
              key: questionId == null ? null : _keyForQuestion(questionId),
              padding: const EdgeInsets.only(bottom: 24),
              child: QuestionWidget(
                key: ValueKey('question-${question.id}'),
                question: question,
                choices: choices,
                value: widget.answers[question.id],
                error: error,
                locale: widget.locale,
                client: widget.client,
                ensureAuthenticated: widget.ensureAuthenticated,
                processImage: widget.processImage,
                onChanged: (value) =>
                    widget.onAnswerChanged(question.id!, value),
              ),
            );
          }),
          const SizedBox(height: 8),
          // Errors sit next to the submit action (ui-baseline), not at page top.
          KeyedSubtree(
            key: _submitSectionKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.errorMessage!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: widget.isSubmitting ? null : widget.onSubmit,
                  child: widget.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(FormContentMessages.text(widget.locale, 'submit')),
                ),
              ],
            ),
          ),
          if (widget.footer != null) ...[
            const SizedBox(height: 12),
            widget.footer!,
          ],
        ],
      ),
    );
  }
}
