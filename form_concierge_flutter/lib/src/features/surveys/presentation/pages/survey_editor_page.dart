import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/public_config_capsule.dart';
import '../../../dashboard/presentation/capsules/survey_list_capsule.dart';
import '../capsules/question_list_capsule.dart';
import '../capsules/survey_form_capsule.dart';
import '../widgets/ai_question_preview_dialog.dart';
import '../widgets/draft_question_editor.dart';
import '../widgets/question_form_dialog.dart';
import '../widgets/question_list.dart';
import '../widgets/survey_form.dart';

/// Page for creating or editing a survey and its questions.
class SurveyEditorPage extends RearchConsumer {
  final int? surveyId;

  const SurveyEditorPage({super.key, this.surveyId});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final formManager = use(surveyFormManagerCapsule);
    final questionManager = use(questionListManagerCapsule);
    final surveyListManager = use(surveyListCapsule);
    final controllers = use(surveyFormControllersCapsule);
    final publicConfig = use(publicConfigCapsule);

    final isNewSurvey = surveyId == null;
    final formState = formManager.getState(surveyId);
    final questionState =
        isNewSurvey ? null : questionManager.getState(surveyId!);
    final geminiEnabled = publicConfig.state.geminiEnabled;

    // Load survey and questions on first build (only for existing surveys)
    if (use.isFirstBuild() && !isNewSurvey) {
      formManager.loadSurvey(surveyId!);
      questionManager.loadQuestions(surveyId!);
    }

