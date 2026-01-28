import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'question_result_card.dart';

/// View showing aggregated survey results.
class AggregatedResultsView extends StatelessWidget {
  final SurveyResults? results;
  final Map<int, List<QuestionOption>> optionsByQuestion;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  const AggregatedResultsView({
    super.key,
    required this.results,
    required this.optionsByQuestion,
    required this.isLoading,
    this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading && results == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && results == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (results == null || results!.totalResponses == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No responses yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Share your survey to start collecting responses',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people,
                      size: 32,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${results!.totalResponses}',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Total Responses',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Results by Question',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...results!.questionResults.map((questionResult) {
            return QuestionResultCard(
              result: questionResult,
              options: optionsByQuestion[questionResult.questionId] ?? [],
              totalResponses: results!.totalResponses,
            );
          }),
        ],
      ),
    );
  }
}
