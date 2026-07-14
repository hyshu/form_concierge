import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';

class AnswerTranslationText extends StatelessWidget {
  final String originalText;
  final String? translation;
  final bool isLoading;
  final String? error;
  final VoidCallback? onTranslate;
  final TextStyle? textStyle;

  const AnswerTranslationText({
    super.key,
    required this.originalText,
    this.translation,
    this.isLoading = false,
    this.error,
    this.onTranslate,
    this.textStyle,
  });

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
