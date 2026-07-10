import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/forms/slug_auto_fill.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../surveys/presentation/widgets/localized_text_helpers.dart';

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
  final _name = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _slug = TextEditingController();
  final _customDomain = TextEditingController();
  final _slugAutoFill = SlugAutoFill();
  String _defaultLocale = defaultFormContentLocale;
  List<String> _supportedLocales = const [defaultFormContentLocale];
  bool _didSetInitialLocale = false;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        _fillSlugFromNameIfEmpty();
      }
    });
    final project = widget.existingProject;
    if (project != null) {
      _name.text = project.name;
      _slug.text = project.slug;
      _customDomain.text = project.customDomain ?? '';
      _supportedLocales = orderedFormContentLocales(project.supportedLocales);
      _defaultLocale = _supportedLocales.contains(project.defaultLocale)
          ? project.defaultLocale
          : _supportedLocales.first;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSetInitialLocale || widget.existingProject != null) return;
    final initialLocale = _formContentLocaleFromAdminLocale(
      Localizations.localeOf(context),
    );
    _defaultLocale = initialLocale;
    _supportedLocales = [initialLocale];
    _didSetInitialLocale = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocusNode.dispose();
    _slug.dispose();
    _customDomain.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    return HuxCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HuxInput(
              controller: _name,
              focusNode: _nameFocusNode,
              label: context.tr('Project name'),
              hint: context.tr('Enter project name'),
              enabled: !widget.isSaving,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('Project name is required');
                }
                return null;
              },
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _fillSlugFromNameIfEmpty(),
            ),
            const SizedBox(height: 16),
            HuxInput(
              controller: _slug,
              label: context.tr('Project URL Slug'),
              hint: 'customer-feedback',
              prefixIcon: Text(
                '/',
                style: TextStyle(color: HuxTokens.textSecondary(context)),
              ),
              enabled: !widget.isSaving,
              validator: (value) => validateSlug(
                context,
                value,
                requireLowercaseLetter: false,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            HuxInput(
              controller: _customDomain,
              label: context.tr('Custom domain (optional)'),
              hint: 'forms.example.com',
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
            _LanguageSelector(
              locales: _supportedLocales,
              enabled: !widget.isSaving,
              onPressed: _selectSupportedLocales,
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
                for (final locale in _supportedLocales)
                  HuxDropdownItem(
                    value: locale,
                    child: Text(formContentLocaleLabels[locale]!),
                  ),
              ],
              onChanged: (value) => setState(() => _defaultLocale = value),
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
        supportedLocales: _supportedLocales,
        name: _name.text.trim(),
        createdByUserId: existing?.createdByUserId,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  void _fillSlugFromNameIfEmpty() {
    _slugAutoFill.update(
      slugController: _slug,
      sourceValues: [_name.text],
      requireLowercaseLetter: false,
    );
  }

  String? _customDomainValue() {
    final domain = _customDomain.text.trim().toLowerCase();
    return domain.isEmpty ? null : domain;
  }

  Future<void> _selectSupportedLocales() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _LocaleSelectionDialog(
        selectedLocales: _supportedLocales,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _supportedLocales = orderedFormContentLocales(selected);
      if (!_supportedLocales.contains(_defaultLocale)) {
        _defaultLocale = _supportedLocales.first;
      }
    });
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.locales,
    required this.enabled,
    required this.onPressed,
  });

  final List<String> locales;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Localized languages'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: HuxTokens.textSecondary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _localeLabels(locales),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        HuxButton(
          onPressed: enabled ? onPressed : null,
          variant: HuxButtonVariant.secondary,
          icon: LucideIcons.languages,
          child: Text(context.tr('Select languages')),
        ),
      ],
    );
  }
}

class _LocaleSelectionDialog extends StatefulWidget {
  const _LocaleSelectionDialog({required this.selectedLocales});

  final List<String> selectedLocales;

  @override
  State<_LocaleSelectionDialog> createState() => _LocaleSelectionDialogState();
}

class _LocaleSelectionDialogState extends State<_LocaleSelectionDialog> {
  late final Set<String> _selected = orderedFormContentLocales(
    widget.selectedLocales,
  ).toSet();

  @override
  Widget build(context) {
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.5;
    return HuxDialog(
      title: context.tr('Localized languages'),
      size: HuxDialogSize.medium,
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxListHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final locale in formContentLocaleCodes)
                Material(
                  type: MaterialType.transparency,
                  child: CheckboxListTile(
                    key: ValueKey('project-locale-$locale'),
                    value: _selected.contains(locale),
                    onChanged: _canToggle(locale)
                        ? (value) => _toggle(locale, value ?? false)
                        : null,
                    title: Text(formContentLocaleLabels[locale]!),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: HuxTokens.primary(context),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        HuxButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: HuxButtonVariant.secondary,
          child: Text(context.tr('Cancel')),
        ),
        HuxButton(
          onPressed: () => Navigator.of(context).pop(
            orderedFormContentLocales(_selected),
          ),
          icon: LucideIcons.check,
          child: Text(context.tr('Apply')),
        ),
      ],
    );
  }

  bool _canToggle(String locale) =>
      !_selected.contains(locale) || _selected.length > 1;

  void _toggle(String locale, bool selected) => setState(() {
    if (selected) {
      _selected.add(locale);
    } else if (_selected.length > 1) {
      _selected.remove(locale);
    }
  });
}

String _localeLabels(Iterable<String> locales) => orderedFormContentLocales(
  locales,
).map((locale) => formContentLocaleLabels[locale]!).join(', ');

String _formContentLocaleFromAdminLocale(Locale locale) {
  final scriptCode = locale.scriptCode;
  final countryCode = locale.countryCode;
  final candidates = [
    if (scriptCode != null) '${locale.languageCode}-$scriptCode',
    if (countryCode != null) '${locale.languageCode}-$countryCode',
    locale.languageCode,
  ];
  for (final candidate in candidates) {
    final normalized = normalizeFormContentLocale(candidate);
    if (formContentLocaleCodes.contains(normalized)) return normalized;
  }
  return defaultFormContentLocale;
}
