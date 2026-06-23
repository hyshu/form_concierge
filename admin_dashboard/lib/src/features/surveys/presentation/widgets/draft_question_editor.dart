import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/extensions/question_type_presentation.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';
import '../models/draft_question.dart';
import 'localized_choice_dialog.dart';
import 'localized_choice_tile.dart';

/// Widget for editing draft questions and their choices.
class DraftQuestionEditor extends StatelessWidget {
  final List<DraftQuestion> questions;
  final String primaryLocale;
  final Iterable<String> locales;
  final bool enabled;
  final void Function(DraftQuestion question) onEdit;
  final void Function(DraftQuestion question) onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(DraftQuestion question, LocalizedText textTranslations)
  onAddChoice;
  final void Function(
    DraftQuestion question,
    DraftChoice choice,
    LocalizedText textTranslations,
  )
  onUpdateChoice;
  final void Function(DraftQuestion question, DraftChoice choice)
  onDeleteChoice;

  const DraftQuestionEditor({
    super.key,
    required this.questions,
    this.primaryLocale = defaultFormContentLocale,
    this.locales = formContentLocaleCodes,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
    required this.onAddChoice,
    required this.onUpdateChoice,
    required this.onDeleteChoice,
  });

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: questions.length,
      buildDefaultDragHandles: false,
      onReorderItem: onReorder,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _DraftQuestionTile(
          key: ValueKey(question.tempId),
          index: index,
          question: question,
          primaryLocale: primaryLocale,
          locales: locales,
          enabled: enabled,
          onEdit: () => onEdit(question),
          onDelete: () => onDelete(question),
          onAddChoice: (text) => onAddChoice(question, text),
          onUpdateChoice: (choice, newText) =>
              onUpdateChoice(question, choice, newText),
          onDeleteChoice: (choice) => onDeleteChoice(question, choice),
        );
      },
    );
  }
}

class _DraftQuestionTile extends StatefulWidget {
  final int index;
  final DraftQuestion question;
  final String primaryLocale;
  final Iterable<String> locales;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(LocalizedText textTranslations) onAddChoice;
  final void Function(DraftChoice choice, LocalizedText textTranslations)
  onUpdateChoice;
  final void Function(DraftChoice choice) onDeleteChoice;

  const _DraftQuestionTile({
    super.key,
    required this.index,
    required this.question,
    required this.primaryLocale,
    required this.locales,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
    required this.onAddChoice,
    required this.onUpdateChoice,
    required this.onDeleteChoice,
  });

  @override
  State<_DraftQuestionTile> createState() => _DraftQuestionTileState();
}

class _DraftQuestionTileState extends State<_DraftQuestionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return HuxCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                enabled: widget.enabled,
                child: Icon(
                  LucideIcons.gripVertical,
                  color: HuxTokens.iconSecondary(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.question.textTranslations.valueFor(
                        widget.primaryLocale,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          widget.question.type.icon,
                          size: 16,
                          color: HuxTokens.iconSecondary(context),
                        ),
                        Text(
                          context.tr(widget.question.type.label),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: HuxTokens.textSecondary(context),
                              ),
                        ),
                        if (widget.question.isRequired)
                          HuxBadge(
                            label: context.tr('Required'),
                            variant: HuxBadgeVariant.primary,
                            size: HuxBadgeSize.small,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.question.hasChoices)
                HuxIconActionButton(
                  tooltip: context.tr('Choices'),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: _isExpanded
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                ),
              if (widget.enabled) ...[
                HuxIconActionButton(
                  tooltip: context.tr('Edit'),
                  onPressed: widget.onEdit,
                  icon: LucideIcons.pencil,
                ),
                HuxIconActionButton(
                  tooltip: context.tr('Delete'),
                  onPressed: widget.onDelete,
                  icon: LucideIcons.trash2,
                  destructive: true,
                ),
              ],
            ],
          ),
          if (_isExpanded && widget.question.hasChoices)
            _ChoicesSection(
              choices: widget.question.choices,
              primaryLocale: widget.primaryLocale,
              locales: widget.locales,
              enabled: widget.enabled,
              onAdd: widget.onAddChoice,
              onUpdate: widget.onUpdateChoice,
              onDelete: widget.onDeleteChoice,
            ),
        ],
      ),
    );
  }
}

class _ChoicesSection extends StatelessWidget {
  final List<DraftChoice> choices;
  final String primaryLocale;
  final Iterable<String> locales;
  final bool enabled;
  final void Function(LocalizedText textTranslations) onAdd;
  final void Function(DraftChoice choice, LocalizedText textTranslations)
  onUpdate;
  final void Function(DraftChoice choice) onDelete;

  const _ChoicesSection({
    required this.choices,
    required this.primaryLocale,
    required this.locales,
    required this.enabled,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: HuxTokens.borderSecondary(context)),
          Text(
            context.tr('Choices'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...choices.map(
            (choice) => LocalizedChoiceTile(
              textTranslations: choice.textTranslations,
              primaryLocale: primaryLocale,
              locales: locales,
              enabled: enabled,
              onUpdate: (textTranslations) =>
                  onUpdate(choice, textTranslations),
              onDelete: () => onDelete(choice),
            ),
          ),
          if (choices.isEmpty)
            Text(
              context.tr('No choices yet. Add at least one choice.'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HuxTokens.textSecondary(context),
              ),
            ),
          const SizedBox(height: 8),
          if (enabled)
            HuxButton(
              onPressed: () => showLocalizedChoiceDialog(
                context,
                title: context.tr('Add Choice'),
                primaryLocale: primaryLocale,
                locales: locales,
                onSubmit: onAdd,
              ),
              variant: HuxButtonVariant.outline,
              icon: LucideIcons.plus,
              child: Text(context.tr('Add Choice')),
            ),
        ],
      ),
    );
  }
}
