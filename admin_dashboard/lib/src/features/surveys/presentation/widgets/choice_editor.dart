import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/localization/app_localizations.dart';

/// Widget for editing question choices.
class ChoiceEditor extends StatelessWidget {
  final List<Choice> choices;
  final bool enabled;
  final void Function(LocalizedText textTranslations) onAdd;
  final void Function(Choice choice, LocalizedText textTranslations) onUpdate;
  final void Function(Choice choice) onDelete;

  const ChoiceEditor({
    super.key,
    required this.choices,
    required this.enabled,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...choices.map(
          (choice) => _ChoiceTile(
            choice: choice,
            enabled: enabled,
            onUpdate: (textTranslations) => onUpdate(choice, textTranslations),
            onDelete: () => onDelete(choice),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: enabled ? () => _showAddDialog(context) : null,
          icon: const Icon(Icons.add),
          label: Text(context.tr('Add Choice')),
        ),
        if (choices.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            context.tr('Add at least one choice for choice questions'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final controllers = {
      for (final locale in formContentLocaleCodes)
        locale: TextEditingController(),
    };
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Add Choice')),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final locale in formContentLocaleCodes) ...[
                  TextField(
                    controller: controllers[locale],
                    decoration: InputDecoration(
                      labelText:
                          '${context.tr('Choice text')} (${formContentLocaleLabels[locale]!})',
                    ),
                    autofocus: locale == defaultFormContentLocale,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (controllers.values.every(
                (controller) => controller.text.trim().isNotEmpty,
              )) {
                onAdd(
                  LocalizedText({
                    for (final locale in formContentLocaleCodes)
                      locale: controllers[locale]!.text.trim(),
                  }),
                );
                Navigator.pop(context);
              }
            },
            child: Text(context.tr('Add')),
          ),
        ],
      ),
    ).whenComplete(() {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    });
  }
}

class _ChoiceTile extends StatelessWidget {
  final Choice choice;
  final bool enabled;
  final void Function(LocalizedText textTranslations) onUpdate;
  final VoidCallback onDelete;

  const _ChoiceTile({
    required this.choice,
    required this.enabled,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: enabled
                ? InkWell(
                    onTap: () => _showEditDialog(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(choice.text),
                    ),
                  )
                : Text(choice.text),
          ),
          if (enabled) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(context),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: colorScheme.error,
              ),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controllers = {
      for (final locale in formContentLocaleCodes)
        locale: TextEditingController(
          text: choice.textTranslations.valueFor(locale),
        ),
    };
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Edit Choice')),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final locale in formContentLocaleCodes) ...[
                  TextField(
                    controller: controllers[locale],
                    decoration: InputDecoration(
                      labelText:
                          '${context.tr('Choice text')} (${formContentLocaleLabels[locale]!})',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (controllers.values.every(
                (controller) => controller.text.trim().isNotEmpty,
              )) {
                onUpdate(
                  LocalizedText({
                    for (final locale in formContentLocaleCodes)
                      locale: controllers[locale]!.text.trim(),
                  }),
                );
                Navigator.pop(context);
              }
            },
            child: Text(context.tr('Save')),
          ),
        ],
      ),
    ).whenComplete(() {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    });
  }
}
