import 'package:flutter/material.dart';

/// Prompt input for generating draft survey questions with AI.
class AiPromptInput extends StatefulWidget {
  final bool isGenerating;
  final String? error;
  final void Function(String prompt) onGenerate;
  final VoidCallback onAddManually;
  final bool isSaving;

  const AiPromptInput({
    super.key,
    required this.isGenerating,
    required this.error,
    required this.onGenerate,
    required this.onAddManually,
    required this.isSaving,
  });

  @override
  State<AiPromptInput> createState() => _AiPromptInputState();
}

class _AiPromptInputState extends State<AiPromptInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 24,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Generate with AI',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Describe your survey and AI will generate questions for you.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText:
                  'Example: Onboarding survey for a fitness app asking about exercise experience, target weight, and weekly workout frequency',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: colorScheme.surface,
            ),
            maxLines: 3,
            enabled: !widget.isGenerating && !widget.isSaving,
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.error!,
              style: TextStyle(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: widget.isGenerating || widget.isSaving
                    ? null
                    : () {
                        final prompt = _controller.text.trim();
                        if (prompt.isNotEmpty) {
                          widget.onGenerate(prompt);
                        }
                      },
                icon: widget.isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(widget.isGenerating ? 'Generating...' : 'Generate'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: widget.isGenerating || widget.isSaving
                    ? null
                    : widget.onAddManually,
                child: const Text('Add manually'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
