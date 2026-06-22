import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/extensions/question_type_presentation.dart';
import '../../../../core/localization/app_localizations.dart';
import '../models/draft_question.dart';

/// Widget for editing draft questions and their choices.
class DraftQuestionEditor extends StatelessWidget {
  final List<DraftQuestion> questions;
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: ReorderableDragStartListener(
              index: widget.index,
              enabled: widget.enabled,
              child: Icon(
                Icons.drag_indicator,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(
              widget.question.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Icon(
                  widget.question.type.icon,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr(widget.question.type.label),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.question.isRequired) ...[
                  const SizedBox(width: 8),
                  Text(
                    context.tr('Required'),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.question.hasChoices)
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                if (widget.enabled) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: widget.onEdit,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                    ),
                    onPressed: widget.onDelete,
                  ),
                ],
              ],
            ),
          ),
          if (_isExpanded && widget.question.hasChoices)
            _ChoicesSection(
              choices: widget.question.choices,
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
  final bool enabled;
  final void Function(LocalizedText textTranslations) onAdd;
  final void Function(DraftChoice choice, LocalizedText textTranslations)
  onUpdate;
  final void Function(DraftChoice choice) onDelete;

  const _ChoicesSection({
    required this.choices,
    required this.enabled,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(
            context.tr('Choices'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...choices.map(
            (choice) => _DraftChoiceTile(
              choice: choice,
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
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 8),
          if (enabled)
            OutlinedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: Text(context.tr('Add Choice')),
            ),
        ],
      ),
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

class _DraftChoiceTile extends StatelessWidget {
  final DraftChoice choice;
  final bool enabled;
  final void Function(LocalizedText textTranslations) onUpdate;
  final VoidCallback onDelete;

  const _DraftChoiceTile({
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
