import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';
import 'localized_choice_dialog.dart';
import 'survey_form.dart';

/// Displays and edits a choice's translations with optional AI assistance.
class LocalizedChoiceTile extends StatelessWidget {
  /// Creates LocalizedChoiceTile with the supplied values.
  const LocalizedChoiceTile({
    super.key,
    required this.textTranslations,
    required this.primaryLocale,
    required this.locales,
    required this.enabled,
    required this.onUpdate,
    required this.onDelete,
    this.aiTranslateEnabled = false,
    this.onTranslate,
    this.leading,
  });

  /// Display text indexed by locale code.
  final LocalizedText textTranslations;

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

  /// Called with the revised localized values for an existing item.
  final void Function(LocalizedText textTranslations) onUpdate;

  /// Called when the user requests deletion of this item.
  final VoidCallback onDelete;

  /// Optional content displayed before the main list item text.
  final Widget? leading;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => HuxCard(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    backgroundColor: HuxTokens.surfaceSecondary(context),
    onTap: enabled ? () => _showEditDialog(context) : null,
    child: Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(textTranslations.valueFor(primaryLocale))),
        if (enabled) ...[
          HuxIconActionButton(
            tooltip: context.tr('Edit'),
            onPressed: () => _showEditDialog(context),
            icon: LucideIcons.pencil,
          ),
          HuxIconActionButton(
            tooltip: context.tr('Delete'),
            onPressed: onDelete,
            icon: LucideIcons.trash2,
            destructive: true,
          ),
        ],
      ],
    ),
  );

  void _showEditDialog(BuildContext context) => showLocalizedChoiceDialog(
    context,
    title: context.tr('Edit Choice'),
    primaryLocale: primaryLocale,
    locales: locales,
    initialText: textTranslations,
    aiTranslateEnabled: aiTranslateEnabled,
    onTranslate: onTranslate,
    onSubmit: onUpdate,
  );
}
