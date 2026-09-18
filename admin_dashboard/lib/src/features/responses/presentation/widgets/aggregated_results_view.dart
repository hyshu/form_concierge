import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_states.dart';
import '../capsules/answer_translation_capsule.dart';
import 'question_result_card.dart';

/// View showing aggregated survey results.
class AggregatedResultsView extends StatelessWidget {
  /// The API client used to load data and submit changes.
  final Client client;

  /// The aggregated survey results, when available.
  final SurveyResults? results;

  /// Available choices indexed by question identifier.
  final Map<int, List<Choice>> choicesByQuestion;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// The error message, when the operation could not complete.
  final String? error;

  /// Optional state and callbacks for translating displayed answers.
  final AnswerTranslationBindings? answerTranslations;

  /// Called when the user requests fresh data from the server.
  final VoidCallback onRefresh;

  /// Creates AggregatedResultsView with the supplied values.
  const AggregatedResultsView({
    super.key,
    required this.client,
    required this.results,
    required this.choicesByQuestion,
    required this.isLoading,
    this.error,
    this.answerTranslations,
    required this.onRefresh,
  });

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) {
    if (isLoading && results == null) {
      return HuxLoadingState(
        message: context.tr('Loading...'),
        padding: const EdgeInsets.only(top: 16, bottom: 16),
      );
    }

    if (error != null && results == null) {
      return HuxErrorState(
        message: context.trMessage(error!),
        onRetry: onRefresh,
      );
    }

    if (results == null || results!.totalResponses == 0) {
      return HuxEmptyState(
        icon: LucideIcons.chartNoAxesColumn,
        title: context.tr('No responses yet'),
        message: context.tr('Share your survey to start collecting responses'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        children: [
          HuxCard(
            size: HuxCardSize.large,
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: HuxTokens.primary(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    LucideIcons.users,
                    size: 32,
                    color: HuxTokens.primary(context),
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
                            color: HuxTokens.primary(context),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      context.tr('Total Responses'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HuxTokens.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('Results by Question'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...results!.questionResults.map((questionResult) {
            return QuestionResultCard(
              client: client,
              result: questionResult,
              choices: choicesByQuestion[questionResult.questionId] ?? [],
              totalResponses: results!.totalResponses,
              answerTranslations: answerTranslations,
            );
          }),
        ],
      ),
    );
  }
}
