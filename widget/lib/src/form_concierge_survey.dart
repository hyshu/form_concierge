import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'state/survey_state.dart';
import 'widgets/survey_loading.dart';
import 'widgets/survey_error.dart';
import 'widgets/survey_completed.dart';
import 'widgets/survey_content.dart';
import 'widgets/follow_up_content.dart';
import 'widgets/questions/image_upload_question.dart';

export 'widgets/questions/image_upload_question.dart'
    show PickedSurveyImage, ProcessSurveyImage;

/// Loads and renders a published Form Concierge survey.
///
/// The widget creates an anonymous session when [anonymousToken] is absent,
/// submits answers, and renders an adaptive follow-up when enabled. Persist the
/// session received by [onAnonymousSession] to receive replies across launches.
class FormConciergeSurvey extends StatefulWidget {
  final Client client;
  final String projectSlug;
  final String? surveySlug;
  final int? surveyId;
  final VoidCallback? onSubmitted;

  /// Called when the user taps the completion-screen "Done" button.
  final VoidCallback? onDone;
  final void Function(SurveyResponse response, List<Answer> answers)?
  onResponseSubmitted;

  /// Called after follow-up answers are saved successfully.
  final ValueChanged<SurveyResponse>? onFollowUpSubmitted;
  final ValueChanged<AnonymousSession>? onAnonymousSession;
  final String? anonymousId;
  final String? anonymousToken;
  final DeviceInfo? deviceInfo;
  final Map<String, dynamic>? metadata;
  final String? locale;

  /// When false, the in-form locale dropdown is hidden even if the project
  /// supports multiple locales. The host-provided [locale] is still used.
  final bool showLocalePicker;

  /// Optional host-side image transform before upload (resize/compress/edit).
  ///
  /// Called for each picked image. Return the image to upload, or `null` to
  /// skip that image. When omitted, the original pick is uploaded as-is.
  final ProcessSurveyImage? processImage;

  /// Shown below the submit button when the survey form is ready.
  final Widget? footer;

  /// Supplies a CAPTCHA token when the survey has CAPTCHA enabled.
  ///
  /// The widget never embeds a CAPTCHA implementation: the host resolves a
  /// token with whatever provider it chooses (e.g. Cloudflare Turnstile in a
  /// WebView) and returns it here. Return `null` to abort the submission.
  /// Called once per submit attempt, and again if a stale-session retry occurs.
  final Future<String?> Function()? captchaTokenProvider;

  /// Called when a submission fails, with the underlying error. The widget
  /// already shows an inline error message; use this to surface details.
  final void Function(Object error)? onSubmitError;

  const FormConciergeSurvey({
    super.key,
    required this.client,
    required this.projectSlug,
    this.surveySlug,
    this.surveyId,
    this.onSubmitted,
    this.onDone,
    this.onResponseSubmitted,
    this.onFollowUpSubmitted,
    this.onAnonymousSession,
    this.anonymousId,
    this.anonymousToken,
    this.deviceInfo,
    this.metadata,
    this.locale,
    this.showLocalePicker = false,
    this.processImage,
    this.footer,
    this.captchaTokenProvider,
    this.onSubmitError,
  });

  @override
  State<FormConciergeSurvey> createState() => _FormConciergeSurveyState();
}

class _FormConciergeSurveyState extends State<FormConciergeSurvey> {
  SurveyState _state = const SurveyState();
  String? _selectedLocale;

