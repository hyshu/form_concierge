import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import 'localized_text_field_group.dart';

/// Widget for editing question choices.
class ChoiceEditor extends StatelessWidget {
  final List<Choice> choices;
  final String primaryLocale;
  final Iterable<String> locales;
  final bool enabled;
  final void Function(LocalizedText textTranslations) onAdd;
  final void Function(Choice choice, LocalizedText textTranslations) onUpdate;
  final void Function(Choice choice) onDelete;

  const ChoiceEditor({
    super.key,
    required this.choices,
    this.primaryLocale = defaultFormContentLocale,
    this.locales = formContentLocaleCodes,
    required this.enabled,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...choices.map(
          (choice) => _ChoiceTile(
            choice: choice,
            primaryLocale: primaryLocale,
            locales: locales,
            enabled: enabled,
            onUpdate: (textTranslations) => onUpdate(choice, textTranslations),
            onDelete: () => onDelete(choice),
          ),
        ),
        const SizedBox(height: 8),
        HuxButton(
          onPressed: enabled ? () => _showAddDialog(context) : null,
          variant: HuxButtonVariant.outline,
          icon: LucideIcons.plus,
          child: Text(context.tr('Add Choice')),
        ),
        if (choices.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            context.tr('Add at least one choice for choice questions'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: HuxTokens.textSecondary(context),
            ),
          ),
        ],
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    _showChoiceDialog(
      context,
      title: context.tr('Add Choice'),
      primaryLocale: primaryLocale,
      locales: locales,
      onSubmit: onAdd,
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final Choice choice;
  final String primaryLocale;
  final Iterable<String> locales;
  final bool enabled;
  final void Function(LocalizedText textTranslations) onUpdate;
  final VoidCallback onDelete;

  const _ChoiceTile({
    required this.choice,
    required this.primaryLocale,
    required this.locales,
    required this.enabled,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return HuxCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: HuxTokens.surfaceSecondary(context),
      onTap: enabled ? () => _showEditDialog(context) : null,
      child: Row(
        children: [
          Icon(
            LucideIcons.gripVertical,
            size: 18,
            color: HuxTokens.iconSecondary(context),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(choice.textFor(primaryLocale))),
          if (enabled) ...[
            Tooltip(
              message: context.tr('Edit'),
              child: HuxButton(
                onPressed: () => _showEditDialog(context),
                variant: HuxButtonVariant.ghost,
                size: HuxButtonSize.small,
                icon: LucideIcons.pencil,
                child: const SizedBox(width: 0),
              ),
            ),
            Tooltip(
              message: context.tr('Delete'),
              child: HuxButton(
                onPressed: onDelete,
                variant: HuxButtonVariant.ghost,
                size: HuxButtonSize.small,
                icon: LucideIcons.trash2,
                textColor: HuxTokens.textDestructive(context),
                child: const SizedBox(width: 0),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    _showChoiceDialog(
      context,
      title: context.tr('Edit Choice'),
      primaryLocale: primaryLocale,
      locales: locales,
      initialText: choice.textTranslations,
      onSubmit: onUpdate,
    );
  }
}

void _showChoiceDialog(
  BuildContext context, {
  required String title,
  required String primaryLocale,
  required Iterable<String> locales,
  required void Function(LocalizedText textTranslations) onSubmit,
  LocalizedText? initialText,
}) {
  final formKey = GlobalKey<FormState>();
  final controllers = {
    for (final locale in formContentLocaleCodes)
      locale: TextEditingController(text: initialText?.valueFor(locale) ?? ''),
  };

  showDialog(
    context: context,
    builder: (context) => HuxDialog(
      title: title,
      size: HuxDialogSize.medium,
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: LocalizedTextFieldGroup(
              controllers: controllers,
              primaryLocale: primaryLocale,
              locales: locales,
              labelText: context.tr('Choice text'),
              requiredMessage: context.tr('Choice text is required'),
              autofocus: initialText == null,
            ),
          ),
        ),
      ),
      actions: [
        HuxButton(
          onPressed: () => Navigator.pop(context),
          variant: HuxButtonVariant.secondary,
          child: Text(context.tr('Cancel')),
        ),
        HuxButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              onSubmit(
                localizedTextFromControllers(
                  controllers,
                  primaryLocale: primaryLocale,
                  locales: locales,
                ),
              );
              Navigator.pop(context);
            }
          },
          icon: initialText == null ? LucideIcons.plus : LucideIcons.save,
          child: Text(context.tr(initialText == null ? 'Add' : 'Save')),
        ),
      ],
    ),
  ).whenComplete(() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
  });
}
