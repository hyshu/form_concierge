import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import 'localized_choice_dialog.dart';
import 'localized_choice_tile.dart';
import 'survey_form.dart';

/// Widget for editing question choices.
class ChoiceEditor extends StatelessWidget {
  /// The choices available for this question.
  final List<Choice> choices;

  /// The main locale used to display and edit localized content.
  final String primaryLocale;

  /// The locales available for editing or displaying translated content.
  final Iterable<String> locales;

  /// Whether the control is available for interaction.
  final bool enabled;

  /// Whether AI-assisted translation controls are available.
  final bool aiTranslateEnabled;

  /// Called when the user requests a translation of the displayed content.
  final SurveyLocalizedTranslate? onTranslate;

  /// Called when a new localized item should be created.
  final void Function(LocalizedText textTranslations) onAdd;

  /// Called with the revised localized values for an existing item.
  final void Function(Choice choice, LocalizedText textTranslations) onUpdate;

  /// Called when the user requests deletion of this item.
  final void Function(Choice choice) onDelete;

  /// Creates ChoiceEditor with the supplied values.
  const ChoiceEditor({
    super.key,
    required this.choices,
    this.primaryLocale = defaultFormContentLocale,
    this.locales = formContentLocaleCodes,
    required this.enabled,
    this.aiTranslateEnabled = false,
    this.onTranslate,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...choices.map(
        (choice) => LocalizedChoiceTile(
          textTranslations: choice.textTranslations,
          primaryLocale: primaryLocale,
          locales: locales,
          enabled: enabled,
          aiTranslateEnabled: aiTranslateEnabled,
          onTranslate: onTranslate,
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

  void _showAddDialog(BuildContext context) => showLocalizedChoiceDialog(
    context,
    title: context.tr('Add Choice'),
    primaryLocale: primaryLocale,
    locales: locales,
    aiTranslateEnabled: aiTranslateEnabled,
    onTranslate: onTranslate,
    onSubmit: onAdd,
  );
}
