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
  final String projectSlug;
  final String? surveySlug;
  final int? surveyId;
  final VoidCallback? onSubmitted;
  /// Called when the user taps the completion-screen "Done" button.
  final VoidCallback? onDone;
  final ValueChanged<SurveyResponse>? onResponseSubmitted;
  final ValueChanged<AnonymousSession>? onAnonymousSession;
  final String? anonymousId;
  final String? anonymousToken;
  final DeviceInfo? deviceInfo;
  final Map<String, dynamic>? metadata;
  final String? locale;

  const FormConciergeSurvey({
    super.key,
    required this.client,
    required this.projectSlug,
    this.surveySlug,
    this.surveyId,
    this.onSubmitted,
    this.onDone,
    this.onResponseSubmitted,
    this.onAnonymousSession,
    this.anonymousId,
    this.anonymousToken,
    this.deviceInfo,
    this.metadata,
    this.locale,
  });

  @override
  State<FormConciergeSurvey> createState() => _FormConciergeSurveyState();
}

class _FormConciergeSurveyState extends State<FormConciergeSurvey> {
  SurveyState _state = const SurveyState();
  String? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    try {
      final project = await widget.client.survey.getProjectBySlug(
        widget.projectSlug,
      );

      final survey = _selectSurvey(project);
      if (project == null || survey == null) {
        setState(() {
          _state = _state.copyWith(
            viewState: SurveyViewState.error,
            errorMessage: FormContentMessages.text(
              defaultFormContentLocale,
              'surveyNotFound',
            ),
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
        _selectedLocale = normalizeFormContentLocale(
          widget.locale ?? project.project.defaultLocale,
        );
        _state = _state.copyWith(
          viewState: SurveyViewState.ready,
          project: project.project,
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

  Survey? _selectSurvey(PublicProject? project) {
    if (project == null || project.surveys.isEmpty) return null;
    final surveySlug = widget.surveySlug?.trim();
    if (surveySlug != null && surveySlug.isNotEmpty) {
      for (final survey in project.surveys) {
        if (survey.slug == surveySlug) return survey;
      }
      return null;
    }
    final surveyId = widget.surveyId;
    if (surveyId == null) {
      return project.surveys.length == 1 ? project.surveys.first : null;
    }
    for (final survey in project.surveys) {
      if (survey.id == surveyId) return survey;
    }
    return null;
  }

  void _updateAnswer(int questionId, AnswerValue value) {
    setState(() {
      final change = applyAnswerChange(
        answers: _state.answers,
        validationErrors: _state.validationErrors,
        questions: _state.questions,
        visibilityRules: _state.visibilityRules,
        questionId: questionId,
        value: value,
      );
      _state = _state.copyWith(
        answers: change.answers,
        validationErrors: change.validationErrors,
      );
    });
  }

  ValidationErrors _validate() {
    final visibleQuestions = resolveVisibleQuestions(
      _state.questions,
      _state.visibilityRules,
      _state.answers,
    );
    return validateSurveyAnswers(_state.answers, visibleQuestions, _locale);
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
    final locale = _locale;
    final visibleQuestions = resolveVisibleQuestions(
      _state.questions,
      _state.visibilityRules,
      _state.answers,
    );
    return switch (_state.viewState) {
      SurveyViewState.loading => const SurveyLoading(),
      SurveyViewState.error => SurveyError(
        locale: locale,
        message:
            _state.errorMessage ??
            FormContentMessages.text(locale, 'errorOccurred'),
        onRetry: _loadSurvey,
      ),
      SurveyViewState.ready || SurveyViewState.submitting => SurveyContent(
        project: _state.project!,
        survey: _state.survey!,
        questions: visibleQuestions,
        choicesByQuestion: _state.choicesByQuestion,
        answers: _state.answers,
        validationErrors: _state.validationErrors,
        errorMessage: _state.errorMessage,
        locale: locale,
        isSubmitting: _state.viewState == SurveyViewState.submitting,
        onAnswerChanged: _updateAnswer,
        onLocaleChanged: (locale) {
          setState(() {
            _selectedLocale = locale;
            _state = _state.copyWith(
              validationErrors: const {},
              errorMessage: null,
            );
          });
        },
        onSubmit: _submit,
      ),
      SurveyViewState.completed => SurveyCompleted(
        survey: _state.survey!,
        locale: locale,
        onDone: widget.onDone,
      ),
    };
  }

  String get _locale => normalizeFormContentLocale(
    _selectedLocale ??
        widget.locale ??
        _state.project?.defaultLocale ??
        defaultFormContentLocale,
  );
}
