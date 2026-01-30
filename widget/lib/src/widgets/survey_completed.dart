import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

class SurveyCompleted extends StatelessWidget {
  final Survey survey;

  const SurveyCompleted({super.key, required this.survey});

  @override
  Widget build(BuildContext context) {
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
              'Thank you!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your response to "${survey.title}" has been submitted.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
