import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/forms/slug_auto_fill.dart';
import '../../../../core/localization/app_localizations.dart';
import '../capsules/survey_form_capsule.dart';
import 'localized_text_field_group.dart';
import 'localized_text_helpers.dart';

/// Form widget for creating/editing survey basic info (title, slug, etc.).
class SurveyForm extends StatefulWidget {
  final SurveyFormControllers controllers;
  final Survey? existingSurvey;
  final bool isSaving;
  final String? error;
  final String primaryLocale;
  final Iterable<String> locales;
  final bool showSubmitButton;
  final Future<void> Function({
    required String slug,
    required LocalizedText titleTranslations,
    required LocalizedText descriptionTranslations,
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
    required this.onSave,
  });

  @override
  SurveyFormWidgetState createState() => SurveyFormWidgetState();
}

class SurveyFormWidgetState extends State<SurveyForm> {
  final _formKey = GlobalKey<FormState>();
  final _slugAutoFill = SlugAutoFill();
  String? _listeningTitleLocale;

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return HuxCard(
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
            Text(
              context.tr('Localized descriptions'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            LocalizedTextFieldGroup(
              controllers: widget.controllers.descriptionTranslations,
              primaryLocale: widget.primaryLocale,
              locales: widget.locales,
              labelText: context.tr('Description (optional)'),
              hintText: context.tr('Brief description of the survey'),
              enabled: !widget.isSaving,
              maxLines: 2,
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
  }

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
