import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

/// Displays a survey error with an optional retry action.
class SurveyError extends StatelessWidget {
  /// The locale used to display the form content.
  final String locale;

  /// The message displayed to the caller or user.
  final String message;

  /// Called when the user requests another attempt, when provided.
  final VoidCallback? onRetry;

  /// Creates SurveyError with the supplied values.
  const SurveyError({
    super.key,
    required this.locale,
    required this.message,
    this.onRetry,
  });

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
              semanticLabel: 'Error',
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(FormContentMessages.text(locale, 'tryAgain')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
