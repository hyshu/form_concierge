import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';
import 'package:rearch/rearch.dart';

import '../../../dashboard/presentation/capsules/survey_list_capsule.dart';
import '../capsules/question_list_capsule.dart';
import '../capsules/survey_form_capsule.dart';
import '../widgets/question_list.dart';
import '../widgets/survey_form.dart';

/// Page for editing an existing survey and its questions.
class EditSurveyPage extends RearchConsumer {
  final int surveyId;

  const EditSurveyPage({super.key, required this.surveyId});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final formManager = use(surveyFormManagerCapsule);
    final questionManager = use(questionListManagerCapsule);
    final surveyListManager = use(surveyListCapsule);
    final controllers = use(surveyFormControllersCapsule);

    final formState = formManager.getState(surveyId);
    final questionState = questionManager.getState(surveyId);

    // Load survey and questions on first build
    if (use.isFirstBuild()) {
      formManager.loadSurvey(surveyId);
      questionManager.loadQuestions(surveyId);
    }

    // Populate form when survey is loaded (track previous to detect change)
    final prevSurvey = use.previous(formState.survey);
    if (formState.survey != null && prevSurvey == null) {
      // Schedule for after build to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controllers.populateFrom(formState.survey!);
      });
    }

    if (formState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final survey = formState.survey;
    if (survey == null) {
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

    final canEdit = survey.status == SurveyStatus.draft;

    return Scaffold(
      appBar: AppBar(
        title: Text(survey.title),
        actions: [
          if (survey.status == SurveyStatus.draft)
            TextButton.icon(
              onPressed: questionState.questions.isEmpty
                  ? null
                  : () => _publishSurvey(context, surveyListManager),
              icon: const Icon(Icons.publish),
              label: const Text('Publish'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!canEdit) ...[
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
                        color: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This survey is ${survey.status.name}. You cannot edit the questions.',
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
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SurveyForm(
                  controllers: controllers,
                  existingSurvey: survey,
                  isSaving: formState.isSaving,
                  error: formState.error,
                  onSave:
                      ({
                        required String title,
                        required String slug,
                        String? description,
                        required AuthRequirement authRequirement,
                      }) async {
                        final updated = survey.copyWith(
                          title: title,
                          slug: slug,
                          description: description,
                          authRequirement: authRequirement,
                          updatedAt: DateTime.now(),
                        );
                        await formManager.updateSurvey(updated);
                      },
                ),
              ),
              const SizedBox(height: 48),
              QuestionList(
                surveyId: surveyId,
                questions: questionState.questions,
                optionsByQuestion: questionState.optionsByQuestion,
                isLoading: questionState.isLoading,
                enabled: canEdit,
                onAddQuestion:
                    ({
                      required String text,
                      required QuestionType type,
                      required bool isRequired,
                      String? placeholder,
                    }) {
                      questionManager.createQuestion(
                        surveyId: surveyId,
                        text: text,
                        type: type,
                        isRequired: isRequired,
                        placeholder: placeholder,
                      );
                    },
                onEditQuestion:
                    (
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
                  questionManager.deleteQuestion(surveyId, question.id!);
                },
                onAddOption: (questionId, text) {
                  questionManager.createOption(
                    questionId: questionId,
                    surveyId: surveyId,
                    text: text,
                  );
                },
                onUpdateOption: (option, newText) {
                  final updated = option.copyWith(text: newText);
                  questionManager.updateOption(updated, surveyId);
                },
                onDeleteOption: (option) {
                  questionManager.deleteOption(option.id!, surveyId);
                },
              ),
              if (questionState.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  questionState.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

    if (confirmed == true) {
      final success = await manager.publishSurvey(surveyId);
      if (success && context.mounted) {
        context.go('/admin');
      }
    }
  }
}
