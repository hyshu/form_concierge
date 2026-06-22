import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownMenu<String>(
            initialSelection: _defaultLocale,
            expandedInsets: EdgeInsets.zero,
            label: Text(context.tr('Default language')),
            dropdownMenuEntries: [
              for (final locale in formContentLocaleCodes)
                DropdownMenuEntry(
                  value: locale,
                  label: formContentLocaleLabels[locale]!,
                ),
            ],
            onSelected: widget.isSaving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _defaultLocale = value);
                    widget.onDefaultLocaleChanged?.call(value);
                  },
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
          TextFormField(
            controller: widget.controllers.slug,
            decoration: InputDecoration(
              labelText: context.tr('URL Slug'),
              hintText: 'my-survey',
              prefixText: '/',
              prefixStyle: TextStyle(color: colorScheme.onSurfaceVariant),
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
          TextFormField(
            controller: widget.controllers.customDomain,
            decoration: InputDecoration(
              labelText: context.tr('Custom domain (optional)'),
              hintText: 'forms.example.com',
              helperText: context.tr(
                'Use a dedicated host to open this survey without a slug.',
              ),
            ),
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
              style: TextStyle(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.isSaving ? null : _submit,
            child: widget.isSaving
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    context.tr(
                      widget.existingSurvey != null
                          ? 'Save Changes'
                          : 'Create Survey',
                    ),
                  ),
          ),
        ],
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
