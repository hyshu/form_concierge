import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/forms/slug_auto_fill.dart';
import '../../../../core/localization/app_localizations.dart';
import '../capsules/survey_form_capsule.dart';
import 'localized_text_field_group.dart';
import 'localized_text_helpers.dart';

/// Translate helper that includes a field kind for better LLM context.
typedef SurveyLocalizedTranslate =
    Future<Map<String, String>> Function({
      required String sourceLocale,
      required String sourceText,
      required List<String> targetLocales,
      required String fieldKind,
    });

/// Form widget for creating/editing survey basic info (title, slug, etc.).
class SurveyForm extends StatefulWidget {
  final SurveyFormControllers controllers;
  final Survey? existingSurvey;
  final bool isSaving;
  final String? error;
  final String primaryLocale;
  final Iterable<String> locales;
  final bool showSubmitButton;
  final bool aiTranslateEnabled;
  final bool aiGenerationEnabled;
  final bool followUpEnabled;
  final bool captchaEnabled;
  final ValueChanged<bool>? onFollowUpEnabledChanged;
  final SurveyLocalizedTranslate? onTranslate;
  final Future<void> Function({
    required String slug,
    required LocalizedText titleTranslations,
    required LocalizedText descriptionTranslations,
    required bool followUpEnabled,
    required bool captchaEnabled,
  })
  onSave;

  const SurveyForm({
    super.key,
    required this.controllers,
    this.existingSurvey,
    required this.isSaving,
    this.error,
    required this.primaryLocale,
    this.locales = formContentLocaleCodes,
    this.showSubmitButton = true,
    this.aiTranslateEnabled = false,
    this.aiGenerationEnabled = false,
    this.followUpEnabled = false,
    this.captchaEnabled = true,
    this.onFollowUpEnabledChanged,
    this.onTranslate,
    required this.onSave,
  });

  @override
  SurveyFormWidgetState createState() => SurveyFormWidgetState();
}

class SurveyFormWidgetState extends State<SurveyForm> {
  final _formKey = GlobalKey<FormState>();
  final _slugAutoFill = SlugAutoFill();
  String? _listeningTitleLocale;
  late bool _followUpEnabled;
  late bool _captchaEnabled;

  @override
  void initState() {
    super.initState();
    _followUpEnabled =
        widget.followUpEnabled ||
        (widget.existingSurvey?.followUpEnabled ?? false);
    _captchaEnabled =
        widget.existingSurvey?.captchaEnabled ?? widget.captchaEnabled;
    if (widget.existingSurvey != null) {
      widget.controllers.populateFrom(widget.existingSurvey!);
    }
    _syncTitleSlugListener();
  }

