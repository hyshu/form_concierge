import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/localization/app_localizations.dart';
import '../capsules/survey_form_capsule.dart';

/// Form widget for creating/editing survey basic info (title, slug, etc.).
class SurveyForm extends StatefulWidget {
  final SurveyFormControllers controllers;
  final Survey? existingSurvey;
  final bool isSaving;
  final String? error;
  final Future<void> Function({
    required String defaultLocale,
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
                  },
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('Localized titles'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final locale in formContentLocaleCodes) ...[
            TextFormField(
              controller: widget.controllers.titleTranslations[locale],
              decoration: InputDecoration(
                labelText:
                    '${context.tr('Title')} (${formContentLocaleLabels[locale]!})',
                hintText: context.tr('Enter survey title'),
              ),
              enabled: !widget.isSaving,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('Title is required');
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
          ],
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
          Text(
            context.tr('Localized descriptions'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final locale in formContentLocaleCodes) ...[
            TextFormField(
              controller: widget.controllers.descriptionTranslations[locale],
              decoration: InputDecoration(
                labelText:
                    '${context.tr('Description (optional)')} (${formContentLocaleLabels[locale]!})',
                hintText: context.tr('Brief description of the survey'),
              ),
              enabled: !widget.isSaving,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
          ],
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
        titleTranslations: widget.controllers.titleValue(),
        descriptionTranslations: widget.controllers.descriptionValue(),
      );
    }
  }
}
