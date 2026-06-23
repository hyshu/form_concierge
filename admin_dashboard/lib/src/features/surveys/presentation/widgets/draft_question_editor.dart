import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/extensions/question_type_presentation.dart';
import '../../../../core/localization/app_localizations.dart';
import '../models/draft_question.dart';
import 'localized_text_field_group.dart';

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
                Tooltip(
                  message: context.tr('Choices'),
                  child: HuxButton(
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    variant: HuxButtonVariant.ghost,
                    size: HuxButtonSize.small,
                    icon: _isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    child: const SizedBox(width: 0),
                  ),
                ),
              if (widget.enabled) ...[
                Tooltip(
                  message: context.tr('Edit'),
                  child: HuxButton(
                    onPressed: widget.onEdit,
                    variant: HuxButtonVariant.ghost,
                    size: HuxButtonSize.small,
                    icon: LucideIcons.pencil,
                    child: const SizedBox(width: 0),
                  ),
                ),
                Tooltip(
                  message: context.tr('Delete'),
                  child: HuxButton(
                    onPressed: widget.onDelete,
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
            (choice) => _DraftChoiceTile(
              choice: choice,
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
              onPressed: () => _showChoiceDialog(
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

class _DraftChoiceTile extends StatelessWidget {
  final DraftChoice choice;
  final String primaryLocale;
  final Iterable<String> locales;
  final bool enabled;
  final void Function(LocalizedText textTranslations) onUpdate;
  final VoidCallback onDelete;

  const _DraftChoiceTile({
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
          Expanded(
            child: Text(choice.textTranslations.valueFor(primaryLocale)),
          ),
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
