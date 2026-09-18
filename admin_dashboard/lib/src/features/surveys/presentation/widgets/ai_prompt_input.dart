import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';

/// Prompt input for generating draft survey questions with AI.
class AiPromptInput extends StatefulWidget {
  /// Whether AI question generation is in progress.
  final bool isGenerating;

  /// The error message, when the operation could not complete.
  final String? error;

  /// Called with the prompt when AI question generation is requested.
  final void Function(String prompt) onGenerate;

  /// Called when the user chooses to create a question without AI generation.
  final VoidCallback onAddManually;

  /// Whether a save operation is in progress.
  final bool isSaving;

  /// Creates AiPromptInput with the supplied values.
  const AiPromptInput({
    super.key,
    required this.isGenerating,
    required this.error,
    required this.onGenerate,
    required this.onAddManually,
    required this.isSaving,
  });

  /// Creates the mutable state used by this widget.
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
  Widget build(context) => HuxCard(
    size: HuxCardSize.large,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 24,
              color: HuxTokens.primary(context),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('Generate with AI'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HuxTokens.primary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(
            'Describe your survey and AI will generate questions for you.',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: HuxTokens.textSecondary(context),
          ),
        ),
        const SizedBox(height: 16),
        HuxTextarea(
          controller: _controller,
          hint: context.tr(
            'Example: Onboarding survey for a fitness app asking about exercise experience, target weight, and weekly workout frequency',
          ),
          minLines: 3,
          maxLines: 5,
          enabled: !widget.isGenerating && !widget.isSaving,
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 8),
          Text(
            context.trMessage(widget.error!),
            style: TextStyle(color: HuxTokens.textDestructive(context)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            HuxButton(
              onPressed: widget.isGenerating || widget.isSaving
                  ? null
                  : () {
                      final prompt = _controller.text.trim();
                      if (prompt.isNotEmpty) {
                        widget.onGenerate(prompt);
                      }
                    },
              isLoading: widget.isGenerating,
              icon: LucideIcons.sparkles,
              child: Text(
                context.tr(
                  widget.isGenerating ? 'Generating...' : 'Generate',
                ),
              ),
            ),
            const SizedBox(width: 12),
            HuxButton(
              onPressed: widget.isGenerating || widget.isSaving
                  ? null
                  : widget.onAddManually,
              variant: HuxButtonVariant.secondary,
              child: Text(context.tr('Add manually')),
            ),
          ],
        ),
      ],
    ),
  );
}
