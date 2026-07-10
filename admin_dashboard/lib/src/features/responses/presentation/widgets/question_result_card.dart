import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/extensions/question_type_presentation.dart';
import '../../../../core/localization/app_localizations.dart';

const int _kMaxTextResponsesPreview = 10;

/// Card displaying results for a single question.
class QuestionResultCard extends StatelessWidget {
  final QuestionResult result;
  final List<Choice> choices;
  final int totalResponses;

  const QuestionResultCard({
    super.key,
    required this.result,
    required this.choices,
    required this.totalResponses,
  });

  @override
  Widget build(BuildContext context) {
    return HuxCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.questionType.icon,
                size: 20,
                color: HuxTokens.primary(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.questionText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result.choiceCounts != null)
            _buildChoicesSection(context)
          else if (result.questionType == QuestionType.imageUpload)
            _buildImageResponses(context)
          else if (result.textResponses != null)
            _buildTextResponses(context),
        ],
      ),
    );
  }

  Widget _buildImageResponses(BuildContext context) {
    final withImages = result.individualAnswers
        .where((answer) => (answer.fileKeys?.isNotEmpty ?? false))
        .toList();
    final count = result.imageResponseCount ?? withImages.length;

    if (withImages.isEmpty) {
      return Text(
        context.tr('No image responses'),
        style: TextStyle(color: HuxTokens.textSecondary(context)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('{count} responses with images', {'count': count}),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: HuxTokens.textSecondary(context),
          ),
        ),
        const SizedBox(height: 12),
        ...withImages.take(_kMaxTextResponsesPreview).map((answer) {
          final keys = answer.fileKeys ?? const <String>[];
          return Padding(
            key: ValueKey('image-answer-${answer.responseId}'),
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HuxTokens.surfaceSecondary(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HuxTokens.borderSecondary(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Response #{id}', {
                      'id': answer.responseId,
                    }),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: HuxTokens.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('{count} image(s)', {'count': keys.length}),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    keys.join('\n'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HuxTokens.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (withImages.length > _kMaxTextResponsesPreview)
          Text(
            context.tr('…and {count} more', {
              'count': withImages.length - _kMaxTextResponsesPreview,
            }),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: HuxTokens.textSecondary(context),
            ),
          ),
      ],
    );
  }

  Widget _buildChoicesSection(BuildContext context) {
    final sortedChoices = List<Choice>.from(choices)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final answersByChoice = <int, List<IndividualAnswer>>{};
    for (final answer in result.individualAnswers) {
      for (final choiceId in answer.selectedChoiceIds ?? const <int>[]) {
        answersByChoice.putIfAbsent(choiceId, () => []).add(answer);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
          },
          border: TableBorder(
            horizontalInside: BorderSide(
              color: HuxTokens.borderSecondary(context),
            ),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: HuxTokens.surfaceSecondary(context),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Text(
                    context.tr('Choice'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Text(
                    context.tr('Count'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Text(
                    '%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            ...sortedChoices.map((choice) {
              final count = result.choiceCounts![choice.id] ?? 0;
              final percentage = totalResponses > 0
                  ? (count / totalResponses * 100).toStringAsFixed(1)
                  : '0.0';

              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Text(choice.text),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Text(
                      '$percentage%',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        if (sortedChoices.any(
          (choice) => (answersByChoice[choice.id]?.isNotEmpty ?? false),
        )) ...[
          const SizedBox(height: 8),
          ...sortedChoices.map((choice) {
            final answers = answersByChoice[choice.id] ?? const [];
            if (answers.isEmpty) return const SizedBox.shrink();
            return _ChoiceIndividualExpansion(
              key: ValueKey('choice-${result.questionId}-${choice.id}'),
              choiceLabel: choice.text,
              answers: answers,
            );
          }),
        ],
      ],
    );
  }

  Widget _buildTextResponses(BuildContext context) {
    final individuals = result.individualAnswers
        .where(
          (answer) =>
              answer.textValue != null && answer.textValue!.trim().isNotEmpty,
        )
        .toList();
    final responses = individuals.isNotEmpty
        ? individuals.map((a) => a.textValue!).toList()
        : (result.textResponses ?? []);

    if (responses.isEmpty) {
      return Text(
        context.tr('No text responses'),
        style: TextStyle(
          color: HuxTokens.textSecondary(context),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(
            responses.length == 1 ? '{count} response' : '{count} responses',
            {'count': responses.length},
          ),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: HuxTokens.textSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        if (individuals.isNotEmpty)
          ...individuals
              .take(_kMaxTextResponsesPreview)
              .map(
                (answer) => _TextIndividualExpansion(
                  key: ValueKey(
                    'text-${result.questionId}-${answer.responseId}',
                  ),
                  answer: answer,
                ),
              )
        else
          ...responses
              .take(_kMaxTextResponsesPreview)
              .map(
                (response) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HuxTokens.surfaceSecondary(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: HuxTokens.borderSecondary(context),
                    ),
                  ),
                  child: Text(response),
                ),
              ),
        if (responses.length > _kMaxTextResponsesPreview)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.tr('... and {count} more responses', {
                'count': responses.length - _kMaxTextResponsesPreview,
              }),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HuxTokens.textSecondary(context),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChoiceIndividualExpansion extends StatelessWidget {
  final String choiceLabel;
  final List<IndividualAnswer> answers;

  const _ChoiceIndividualExpansion({
    super.key,
    required this.choiceLabel,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        dividerColor: theme.colorScheme.surface.withValues(alpha: 0),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        title: Text(
          context.tr('{choice} · {count} individual', {
            'choice': choiceLabel,
            'count': answers.length,
          }),
          style: theme.textTheme.bodyMedium,
        ),
        children: [
          for (final answer in answers)
            _IndividualAnswerTile(
              key: ValueKey('ind-${answer.responseId}'),
              answer: answer,
            ),
        ],
      ),
    );
  }
}

class _TextIndividualExpansion extends StatelessWidget {
  final IndividualAnswer answer;

  const _TextIndividualExpansion({
    super.key,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = answer.textValue ?? '';
    final shortPreview = preview.length > 80
        ? '${preview.substring(0, 80)}…'
        : preview;

    return Theme(
      data: theme.copyWith(
        dividerColor: theme.colorScheme.surface.withValues(alpha: 0),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
        title: Text(
          shortPreview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: Text(
          _individualMetaLabel(context, answer),
          style: theme.textTheme.bodySmall?.copyWith(
            color: HuxTokens.textSecondary(context),
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HuxTokens.surfaceSecondary(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HuxTokens.borderSecondary(context)),
            ),
            child: SelectableText(preview),
          ),
        ],
      ),
    );
  }
}

class _IndividualAnswerTile extends StatelessWidget {
  final IndividualAnswer answer;

  const _IndividualAnswerTile({
    super.key,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        _individualMetaLabel(context, answer),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

String _individualMetaLabel(BuildContext context, IndividualAnswer answer) {
  final when = answer.submittedAt.toIsoDateTimeString();
  final who = answer.anonymousId != null && answer.anonymousId!.isNotEmpty
      ? context.tr('Anonymous · {id}', {'id': answer.anonymousId})
      : context.tr('Anonymous');
  return context.tr('Response #{id} · {when} · {who}', {
    'id': answer.responseId,
    'when': when,
    'who': who,
  });
}
