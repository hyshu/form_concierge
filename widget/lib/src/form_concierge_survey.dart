import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:serverpod_auth_core_flutter/serverpod_auth_core_flutter.dart';

import 'state/survey_state.dart';
import 'state/auth_state.dart';
import 'widgets/survey_loading.dart';
import 'widgets/survey_error.dart';
import 'widgets/survey_completed.dart';
import 'widgets/survey_content.dart';
import 'widgets/auth/auth_view.dart';
import 'utils/answer_builder.dart';

class FormConciergeSurvey extends StatefulWidget {
  final Client client;
  final String surveySlug;
  final VoidCallback? onSubmitted;
  final VoidCallback? onAuthRequired;
  final String? anonymousId;

  const FormConciergeSurvey({
    super.key,
    required this.client,
    required this.surveySlug,
    this.onSubmitted,
    this.onAuthRequired,
    this.anonymousId,
  });

  @override
  State<FormConciergeSurvey> createState() => _FormConciergeSurveyState();
}

class _FormConciergeSurveyState extends State<FormConciergeSurvey> {
  SurveyState _state = const SurveyState();
  SurveyAuthState _authState = const SurveyAuthState();

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    try {
      final survey = await widget.client.survey.getBySlug(widget.surveySlug);

      if (survey == null) {
        setState(() {
          _state = _state.copyWith(
            viewState: SurveyViewState.error,
            errorMessage: 'Survey not found or not available',
          );
        });
        return;
      }

      final questions = await widget.client.survey.getQuestionsForSurvey(
        survey.id!,
      );

      final choicesByQuestion = <int, List<Choice>>{};
      for (final question in questions) {
        if (question.type == QuestionType.singleChoice ||
            question.type == QuestionType.multipleChoice) {
          final choices = await widget.client.survey.getChoicesForQuestion(
            question.id!,
          );
          choicesByQuestion[question.id!] = choices;
        }
      }

      if (survey.authRequirement == AuthRequirement.authenticated) {
        await widget.client.auth.restore();
        final isAuthenticated = widget.client.auth.isAuthenticated;

        setState(() {
          _authState = _authState.copyWith(isAuthenticated: isAuthenticated);
        });

        if (!isAuthenticated) {
          if (widget.onAuthRequired != null) {
            widget.onAuthRequired!();
            setState(() {
              _state = _state.copyWith(
                viewState: SurveyViewState.authRequired,
                survey: survey,
                questions: questions,
                choicesByQuestion: choicesByQuestion,
              );
            });
            return;
          }

          setState(() {
            _state = _state.copyWith(
              viewState: SurveyViewState.authRequired,
              survey: survey,
              questions: questions,
              choicesByQuestion: choicesByQuestion,
            );
          });
          return;
        }
      }

      setState(() {
        _state = _state.copyWith(
          viewState: SurveyViewState.ready,
          survey: survey,
          questions: questions,
          choicesByQuestion: choicesByQuestion,
        );
      });
    } on Exception catch (e) {
      setState(() {
        _state = _state.copyWith(
          viewState: SurveyViewState.error,
          errorMessage: e.toString(),
        );
      });
    }
  }

  void _updateAnswer(int questionId, dynamic value) {
    setState(() {
      final newAnswers = Map<int, dynamic>.from(_state.answers);
      newAnswers[questionId] = value;

      final newErrors = Map<int, String>.from(_state.validationErrors);
      newErrors.remove(questionId);

      _state = _state.copyWith(
        answers: newAnswers,
        validationErrors: newErrors,
      );
    });
  }

  Map<int, String> _validate() {
    final errors = <int, String>{};

    for (final question in _state.questions) {
      final answer = _state.answers[question.id];

      if (question.isRequired) {
        if (answer == null) {
          errors[question.id!] = 'This question is required';
          continue;
        }

        if (answer is String && answer.trim().isEmpty) {
          errors[question.id!] = 'This question is required';
          continue;
        }

        if (answer is List && answer.isEmpty) {
          errors[question.id!] = 'Please select at least one choice';
          continue;
        }
      }

      if (answer is String && answer.isNotEmpty) {
        if (question.minLength != null && answer.length < question.minLength!) {
          errors[question.id!] =
              'Minimum ${question.minLength} characters required';
          continue;
        }

        if (question.maxLength != null && answer.length > question.maxLength!) {
          errors[question.id!] =
              'Maximum ${question.maxLength} characters allowed';
          continue;
        }
      }
    }

    return errors;
  }

  Future<void> _submit() async {
    final errors = _validate();

    if (errors.isNotEmpty) {
      setState(() {
        _state = _state.copyWith(validationErrors: errors);
      });
      return;
    }

    setState(() {
      _state = _state.copyWith(viewState: SurveyViewState.submitting);
    });

    try {
      final answers = buildAnswers(_state.answers, _state.questions);

      await widget.client.survey.submitResponse(
        surveyId: _state.survey!.id!,
        answers: answers,
        anonymousId: widget.anonymousId,
      );

      setState(() {
        _state = _state.copyWith(viewState: SurveyViewState.completed);
      });

      widget.onSubmitted?.call();
    } on Exception catch (e) {
      setState(() {
        _state = _state.copyWith(
          viewState: SurveyViewState.ready,
          errorMessage: e.toString(),
        );
      });
    }
  }

  void _onAuthSuccess() {
    setState(() {
      _authState = _authState.copyWith(isAuthenticated: true);
      _state = _state.copyWith(viewState: SurveyViewState.ready);
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state.viewState) {
      SurveyViewState.loading => const SurveyLoading(),
      SurveyViewState.error => SurveyError(
        message: _state.errorMessage ?? 'An error occurred',
        onRetry: _loadSurvey,
      ),
      SurveyViewState.authRequired => AuthView(
        client: widget.client,
        authState: _authState,
        onAuthStateChanged: (newState) {
          setState(() {
            _authState = newState;
          });
        },
        onAuthSuccess: _onAuthSuccess,
      ),
      SurveyViewState.ready || SurveyViewState.submitting => SurveyContent(
        survey: _state.survey!,
        questions: _state.questions,
        choicesByQuestion: _state.choicesByQuestion,
        answers: _state.answers,
        validationErrors: _state.validationErrors,
        errorMessage: _state.errorMessage,
        isSubmitting: _state.viewState == SurveyViewState.submitting,
        onAnswerChanged: _updateAnswer,
        onSubmit: _submit,
      ),
      SurveyViewState.completed => SurveyCompleted(survey: _state.survey!),
    };
  }
}
