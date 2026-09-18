import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';

/// Displays an answer with optional translation controls, progress, and errors.
class AnswerTranslationText extends StatelessWidget {
  /// The respondent's original answer text.
  final String originalText;

  /// The translated answer text, if it has been loaded.
  final String? translation;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// The error message, when the operation could not complete.
  final String? error;

  /// Called when the user requests a translation of the displayed content.
  final VoidCallback? onTranslate;

  /// An optional text style applied to the displayed answer.
  final TextStyle? textStyle;

  /// Creates AnswerTranslationText with the supplied values.
  const AnswerTranslationText({
    super.key,
    required this.originalText,
    this.translation,
    this.isLoading = false,
    this.error,
    this.onTranslate,
    this.textStyle,
  });

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(originalText, style: textStyle),
          ),
          if (translation == null && (onTranslate != null || isLoading)) ...[
            const SizedBox(width: 4),
            if (isLoading)
              const SizedBox(
                width: 36,
                height: 36,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              HuxIconActionButton(
                icon: LucideIcons.sparkles,
                onPressed: onTranslate,
                tooltip: context.tr('Translate answer'),
              ),
          ],
        ],
      ),
      if (translation != null) ...[
        const SizedBox(height: 8),
        SelectableText(
          translation!,
          style:
              textStyle?.copyWith(color: HuxTokens.textSecondary(context)) ??
              TextStyle(color: HuxTokens.textSecondary(context)),
        ),
      ],
      if (error != null) ...[
        const SizedBox(height: 8),
        Text(
          context.trMessage(error!),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: HuxTokens.textDestructive(context),
          ),
        ),
      ],
    ],
  );
}