  /// Bumped whenever the survey target changes so stale loads are ignored.
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _restoreAnonymousToken();
    _loadSurvey();
  }

  @override
  void didUpdateWidget(covariant FormConciergeSurvey oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetChanged =
        oldWidget.client != widget.client ||
        oldWidget.projectSlug != widget.projectSlug ||
        oldWidget.surveySlug != widget.surveySlug ||
        oldWidget.surveyId != widget.surveyId ||
        oldWidget.anonymousId != widget.anonymousId ||
        oldWidget.anonymousToken != widget.anonymousToken;
    if (targetChanged) {
      setState(() {
        _state = const SurveyState();
        _selectedLocale = null;
      });
      _restoreAnonymousToken();
      _loadSurvey();
      return;
    }
    if (oldWidget.locale != widget.locale && widget.locale != null) {
      setState(() {
        _selectedLocale = normalizeFormContentLocale(widget.locale!);
      });
    }
  }

  Future<void> _loadSurvey() async {
    final generation = ++_loadGeneration;
    try {
      final project = await widget.client.survey.getProjectBySlug(
        widget.projectSlug,
      );

      final survey = _selectSurvey(project);
      if (project == null || survey == null) {
        if (!mounted || generation != _loadGeneration) return;
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

      // Anonymous accounts are created lazily on submit to avoid DB rows for
      // every page view (and when the host never wires onAnonymousSession).

      if (!mounted || generation != _loadGeneration) return;
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
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _state = _state.copyWith(
          viewState: SurveyViewState.error,
          errorMessage: e is ApiException
              ? e.message
              : FormContentMessages.text(
                  defaultFormContentLocale,
                  'errorOccurred',
                ),
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
        _state = _state.copyWith(validationErrors: errors, errorMessage: null);
      });
      return;
    }

    // Capture device info before any await so we do not use a stale context.
    final deviceInfo = _deviceInfoForContext(context);

    setState(() {
      _state = _state.copyWith(
        viewState: SurveyViewState.submitting,
        errorMessage: null,
      );
    });

    try {
      await _ensureAnonymousSession();

      final visibleQuestions = resolveVisibleQuestions(
        _state.questions,
        _state.visibilityRules,
        _state.answers,
      );
      final answers = buildAnswers(_state.answers, visibleQuestions);

      final idempotencyKey = generateIdempotencyKey();
      Future<SurveyResponse?> submit() async {
        final captchaRequired = _state.survey?.captchaEnabled == true;
        final captchaToken = captchaRequired
            ? await widget.captchaTokenProvider?.call()
            : null;
        if (captchaRequired && (captchaToken == null || captchaToken.isEmpty)) {
          if (!mounted) return null;
          setState(() {
            _state = _state.copyWith(
              viewState: SurveyViewState.ready,
              errorMessage: FormContentMessages.text(
                _locale,
                'captchaRequired',
              ),
            );
          });
          return null;
        }

        return widget.client.survey.submitResponse(
          surveyId: _state.survey!.id!,
          answers: answers,
          anonymousId: widget.anonymousId,
          deviceInfo: deviceInfo,
          metadata: widget.metadata,
          idempotencyKey: idempotencyKey,
          captchaToken: captchaToken,
        );
      }

      SurveyResponse? response;
      try {
        response = await submit();
      } on ApiException catch (e) {
        // Stale token (e.g. after DB rebuild) → recreate once, same as web.
        if (e.statusCode != 401) rethrow;
        widget.client.anonymous.clear();
        await _ensureAnonymousSession();
        response = await submit();
      }
      if (response == null) return;

      if (!mounted) return;
      widget.onSubmitted?.call();
      widget.onResponseSubmitted?.call(response, answers);

      if (_state.survey?.followUpEnabled == true && response.id != null) {
        setState(() {
          _state = _state.copyWith(
            viewState: SurveyViewState.followUpLoading,
            submittedResponse: response,
            errorMessage: null,
          );
        });
        await _startFollowUp(response.id!);
        return;
      }

      setState(() {
        _state = _state.copyWith(
          viewState: SurveyViewState.completed,
          submittedResponse: response,
        );
      });
    } on Exception catch (e) {
      widget.onSubmitError?.call(e);
      if (!mounted) return;
      setState(() {
        _state = _state.copyWith(
          viewState: SurveyViewState.ready,
          errorMessage: FormContentMessages.text(_locale, 'submitFailed'),
        );
      });
    }
  }

  Future<void> _startFollowUp(int responseId) async {
    try {
      final result = await widget.client.survey.generateFollowUp(
        responseId: responseId,
        locale: _locale,
      );
      if (!mounted) return;
      if (!result.needed ||
          result.followUp.status != FollowUpStatus.pending ||
          result.followUp.items.isEmpty) {
        setState(() {
          _state = _state.copyWith(viewState: SurveyViewState.completed);
        });
        return;
      }
      setState(() {
        _state = _state.copyWith(
          viewState: SurveyViewState.followUp,
          followUp: result.followUp,
          followUpAnswers: const {},
          followUpValidationErrors: const {},
          errorMessage: null,
        );
      });
    } on Exception catch (_) {
      // Follow-up is optional; main response is already saved.
      if (!mounted) return;
      setState(() {
        _state = _state.copyWith(viewState: SurveyViewState.completed);
      });
    }
  }

  void _updateFollowUpAnswer(String itemId, dynamic value) {
    setState(() {
      final next = Map<String, dynamic>.from(_state.followUpAnswers);
      next[itemId] = value;
      final errors = Map<String, String>.from(_state.followUpValidationErrors)
        ..remove(itemId);
      _state = _state.copyWith(
        followUpAnswers: next,
        followUpValidationErrors: errors,
        errorMessage: null,
      );
    });
  }

  /// Follow-up items are always optional; empty answers are allowed.
  Map<String, String> _validateFollowUp() => const {};

  Future<void> _submitFollowUp() async {
    final errors = _validateFollowUp();
    if (errors.isNotEmpty) {
      setState(() {
        _state = _state.copyWith(
          followUpValidationErrors: errors,
          errorMessage: null,
        );
      });
      return;
    }

    final responseId = _state.submittedResponse?.id;
    final followUp = _state.followUp;
    if (responseId == null || followUp == null) {
      setState(() {
        _state = _state.copyWith(viewState: SurveyViewState.completed);
      });
      return;
    }

    setState(() {
      _state = _state.copyWith(
        viewState: SurveyViewState.followUpSubmitting,
        errorMessage: null,
      );
    });

    try {
      final payload = followUp.items.map((item) {
        final value = _state.followUpAnswers[item.id];
        return switch (item.type) {
          QuestionType.textSingle || QuestionType.textMultiLine => {
            'id': item.id,
            'textValue': value is String ? value.trim() : null,
            'selectedChoiceIds': <String>[],
            'fileKeys': <String>[],
          },
          QuestionType.singleChoice => {
            'id': item.id,
            'textValue': null,
            'selectedChoiceIds': value is String && value.isNotEmpty
                ? <String>[value]
                : <String>[],
            'fileKeys': <String>[],
          },
          QuestionType.multipleChoice => {
            'id': item.id,
            'textValue': null,
            'selectedChoiceIds': value is List
                ? value.whereType<String>().toList()
                : <String>[],
            'fileKeys': <String>[],
          },
          QuestionType.imageUpload => {
            'id': item.id,
            'textValue': null,
            'selectedChoiceIds': <String>[],
            'fileKeys': value is List
                ? value.whereType<String>().toList()
                : <String>[],
          },
        };
      }).toList();

      final updated = await widget.client.survey.saveFollowUp(
        responseId: responseId,
        answers: payload,
      );
      if (!mounted) return;
      widget.onFollowUpSubmitted?.call(updated);
      setState(() {
        _state = _state.copyWith(
          viewState: SurveyViewState.completed,
          submittedResponse: updated,
        );
      });
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _state.copyWith(
          viewState: SurveyViewState.followUp,
          errorMessage: FormContentMessages.text(_locale, 'submitFailed'),
        );
      });
    }
  }

  void _restoreAnonymousToken() {
    if (!widget.client.anonymous.isAuthenticated &&
        widget.anonymousToken != null) {
      widget.client.anonymous.useToken(widget.anonymousToken!);
    }
  }

  Future<void> _ensureAnonymousSession() async {
    _restoreAnonymousToken();
    if (widget.client.anonymous.isAuthenticated) return;

    // Do not pass anonymousId as displayName — they are different concepts.
    final session = await widget.client.anonymous.createAccount();
    widget.onAnonymousSession?.call(session);
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
      timezone: _timezoneOffsetLabel(),
      screenWidth: media?.size.width.round(),
      screenHeight: media?.size.height.round(),
      devicePixelRatio: media?.devicePixelRatio,
    );
    return automatic.merge(widget.deviceInfo);
  }

  /// Prefer a stable UTC offset label over ambiguous abbreviations like "JST".
  static String _timezoneOffsetLabel() {
    final offset = DateTime.now().timeZoneOffset;
    final totalMinutes = offset.inMinutes;
    final sign = totalMinutes >= 0 ? '+' : '-';
    final abs = totalMinutes.abs();
    final hours = (abs ~/ 60).toString().padLeft(2, '0');
    final minutes = (abs % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$minutes';
  }

  @override
  Widget build(context) {
    final locale = _locale;
    final visibleQuestions = resolveVisibleQuestions(
      _state.questions,
      _state.visibilityRules,
      _state.answers,
    );
    return switch (_state.viewState) {
      SurveyViewState.loading ||
      SurveyViewState.followUpLoading => const SurveyLoading(),
      SurveyViewState.error => SurveyError(
        locale: locale,
        message:
            _state.errorMessage ??
            FormContentMessages.text(locale, 'errorOccurred'),
        onRetry: _loadSurvey,
      ),
      SurveyViewState.ready || SurveyViewState.submitting => SurveyContent(
        client: widget.client,
        project: _state.project!,
        survey: _state.survey!,
        questions: visibleQuestions,
        choicesByQuestion: _state.choicesByQuestion,
        answers: _state.answers,
        validationErrors: _state.validationErrors,
        errorMessage: _state.errorMessage,
        locale: locale,
        isSubmitting: _state.viewState == SurveyViewState.submitting,
        showLocalePicker: widget.showLocalePicker,
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
        ensureAuthenticated: _ensureAnonymousSession,
        processImage: widget.processImage,
        footer: widget.footer,
      ),
      SurveyViewState.followUp ||
      SurveyViewState.followUpSubmitting => FollowUpContent(
        client: widget.client,
        survey: _state.survey!,
        followUp: _state.followUp!,
        answers: _state.followUpAnswers,
        validationErrors: _state.followUpValidationErrors,
        errorMessage: _state.errorMessage,
        locale: locale,
        isSubmitting: _state.viewState == SurveyViewState.followUpSubmitting,
        onAnswerChanged: _updateFollowUpAnswer,
        onSubmit: _submitFollowUp,
        ensureAuthenticated: _ensureAnonymousSession,
        processImage: widget.processImage,
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
