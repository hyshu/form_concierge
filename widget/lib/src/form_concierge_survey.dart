import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'state/survey_state.dart';
import 'widgets/survey_loading.dart';
import 'widgets/survey_error.dart';
import 'widgets/survey_completed.dart';
import 'widgets/survey_content.dart';

class FormConciergeSurvey extends StatefulWidget {
  final Client client;
  final String surveySlug;
  final VoidCallback? onSubmitted;
  final ValueChanged<SurveyResponse>? onResponseSubmitted;
  final ValueChanged<AnonymousSession>? onAnonymousSession;
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
      final visibilityRules = await widget.client.survey
          .getVisibilityRulesForSurvey(survey.id!);

      final choicesByQuestion = await widget.client.survey.getChoicesByQuestion(
        questions,
      );

      await _ensureAnonymousSession();

      setState(() {
        _state = _state.copyWith(
          viewState: SurveyViewState.ready,
          survey: survey,
          questions: questions,
          visibilityRules: visibilityRules,
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
      final newAnswers = Map<int, dynamic>.from(_state.answers)
        ..[questionId] = value;
      final visibleQuestions = resolveVisibleQuestions(
        _state.questions,
        _state.visibilityRules,
        newAnswers,
      );

      final newErrors = Map<int, String>.from(_state.validationErrors);
      newErrors.remove(questionId);

      _state = _state.copyWith(
        answers: pruneHiddenAnswers(newAnswers, visibleQuestions),
        validationErrors: newErrors,
      );
    });
  }

  Map<int, String> _validate() {
    final visibleQuestions = resolveVisibleQuestions(
      _state.questions,
      _state.visibilityRules,
      _state.answers,
    );
    return validateSurveyAnswers(_state.answers, visibleQuestions);
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

      final visibleQuestions = resolveVisibleQuestions(
        _state.questions,
        _state.visibilityRules,
        _state.answers,
      );
      final answers = buildAnswers(_state.answers, visibleQuestions);

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
      return;
    }

    if (!widget.client.anonymous.isAuthenticated) {
      final session = await widget.client.anonymous.createAccount(
        displayName: widget.anonymousId,
      );
      widget.onAnonymousSession?.call(session);
    }
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
    final visibleQuestions = resolveVisibleQuestions(
      _state.questions,
      _state.visibilityRules,
      _state.answers,
    );
    return switch (_state.viewState) {
      SurveyViewState.loading => const SurveyLoading(),
      SurveyViewState.error => SurveyError(
        message: _state.errorMessage ?? 'An error occurred',
        onRetry: _loadSurvey,
      ),
      SurveyViewState.ready || SurveyViewState.submitting => SurveyContent(
        survey: _state.survey!,
        questions: visibleQuestions,
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
