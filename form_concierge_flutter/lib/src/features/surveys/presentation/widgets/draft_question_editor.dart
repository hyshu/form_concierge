import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../models/draft_question.dart';

/// Widget for editing draft questions and their choices.
class DraftQuestionEditor extends StatelessWidget {
  final List<DraftQuestion> questions;
  final bool enabled;
  final void Function(DraftQuestion question) onEdit;
  final void Function(DraftQuestion question) onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(DraftQuestion question, String text) onAddChoice;
  final void Function(
    DraftQuestion question,
    DraftChoice choice,
    String newText,
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
      onReorder: onReorder,
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
  final void Function(String text) onAddChoice;
  final void Function(DraftChoice choice, String newText) onUpdateChoice;
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
                  _iconForType(widget.question.type),
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _labelForType(widget.question.type),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.question.isRequired) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Required',
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

  IconData _iconForType(QuestionType type) {
    return switch (type) {
      QuestionType.singleChoice => Icons.radio_button_checked,
      QuestionType.multipleChoice => Icons.check_box,
      QuestionType.textSingle => Icons.short_text,
      QuestionType.textMultiLine => Icons.notes,
    };
  }

  String _labelForType(QuestionType type) {
    return switch (type) {
      QuestionType.singleChoice => 'Single Choice',
      QuestionType.multipleChoice => 'Multiple Choice',
      QuestionType.textSingle => 'Short Text',
      QuestionType.textMultiLine => 'Long Text',
    };
  }
}

class _ChoicesSection extends StatelessWidget {
  final List<DraftChoice> choices;
  final bool enabled;
  final void Function(String text) onAdd;
  final void Function(DraftChoice choice, String newText) onUpdate;
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
            'Choices',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...choices.map(
            (choice) => _DraftChoiceTile(
              choice: choice,
              enabled: enabled,
              onUpdate: (newText) => onUpdate(choice, newText),
              onDelete: () => onDelete(choice),
            ),
          ),
          if (choices.isEmpty)
            Text(
              'No choices yet. Add at least one choice.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 8),
          if (enabled)
            OutlinedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Choice'),
            ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Choice'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Choice text',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onAdd(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _DraftChoiceTile extends StatefulWidget {
  final DraftChoice choice;
  final bool enabled;
  final void Function(String newText) onUpdate;
  final VoidCallback onDelete;

  const _DraftChoiceTile({
    required this.choice,
    required this.enabled,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_DraftChoiceTile> createState() => _DraftChoiceTileState();
}

class _DraftChoiceTileState extends State<_DraftChoiceTile> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.choice.text);
  }

  @override
  void didUpdateWidget(_DraftChoiceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.choice.text != widget.choice.text && !_isEditing) {
      _controller.text = widget.choice.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onSubmitted: _save,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _save(_controller.text),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _controller.text = widget.choice.text;
                });
              },
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

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
            child: widget.enabled
                ? InkWell(
                    onTap: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(widget.choice.text),
                    ),
                  )
                : Text(widget.choice.text),
          ),
          if (widget.enabled) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: colorScheme.error,
              ),
              onPressed: widget.onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  void _save(String value) {
    if (value.trim().isNotEmpty && value.trim() != widget.choice.text) {
      widget.onUpdate(value.trim());
    }
    setState(() {
      _isEditing = false;
    });
  }
}
