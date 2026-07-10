import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

class SurveyCompleted extends StatelessWidget {
  final Survey survey;
  final String locale;
  final VoidCallback? onDone;

  const SurveyCompleted({
    super.key,
    required this.survey,
    required this.locale,
    this.onDone,
  });

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
              Icons.check_circle_outline,
              size: 64,
              color: colorScheme.primary,
              semanticLabel: 'Completed',
            ),
            const SizedBox(height: 24),
            Text(
              FormContentMessages.text(locale, 'thankYou'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              FormContentMessages.text(
                locale,
                'submittedWithTitle',
              ).replaceAll('{title}', survey.titleFor(locale)),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onDone != null) ...[
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onDone,
                child: Text(FormContentMessages.text(locale, 'done')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
