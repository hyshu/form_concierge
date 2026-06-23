import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/extensions/question_type_presentation.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';
import 'choice_editor.dart';

/// List tile for displaying a question with its choices.
class QuestionListTile extends StatelessWidget {
  final Question question;
  final List<Choice> choices;
  final String primaryLocale;
  final Iterable<String> locales;
  final List<QuestionVisibilityRule> visibilityRules;
  final Widget visibilityRuleEditor;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(LocalizedText textTranslations) onAddChoice;
  final void Function(Choice choice, LocalizedText textTranslations)
  onUpdateChoice;
  final void Function(Choice choice) onDeleteChoice;

  const QuestionListTile({
    super.key,
    required this.question,
    required this.choices,
    this.primaryLocale = defaultFormContentLocale,
    this.locales = formContentLocaleCodes,
    required this.visibilityRules,
    required this.visibilityRuleEditor,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
    required this.onAddChoice,
    required this.onUpdateChoice,
    required this.onDeleteChoice,
  });

  @override
  Widget build(BuildContext context) {
    final usesChoices = question.type.usesChoices;
    final validationSummary = _validationSummary(context);

    return HuxCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  question.type.icon,
                  size: 24,
                  color: HuxTokens.primary(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              question.textFor(primaryLocale),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (question.isRequired)
                            HuxBadge(
                              label: context.tr('Required'),
                              variant: HuxBadgeVariant.primary,
                              size: HuxBadgeSize.small,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(question.type.label),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HuxTokens.textSecondary(context),
                        ),
                      ),
                      if (validationSummary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          validationSummary,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: HuxTokens.textSecondary(context),
                              ),
                        ),
                      ],
                      if (visibilityRules.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.tr(
                            visibilityRules.length == 1
                                ? 'Visible when {count} rule matches'
                                : 'Visible when {count} rules match',
                            {'count': visibilityRules.length},
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: HuxTokens.primary(context)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (enabled) ...[
                  HuxIconActionButton(
                    tooltip: context.tr('Edit question'),
                    onPressed: onEdit,
                    icon: LucideIcons.pencil,
                  ),
                  HuxIconActionButton(
                    tooltip: context.tr('Delete question'),
                    onPressed: onDelete,
                    icon: LucideIcons.trash2,
                    destructive: true,
                  ),
                ],
              ],
            ),
            if (usesChoices) ...[
              const SizedBox(height: 16),
              ChoiceEditor(
                choices: choices,
                primaryLocale: primaryLocale,
                locales: locales,
                enabled: enabled,
                onAdd: onAddChoice,
                onUpdate: onUpdateChoice,
                onDelete: onDeleteChoice,
              ),
            ],
            if (!usesChoices &&
                question.placeholderFor(primaryLocale) != null) ...[
              const SizedBox(height: 8),
              Text(
                context.tr('Placeholder: {placeholder}', {
                  'placeholder': question.placeholderFor(primaryLocale),
                }),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HuxTokens.textSecondary(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            visibilityRuleEditor,
          ],
        ),
      ),
    );
  }

  String? _validationSummary(BuildContext context) {
    if (question.type.usesTextAnswer) {
      final parts = [
        if (question.minLength != null)
          context.tr('min {value}', {'value': question.minLength}),
        if (question.maxLength != null)
          context.tr('max {value}', {'value': question.maxLength}),
      ];
      return parts.isEmpty
          ? null
          : context.tr('Length: {summary}', {'summary': parts.join(', ')});
    }
    if (question.type == QuestionType.multipleChoice) {
      final parts = [
        if (question.minSelected != null)
          context.tr('min {value}', {'value': question.minSelected}),
        if (question.maxSelected != null)
          context.tr('max {value}', {'value': question.maxSelected}),
      ];
      return parts.isEmpty
          ? null
          : context.tr('Selections: {summary}', {'summary': parts.join(', ')});
    }
    return null;
  }
}
