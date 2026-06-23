import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';
import 'localized_choice_dialog.dart';

class LocalizedChoiceTile extends StatelessWidget {
  const LocalizedChoiceTile({
    super.key,
    required this.textTranslations,
    required this.primaryLocale,
    required this.locales,
    required this.enabled,
    required this.onUpdate,
    required this.onDelete,
    this.leading,
  });

  final LocalizedText textTranslations;
  final String primaryLocale;
  final Iterable<String> locales;
  final bool enabled;
  final void Function(LocalizedText textTranslations) onUpdate;
  final VoidCallback onDelete;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return HuxCard(
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
  }

  void _showEditDialog(BuildContext context) {
    showLocalizedChoiceDialog(
      context,
      title: context.tr('Edit Choice'),
      primaryLocale: primaryLocale,
      locales: locales,
      initialText: textTranslations,
      onSubmit: onUpdate,
    );
  }
}
