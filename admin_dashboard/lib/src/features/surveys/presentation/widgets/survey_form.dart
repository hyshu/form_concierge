import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../capsules/survey_form_capsule.dart';
import 'localized_text_field_group.dart';

/// Form widget for creating/editing survey basic info (title, slug, etc.).
class SurveyForm extends StatefulWidget {
  final SurveyFormControllers controllers;
  final Survey? existingSurvey;
  final bool isSaving;
  final String? error;
  final String primaryLocale;
  final Iterable<String> locales;
  final Future<void> Function({
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
    required this.onSave,
  });

  @override
  State<SurveyForm> createState() => _SurveyFormState();
}

class _SurveyFormState extends State<SurveyForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.existingSurvey != null) {
      widget.controllers.populateFrom(widget.existingSurvey!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HuxCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('Localized titles'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 24),
            HuxButton(
              onPressed: widget.isSaving ? null : _submit,
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
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(
        titleTranslations: localizedTextFromControllers(
          widget.controllers.titleTranslations,
          primaryLocale: widget.primaryLocale,
          locales: widget.locales,
        ),
        descriptionTranslations: localizedTextFromControllers(
          widget.controllers.descriptionTranslations,
          primaryLocale: widget.primaryLocale,
          locales: widget.locales,
        ),
      );
    }
  }
}