  @override
  void didUpdateWidget(SurveyForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existingSurvey != widget.existingSurvey &&
        widget.existingSurvey != null) {
      widget.controllers.populateFrom(widget.existingSurvey!);
      _followUpEnabled = widget.existingSurvey!.followUpEnabled;
      _captchaEnabled = widget.existingSurvey!.captchaEnabled;
    } else if (oldWidget.followUpEnabled != widget.followUpEnabled) {
      _followUpEnabled = widget.followUpEnabled;
    }
    if (oldWidget.controllers != widget.controllers ||
        oldWidget.primaryLocale != widget.primaryLocale ||
        oldWidget.locales != widget.locales ||
        oldWidget.existingSurvey != widget.existingSurvey) {
      oldWidget.controllers.titleTranslations[_listeningTitleLocale]
          ?.removeListener(_fillSlugFromTitleIfEmpty);
      _listeningTitleLocale = null;
      _syncTitleSlugListener();
    }
  }

  @override
  void dispose() {
    widget.controllers.titleTranslations[_listeningTitleLocale]?.removeListener(
      _fillSlugFromTitleIfEmpty,
    );
    super.dispose();
  }

  @override
  Widget build(context) => HuxCard(
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocalizedTextFieldGroup(
            controllers: widget.controllers.titleTranslations,
            primaryLocale: widget.primaryLocale,
            locales: widget.locales,
            labelText: context.tr('Title'),
            hintText: context.tr('Enter survey title'),
            enabled: !widget.isSaving,
            requiredMessage: context.tr('Title is required'),
            textInputAction: TextInputAction.next,
            aiTranslateEnabled: widget.aiTranslateEnabled,
            onTranslate: widget.onTranslate == null
                ? null
                : ({
                    required sourceLocale,
                    required sourceText,
                    required targetLocales,
                  }) => widget.onTranslate!(
                    sourceLocale: sourceLocale,
                    sourceText: sourceText,
                    targetLocales: targetLocales,
                    fieldKind: 'title',
                  ),
          ),
          const SizedBox(height: 16),
          HuxInput(
            controller: widget.controllers.slug,
            label: context.tr('URL Slug'),
            hint: 'customer-feedback',
            enabled: !widget.isSaving,
            textInputAction: TextInputAction.next,
            validator: (value) => validateSlug(context, value),
          ),
          const SizedBox(height: 16),
          LocalizedTextFieldGroup(
            controllers: widget.controllers.descriptionTranslations,
            primaryLocale: widget.primaryLocale,
            locales: widget.locales,
            labelText: context.tr('Description'),
            hintText: context.tr('Brief description of the survey'),
            enabled: !widget.isSaving,
            maxLines: 2,
            aiTranslateEnabled: widget.aiTranslateEnabled,
            onTranslate: widget.onTranslate == null
                ? null
                : ({
                    required sourceLocale,
                    required sourceText,
                    required targetLocales,
                  }) => widget.onTranslate!(
                    sourceLocale: sourceLocale,
                    sourceText: sourceText,
                    targetLocales: targetLocales,
                    fieldKind: 'description',
                  ),
          ),
          if (widget.aiGenerationEnabled) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Flutter follow-up interview')),
              subtitle: Text(
                context.tr(
                  'After the main form, optionally generate adaptive follow-up questions in Flutter apps. Skips straight to completion when none are needed.',
                ),
              ),
              value: _followUpEnabled,
              onChanged: widget.isSaving
                  ? null
                  : (value) {
                      setState(() => _followUpEnabled = value);
                      widget.onFollowUpEnabledChanged?.call(value);
                    },
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr('CAPTCHA verification')),
            subtitle: Text(
              context.tr(
                'Require Turnstile CAPTCHA on the web form to prevent bot submissions.',
              ),
            ),
            value: _captchaEnabled,
            onChanged: widget.isSaving
                ? null
                : (value) => setState(() => _captchaEnabled = value),
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 16),
            Text(
              context.trMessage(widget.error!),
              style: TextStyle(color: HuxTokens.textDestructive(context)),
            ),
          ],
          if (widget.showSubmitButton) ...[
            const SizedBox(height: 24),
            HuxButton(
              onPressed: widget.isSaving ? null : () => submit(),
              isLoading: widget.isSaving,
              width: HuxButtonWidth.expand,
              icon: widget.existingSurvey != null
                  ? LucideIcons.save
                  : LucideIcons.plus,
              child: Text(
                context.tr(
                  widget.existingSurvey != null
                      ? 'Save Changes'
                      : 'Create Survey',
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Future<bool> submit() async {
    _fillSlugFromTitleIfEmpty();
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    await widget.onSave(
      slug: widget.controllers.slug.text.trim(),
      titleTranslations: localizedTextFromControllers(
        widget.controllers.titleTranslations,
        locales: widget.locales,
      ),
      descriptionTranslations: localizedTextFromControllers(
        widget.controllers.descriptionTranslations,
        locales: widget.locales,
      ),
      followUpEnabled: _followUpEnabled,
      captchaEnabled: _captchaEnabled,
    );
    return true;
  }

  void _syncTitleSlugListener() {
    if (widget.existingSurvey != null) {
      _slugAutoFill.reset();
      return;
    }
    final locales = orderedFormContentLocales(widget.locales);
    final primary = normalizedPrimaryLocale(widget.primaryLocale);
    final titleLocale = locales.contains(primary) ? primary : locales.first;
    widget.controllers.titleTranslations[titleLocale]?.addListener(
      _fillSlugFromTitleIfEmpty,
    );
    _listeningTitleLocale = titleLocale;
  }

  void _fillSlugFromTitleIfEmpty() {
    final titleLocale = _listeningTitleLocale ?? widget.primaryLocale;
    _slugAutoFill.update(
      slugController: widget.controllers.slug,
      sourceValues: [
        widget.controllers.titleTranslations[titleLocale]?.text,
        widget.controllers.titleTranslations[defaultFormContentLocale]?.text,
        ...widget.controllers.titleTranslations.values.map(
          (controller) => controller.text,
        ),
      ],
    );
  }
}
