import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'state/survey_state.dart';
import 'state/auth_state.dart';
import 'widgets/survey_loading.dart';
import 'widgets/survey_error.dart';
import 'widgets/survey_completed.dart';
import 'widgets/survey_content.dart';
import 'widgets/auth/auth_view.dart';

class FormConciergeSurvey extends StatefulWidget {
  final Client client;
  final String surveySlug;
  final VoidCallback? onSubmitted;
  final ValueChanged<SurveyResponse>? onResponseSubmitted;
  final ValueChanged<AnonymousSession>? onAnonymousSession;
  final VoidCallback? onAuthRequired;
  final String? anonymousId;
  final String? anonymousToken;
  final DeviceInfo? deviceInfo;
  final Map<String, dynamic>? metadata;

  const FormConciergeSurvey({
    super.key,
    required this.client,
    required this.surveySlug,
    this.onSubmitted,
    this.onResponseSubmitted,
    this.onAnonymousSession,
    this.onAuthRequired,
    this.anonymousId,
    this.anonymousToken,
    this.deviceInfo,
    this.metadata,
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

      final choicesByQuestion = await widget.client.survey.getChoicesByQuestion(
        questions,
      );

      await _ensureAnonymousSession();

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
      await _ensureAnonymousSession();

      final answers = buildAnswers(_state.answers, _state.questions);

      final response = await widget.client.survey.submitResponse(
        surveyId: _state.survey!.id!,
        answers: answers,
        anonymousId: widget.anonymousId,
        deviceInfo: _deviceInfoForContext(context),
        metadata: widget.metadata,
      );

      setState(() {
        _state = _state.copyWith(viewState: SurveyViewState.completed);
      });

      widget.onSubmitted?.call();
      widget.onResponseSubmitted?.call(response);
    } on Exception catch (e) {
      setState(() {
        _state = _state.copyWith(
          viewState: SurveyViewState.ready,
          errorMessage: e.toString(),
        );
      });
    }
  }

  Future<void> _ensureAnonymousSession() async {
    if (!widget.client.anonymous.isAuthenticated &&
        widget.anonymousToken != null) {
      widget.client.anonymous.useToken(widget.anonymousToken!);
      _authState = _authState.copyWith(
        isAuthenticated: true,
        registrationToken: widget.anonymousToken,
      );
      return;
    }

    if (!widget.client.anonymous.isAuthenticated) {
      final session = await widget.client.anonymous.createAccount(
        displayName: widget.anonymousId,
      );
      _authState = _authState.copyWith(
        isAuthenticated: true,
        registrationToken: session.token,
      );
      widget.onAnonymousSession?.call(session);
    }
  }

  void _onAuthSuccess() {
    setState(() {
      _authState = _authState.copyWith(isAuthenticated: true);
      _state = _state.copyWith(viewState: SurveyViewState.ready);
    });
  }

  DeviceInfo _deviceInfoForContext(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final platform = Theme.of(context).platform.name;
    final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final automatic = DeviceInfo(
      label: kIsWeb ? 'Web' : platform,
      platform: kIsWeb ? 'web' : 'flutter',
      os: platform,
      locale: locale,
      timezone: DateTime.now().timeZoneName,
      screenWidth: media?.size.width.round(),
      screenHeight: media?.size.height.round(),
      devicePixelRatio: media?.devicePixelRatio,
    );
    return automatic.merge(widget.deviceInfo);
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
