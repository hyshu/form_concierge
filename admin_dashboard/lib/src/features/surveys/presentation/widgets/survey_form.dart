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
  final void Function(String locale)? onDefaultLocaleChanged;
  final Future<void> Function({
    required String defaultLocale,
    required String slug,
    required String? customDomain,
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
    this.onDefaultLocaleChanged,
    required this.onSave,
  });

  @override
  State<SurveyForm> createState() => _SurveyFormState();
}

class _SurveyFormState extends State<SurveyForm> {
  final _formKey = GlobalKey<FormState>();
  String _defaultLocale = defaultFormContentLocale;

  @override
  void initState() {
    super.initState();
    if (widget.existingSurvey != null) {
      widget.controllers.populateFrom(widget.existingSurvey!);
      _defaultLocale = widget.existingSurvey!.defaultLocale;
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
              context.tr('Default language'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: HuxTokens.textSecondary(context),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: HuxDropdown<String>(
                value: _defaultLocale,
                enabled: !widget.isSaving,
                useItemWidgetAsValue: true,
                items: [
                  for (final locale in formContentLocaleCodes)
                    HuxDropdownItem(
                      value: locale,
                      child: Text(formContentLocaleLabels[locale]!),
                    ),
                ],
                onChanged: (value) {
                  setState(() => _defaultLocale = value);
                  widget.onDefaultLocaleChanged?.call(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Localized titles'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            LocalizedTextFieldGroup(
              controllers: widget.controllers.titleTranslations,
              primaryLocale: _defaultLocale,
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
              hint: 'my-survey',
              prefixIcon: Text(
                '/',
                style: TextStyle(color: HuxTokens.textSecondary(context)),
              ),
              enabled: !widget.isSaving,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('Slug is required');
                }
                if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
                  return context.tr(
                    'Only lowercase letters, numbers, and hyphens allowed',
                  );
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            HuxInput(
              controller: widget.controllers.customDomain,
              label: context.tr('Custom domain (optional)'),
              hint: 'forms.example.com',
              helperText: context.tr(
                'Use a dedicated host to open this survey without a slug.',
              ),
              prefixIcon: const Icon(LucideIcons.globe),
              enabled: !widget.isSaving,
              validator: (value) {
                final domain = value?.trim().toLowerCase() ?? '';
                if (domain.isEmpty) return null;
                if (!RegExp(
                  r'^(?=.{1,253}$)([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$',
                ).hasMatch(domain)) {
                  return context.tr(
                    'Custom domain must be a hostname like forms.example.com',
                  );
                }
                return null;
              },
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
              primaryLocale: _defaultLocale,
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
        defaultLocale: _defaultLocale,
        slug: widget.controllers.slug.text.trim(),
        customDomain: _customDomainValue(),
        titleTranslations: localizedTextFromControllers(
          widget.controllers.titleTranslations,
          primaryLocale: _defaultLocale,
        ),
        descriptionTranslations: localizedTextFromControllers(
          widget.controllers.descriptionTranslations,
          primaryLocale: _defaultLocale,
          fallbackEmptyToPrimary: false,
        ),
      );
    }
  }

  String? _customDomainValue() {
    final domain = widget.controllers.customDomain.text.trim().toLowerCase();
    return domain.isEmpty ? null : domain;
  }
}
