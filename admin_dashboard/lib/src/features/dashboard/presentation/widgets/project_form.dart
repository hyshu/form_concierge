import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../surveys/presentation/widgets/localized_text_field_group.dart';

class ProjectForm extends StatefulWidget {
  final Project? existingProject;
  final bool isSaving;
  final String? error;
  final Future<void> Function(Project project) onSave;

  const ProjectForm({
    super.key,
    this.existingProject,
    required this.isSaving,
    this.error,
    required this.onSave,
  });

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _slug = TextEditingController();
  final _customDomain = TextEditingController();
  late final Map<String, TextEditingController> _nameTranslations;
  late final Map<String, TextEditingController> _descriptionTranslations;
  String _defaultLocale = defaultFormContentLocale;

  @override
  void initState() {
    super.initState();
    _nameTranslations = {
      for (final locale in formContentLocaleCodes)
        locale: TextEditingController(),
    };
    _descriptionTranslations = {
      for (final locale in formContentLocaleCodes)
        locale: TextEditingController(),
    };
    final project = widget.existingProject;
    if (project != null) {
      _slug.text = project.slug;
      _customDomain.text = project.customDomain ?? '';
      _defaultLocale = project.defaultLocale;
      for (final locale in formContentLocaleCodes) {
        _nameTranslations[locale]!.text =
            project.nameTranslations.values[locale] ?? '';
        _descriptionTranslations[locale]!.text =
            project.descriptionTranslations.values[locale] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _slug.dispose();
    _customDomain.dispose();
    for (final controller in _nameTranslations.values) {
      controller.dispose();
    }
    for (final controller in _descriptionTranslations.values) {
      controller.dispose();
    }
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
            HuxInput(
              controller: _slug,
              label: context.tr('Project URL Slug'),
              hint: 'customer-feedback',
              prefixIcon: Text(
                '/',
                style: TextStyle(color: HuxTokens.textSecondary(context)),
              ),
              enabled: !widget.isSaving,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('Slug is required');
                }
                if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value.trim())) {
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
              controller: _customDomain,
              label: context.tr('Custom domain (optional)'),
              hint: 'forms.example.com',
              helperText: context.tr(
                'Use a dedicated host to open this project without a slug.',
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
              context.tr('Default language'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: HuxTokens.textSecondary(context),
              ),
            ),
            const SizedBox(height: 6),
            HuxDropdown<String>(
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
              onChanged: (value) => setState(() => _defaultLocale = value),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Localized project names'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            LocalizedTextFieldGroup(
              controllers: _nameTranslations,
              primaryLocale: _defaultLocale,
              labelText: context.tr('Project name'),
              hintText: context.tr('Enter project name'),
              enabled: !widget.isSaving,
              requiredMessage: context.tr('Project name is required'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Localized descriptions'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            LocalizedTextFieldGroup(
              controllers: _descriptionTranslations,
              primaryLocale: _defaultLocale,
              labelText: context.tr('Description (optional)'),
              hintText: context.tr('Brief description of the project'),
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
              icon: widget.existingProject == null
                  ? LucideIcons.plus
                  : LucideIcons.save,
              child: Text(
                context.tr(
                  widget.existingProject == null
                      ? 'Create Project'
                      : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final existing = widget.existingProject;
    widget.onSave(
      Project(
        id: existing?.id,
        slug: _slug.text.trim(),
        customDomain: _customDomainValue(),
        defaultLocale: _defaultLocale,
        supportedLocales: formContentLocaleCodes,
        nameTranslations: localizedTextFromControllers(
          _nameTranslations,
          primaryLocale: _defaultLocale,
        ),
        descriptionTranslations: localizedTextFromControllers(
          _descriptionTranslations,
          primaryLocale: _defaultLocale,
          fallbackEmptyToPrimary: false,
        ),
        createdByUserId: existing?.createdByUserId,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  String? _customDomainValue() {
    final domain = _customDomain.text.trim().toLowerCase();
    return domain.isEmpty ? null : domain;
  }
}