    // Populate form when survey is loaded (track previous to detect change)
    final prevSurvey = use.previous(formState.survey);
    if (formState.survey != null && prevSurvey == null) {
      // Schedule for after build to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controllers.populateFrom(formState.survey!);
      });
    }

    if (!isNewSurvey && formState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final survey = formState.survey;
    if (!isNewSurvey && survey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Survey Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text('Survey not found'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/admin'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final canEdit = isNewSurvey || survey!.status != SurveyStatus.archived;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewSurvey ? 'New Survey' : survey!.title),
        actions: [
          if (!isNewSurvey && survey!.status == SurveyStatus.draft)
            TextButton.icon(
              onPressed: _canPublish(questionState!)
                  ? () => _publishSurvey(context, surveyListManager)
                  : null,
              icon: const Icon(Icons.publish),
              label: const Text('Publish'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isNewSurvey && !canEdit) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color:
                                Theme.of(context).colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This survey is archived. You cannot edit the questions.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildSurveyForm(
                    context,
                    formManager,
                    surveyListManager,
                    controllers,
                    formState,
                    survey,
                    isNewSurvey,
                  ),
                  const SizedBox(height: 48),
                  if (isNewSurvey)
                    _buildDraftQuestionsSection(
                      context,
                      formManager,
                      formState,
                      geminiEnabled,
                    )
                  else
                    QuestionList(
                  surveyId: surveyId!,
                  questions: questionState!.questions,
                  choicesByQuestion: questionState.choicesByQuestion,
                  isLoading: questionState.isLoading,
                  enabled: canEdit,
                  onAddQuestion: ({
                    required String text,
                    required QuestionType type,
                    required bool isRequired,
                    String? placeholder,
                  }) {
                    questionManager.createQuestion(
                      surveyId: surveyId!,
                      text: text,
                      type: type,
                      isRequired: isRequired,
                      placeholder: placeholder,
                    );
                  },
                  onEditQuestion: (
                    question, {
                    required String text,
                    required QuestionType type,
                    required bool isRequired,
                    String? placeholder,
                  }) {
                    final updated = question.copyWith(
                      text: text,
                      type: type,
                      isRequired: isRequired,
                      placeholder: placeholder,
                    );
                    questionManager.updateQuestion(updated);
                  },
                  onDeleteQuestion: (question) {
                    questionManager.deleteQuestion(surveyId!, question.id!);
                  },
                  onAddChoice: (questionId, text) {
                    questionManager.createChoice(
                      questionId: questionId,
                      surveyId: surveyId!,
                      text: text,
                    );
                  },
                  onUpdateChoice: (choice, newText) {
                    final updated = choice.copyWith(text: newText);
                    questionManager.updateChoice(updated, surveyId!);
                  },
                  onDeleteChoice: (choice) {
                    questionManager.deleteChoice(choice.id!, surveyId!);
                  },
                ),
              if (questionState?.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  questionState!.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyForm(
    BuildContext context,
    SurveyFormManager formManager,
    SurveyListManager surveyListManager,
    SurveyFormControllers controllers,
    SurveyFormState formState,
    Survey? survey,
    bool isNewSurvey,
  ) {
    return SurveyForm(
      controllers: controllers,
      existingSurvey: survey,
      isSaving: formState.isSaving,
      error: formState.error,
      onSave: ({
        required String title,
        required String slug,
        String? description,
        required AuthRequirement authRequirement,
      }) async {
        if (isNewSurvey) {
          final created = await formManager.createSurveyWithQuestions(
            title: title,
            slug: slug,
            description: description,
            authRequirement: authRequirement,
          );
          if (created != null && context.mounted) {
            await surveyListManager.loadSurveys();
            if (context.mounted) {
              context.go('/admin');
            }
          }
        } else {
          final updated = survey!.copyWith(
            title: title,
            slug: slug,
            description: description,
            authRequirement: authRequirement,
            updatedAt: DateTime.now(),
          );
          await formManager.updateSurvey(updated);
        }
      },
    );
  }

  Widget _buildDraftQuestionsSection(
    BuildContext context,
    SurveyFormManager formManager,
    SurveyFormState formState,
    bool geminiEnabled,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final draftQuestions = formState.draftQuestions;

    // Show preview dialog when generated questions are ready
    if (formState.generatedQuestions != null &&
        formState.generatedQuestions!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AiQuestionPreviewDialog.show(
          context,
          questions: formState.generatedQuestions!,
          onApply: formManager.applyGeneratedQuestions,
          onCancel: formManager.clearGeneratedQuestions,
        );
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Questions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16),
        // Show AI generation UI when questions are empty and Gemini is enabled
        if (draftQuestions.isEmpty && geminiEnabled)
          _AiPromptInput(
            isGenerating: formState.isGenerating,
            error: formState.generationError,
            onGenerate: formManager.generateQuestions,
            onAddManually: () => _showAddDialog(context, formManager),
            isSaving: formState.isSaving,
          )
        else if (draftQuestions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No questions yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add questions to your survey',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed:
                      formState.isSaving ? null : () => _showAddDialog(context, formManager),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              DraftQuestionEditor(
                questions: draftQuestions,
                enabled: !formState.isSaving,
                onEdit: (question) =>
                    _showEditDialog(context, formManager, question),
                onDelete: (question) =>
                    formManager.deleteDraftQuestion(question.tempId),
                onReorder: formManager.reorderDraftQuestions,
                onAddChoice: (question, text) =>
                    formManager.addChoiceToDraftQuestion(question.tempId, text),
                onUpdateChoice: (question, choice, newText) => formManager
                    .updateDraftChoice(question.tempId, choice.tempId, newText),
                onDeleteChoice: (question, choice) => formManager
                    .deleteDraftChoice(question.tempId, choice.tempId),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed:
                    formState.isSaving ? null : () => _showAddDialog(context, formManager),
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),
            ],
          ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, SurveyFormManager formManager) {
    QuestionFormDialog.show(
      context,
      onSave: ({
        required String text,
        required QuestionType type,
        required bool isRequired,
        String? placeholder,
      }) {
        formManager.addDraftQuestion(
          text: text,
          type: type,
          isRequired: isRequired,
          placeholder: placeholder,
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    SurveyFormManager formManager,
    dynamic question,
  ) {
    final tempQuestion = Question(
      surveyId: 0,
      text: question.text,
      type: question.type,
      orderIndex: 0,
      isRequired: question.isRequired,
      placeholder: question.placeholder,
    );

    QuestionFormDialog.show(
      context,
      existingQuestion: tempQuestion,
      onSave: ({
        required String text,
        required QuestionType type,
        required bool isRequired,
        String? placeholder,
      }) {
        formManager.updateDraftQuestion(
          tempId: question.tempId,
          text: text,
          type: type,
          isRequired: isRequired,
          placeholder: placeholder,
        );
      },
    );
  }

  /// Returns true if the survey can be published.
  bool _canPublish(QuestionListState state) {
    if (state.questions.isEmpty) return false;

    for (final question in state.questions) {
      if (question.type == QuestionType.singleChoice ||
          question.type == QuestionType.multipleChoice) {
        final choices = state.choicesByQuestion[question.id] ?? [];
        if (choices.isEmpty) return false;
      }
    }

    return true;
  }

  Future<void> _publishSurvey(
    BuildContext context,
    SurveyListManager manager,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Survey'),
        content: const Text(
          'Are you sure you want to publish this survey?\n\n'
          'Once published, you will not be able to edit the questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed == true && surveyId != null) {
      final success = await manager.publishSurvey(surveyId!);
      if (success && context.mounted) {
        context.go('/admin');
      }
    }
  }
}

/// Widget for AI prompt input to generate questions.
class _AiPromptInput extends StatefulWidget {
  final bool isGenerating;
  final String? error;
  final void Function(String prompt) onGenerate;
  final VoidCallback onAddManually;
  final bool isSaving;

  const _AiPromptInput({
    required this.isGenerating,
    required this.error,
    required this.onGenerate,
    required this.onAddManually,
    required this.isSaving,
  });

  @override
  State<_AiPromptInput> createState() => _AiPromptInputState();
}

class _AiPromptInputState extends State<_AiPromptInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 24,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Generate with AI',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Describe your survey and AI will generate questions for you.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Example: Onboarding survey for a fitness app asking about exercise experience, target weight, and weekly workout frequency',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: colorScheme.surface,
            ),
            maxLines: 3,
            enabled: !widget.isGenerating && !widget.isSaving,
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.error!,
              style: TextStyle(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: widget.isGenerating || widget.isSaving
                    ? null
                    : () {
                        final prompt = _controller.text.trim();
                        if (prompt.isNotEmpty) {
                          widget.onGenerate(prompt);
                        }
                      },
                icon: widget.isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(widget.isGenerating ? 'Generating...' : 'Generate'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: widget.isGenerating || widget.isSaving
                    ? null
                    : widget.onAddManually,
                child: const Text('Add manually'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
