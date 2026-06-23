import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import 'localized_choice_dialog.dart';
import 'localized_choice_tile.dart';

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
          (choice) => LocalizedChoiceTile(
            textTranslations: choice.textTranslations,
            primaryLocale: primaryLocale,
            locales: locales,
            enabled: enabled,
            onUpdate: (textTranslations) => onUpdate(choice, textTranslations),
            onDelete: () => onDelete(choice),
            leading: Icon(
              LucideIcons.gripVertical,
              size: 18,
              color: HuxTokens.iconSecondary(context),
            ),
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
    showLocalizedChoiceDialog(
      context,
      title: context.tr('Add Choice'),
      primaryLocale: primaryLocale,
      locales: locales,
      onSubmit: onAdd,
    );
  }
}
