import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

/// Widget for editing question choices.
class ChoiceEditor extends StatelessWidget {
  final List<Choice> choices;
  final bool enabled;
  final void Function(String text) onAdd;
  final void Function(Choice choice, String newText) onUpdate;
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
            onUpdate: (newText) => onUpdate(choice, newText),
            onDelete: () => onDelete(choice),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: enabled ? () => _showAddDialog(context) : null,
          icon: const Icon(Icons.add),
          label: const Text('Add Choice'),
        ),
        if (choices.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Add at least one choice for choice questions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
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

class _ChoiceTile extends StatefulWidget {
  final Choice choice;
  final bool enabled;
  final void Function(String newText) onUpdate;
  final VoidCallback onDelete;

  const _ChoiceTile({
    required this.choice,
    required this.enabled,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<_ChoiceTile> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.choice.text);
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
          Icon(
            Icons.drag_indicator,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
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
