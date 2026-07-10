import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/constants/pagination.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/admin_media_gallery.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';
import '../../../../core/widgets/hux_states.dart';

/// Widget showing a paginated list of individual responses.
class ResponseList extends StatelessWidget {
  final Client client;
  final List<SurveyResponse> responses;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final bool canManageResponses;
  final String? error;
  final List<Question> questions;
  final Map<int, List<Choice>> choicesByQuestion;
  final Map<int, List<Answer>> answersByResponseId;
  final Set<int> loadingAnswerIds;
  final Map<int, String> answerErrorsByResponseId;
  final void Function(int page) onPageChange;
  final void Function(SurveyResponse response) onDelete;
  final void Function(SurveyResponse response) onReply;
  final void Function(int responseId) onExpandAnswers;

  const ResponseList({
    super.key,
    required this.client,
    required this.responses,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.canManageResponses,
    this.error,
    this.questions = const [],
    this.choicesByQuestion = const {},
    this.answersByResponseId = const {},
    this.loadingAnswerIds = const {},
    this.answerErrorsByResponseId = const {},
    required this.onPageChange,
    required this.onDelete,
    required this.onReply,
    required this.onExpandAnswers,
  });

  @override
  Widget build(context) {
    if (isLoading && responses.isEmpty) {
      return HuxLoadingState(
        message: context.tr('Loading...'),
        padding: const EdgeInsets.only(top: 16, bottom: 16),
      );
    }

    if (error != null && responses.isEmpty) {
      return HuxErrorState(
        message: context.trMessage(error!),
        onRetry: () => onPageChange(0),
      );
    }

    if (responses.isEmpty) {
      return HuxEmptyState(
        icon: LucideIcons.inbox,
        title: context.tr('No responses yet'),
        message: '',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: responses.length,
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            itemBuilder: (context, index) {
              final response = responses[index];
              final responseId = response.id;
              return _ResponseTile(
                key: ValueKey(responseId ?? 'response-$index'),
                client: client,
                response: response,
                index: currentPage * kDefaultPageSize + index + 1,
                canManageResponses: canManageResponses,
                questions: questions,
                choicesByQuestion: choicesByQuestion,
                answers: responseId == null
                    ? null
                    : answersByResponseId[responseId],
                isLoadingAnswers:
                    responseId != null && loadingAnswerIds.contains(responseId),
                answersError: responseId == null
                    ? null
                    : answerErrorsByResponseId[responseId],
                onDelete: () => onDelete(response),
                onReply: () => onReply(response),
                onExpand: responseId == null
                    ? null
                    : () => onExpandAnswers(responseId),
              );
            },
          ),
        ),
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HuxTokens.surfacePrimary(context),
              border: Border(
                top: BorderSide(color: HuxTokens.borderSecondary(context)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HuxIconActionButton(
                  onPressed: currentPage > 0
                      ? () => onPageChange(currentPage - 1)
                      : null,
                  icon: LucideIcons.chevronLeft,
                  tooltip: context.tr('Previous page'),
                ),
                const SizedBox(width: 16),
                Text(
                  context.tr('Page {currentPage} of {totalPages}', {
                    'currentPage': currentPage + 1,
                    'totalPages': totalPages,
                  }),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                HuxIconActionButton(
                  onPressed: currentPage < totalPages - 1
                      ? () => onPageChange(currentPage + 1)
                      : null,
                  icon: LucideIcons.chevronRight,
                  tooltip: context.tr('Next page'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ResponseTile extends StatelessWidget {
  final Client client;
  final SurveyResponse response;
  final int index;
  final bool canManageResponses;
  final List<Question> questions;
  final Map<int, List<Choice>> choicesByQuestion;
  final List<Answer>? answers;
  final bool isLoadingAnswers;
  final String? answersError;
  final VoidCallback onDelete;
  final VoidCallback onReply;
  final VoidCallback? onExpand;

  const _ResponseTile({
    super.key,
    required this.client,
    required this.response,
    required this.index,
    required this.canManageResponses,
    required this.questions,
    required this.choicesByQuestion,
    required this.answers,
    required this.isLoadingAnswers,
    required this.answersError,
    required this.onDelete,
    required this.onReply,
    required this.onExpand,
  });

  @override
  Widget build(context) {
    final theme = Theme.of(context);
    final deviceInfo = response.deviceInfo;
    final deviceSummary = deviceInfo?.summary;
    final deviceDetails = deviceInfo?.detailSummary;
    final userAgent = _displayableUserAgent(deviceInfo?.userAgent);
    final metadataSummary = _metadataSummary(response.metadata);

    return HuxCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Theme(
              data: theme.copyWith(
                dividerColor: theme.colorScheme.surface.withValues(alpha: 0),
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 4, bottom: 8),
                onExpansionChanged: (expanded) {
                  if (expanded) onExpand?.call();
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: HuxTokens.surfaceSecondary(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#$index',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: HuxTokens.textSecondary(context),
                    ),
                  ),
                ),
                title: Text(
                  response.submittedAt.toIsoDateTimeString(),
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          response.userId != null
                              ? LucideIcons.user
                              : LucideIcons.userRound,
                          size: 16,
                          color: HuxTokens.iconSecondary(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          response.userId != null
                              ? context.tr('User #{id}', {
                                  'id': response.userId,
                                })
                              : context.tr('Anonymous'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: HuxTokens.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    if (deviceSummary != null) ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: LucideIcons.monitorSmartphone,
                        text: deviceSummary,
                        color: HuxTokens.textSecondary(context),
                      ),
                    ],
                    if (deviceDetails != null) ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: LucideIcons.info,
                        text: deviceDetails,
                        color: HuxTokens.textSecondary(context),
                      ),
                    ],
                    if (userAgent != null) ...[
                      const SizedBox(height: 4),
                      Tooltip(
                        message: userAgent,
                        child: _InfoRow(
                          icon: LucideIcons.globe,
                          text: userAgent,
                          color: HuxTokens.textSecondary(context),
                        ),
                      ),
                    ],
                    if (metadataSummary != null) ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: LucideIcons.tags,
                        text: metadataSummary,
                        color: HuxTokens.textSecondary(context),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      context.tr('View answers'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: HuxTokens.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                children: [
                  _AnswersBody(
                    client: client,
                    questions: questions,
                    choicesByQuestion: choicesByQuestion,
                    answers: answers,
                    followUp: response.followUp,
                    isLoading: isLoadingAnswers,
                    error: answersError,
                  ),
                ],
              ),
            ),
          ),
          if (canManageResponses)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HuxIconActionButton(
                  onPressed: onReply,
                  icon: LucideIcons.reply,
                  tooltip: context.tr('Reply'),
                ),
                HuxIconActionButton(
                  onPressed: onDelete,
                  icon: LucideIcons.trash2,
                  tooltip: context.tr('Delete response'),
                  destructive: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// HTTP client library defaults are not useful in the response list.
  /// e.g. Dart's `http` package sends `Dart/3.x (dart:io)`.
  String? _displayableUserAgent(String? userAgent) {
    final value = userAgent?.trim();
    if (value == null || value.isEmpty) return null;
    if (_isLibraryUserAgent(value)) return null;
    return value;
  }

  bool _isLibraryUserAgent(String userAgent) {
    return RegExp(
      r'^(Dart|okhttp|Go-http-client|python-requests|curl|Wget|PostmanRuntime|node-fetch|undici)(/|\s|$)',
      caseSensitive: false,
    ).hasMatch(userAgent);
  }

  String? _metadataSummary(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return null;
    final values = metadata.entries.take(4).map((entry) {
      final value = entry.value;
      final display = switch (value) {
        null => 'null',
        String() => value,
        num() || bool() => '$value',
        List() => '[${value.length}]',
        Map() => '{${value.length}}',
        _ => '$value',
      };
      return '${entry.key}: $display';
    });
    return values.join(' / ');
  }
}

class _AnswersBody extends StatelessWidget {
  final Client client;
  final List<Question> questions;
  final Map<int, List<Choice>> choicesByQuestion;
  final List<Answer>? answers;
  final FollowUp? followUp;
  final bool isLoading;
  final String? error;

  const _AnswersBody({
    required this.client,
    required this.questions,
    required this.choicesByQuestion,
    required this.answers,
    this.followUp,
    required this.isLoading,
    required this.error,
  });

  @override
  Widget build(context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: HuxTokens.primary(context),
              ),
            ),
            const SizedBox(width: 12),
            Text(context.tr('Loading...')),
          ],
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          context.trMessage(error!),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }

    if (answers == null) {
      return const SizedBox.shrink();
    }

    final questionById = {
      for (final question in questions)
        if (question.id != null) question.id!: question,
    };
    final sortedAnswers = List<Answer>.from(answers!)
      ..sort((a, b) {
        final aOrder = questionById[a.questionId]?.orderIndex ?? a.questionId;
        final bOrder = questionById[b.questionId]?.orderIndex ?? b.questionId;
        return aOrder.compareTo(bOrder);
      });

    if (sortedAnswers.isEmpty && followUp == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          context.tr('No answers for this response'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: HuxTokens.textSecondary(context),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sortedAnswers.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              context.tr('No answers for this response'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HuxTokens.textSecondary(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        for (final answer in sortedAnswers)
          _AnswerRow(
            key: ValueKey('answer-${answer.id ?? answer.questionId}'),
            client: client,
            question: questionById[answer.questionId],
            answer: answer,
            choices: choicesByQuestion[answer.questionId] ?? const [],
          ),
        if (followUp != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              context.tr('Follow-up interview'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              context.tr('Follow-up status: {status}', {
                'status': followUp!.status.name,
              }),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HuxTokens.textSecondary(context),
              ),
            ),
          ),
          for (final item in followUp!.items)
            _FollowUpAnswerRow(
              key: ValueKey('follow-up-${item.id}'),
              client: client,
              item: item,
            ),
        ],
      ],
    );
  }
}

class _FollowUpAnswerRow extends StatelessWidget {
  final Client client;
  final FollowUpItem item;

  const _FollowUpAnswerRow({
    super.key,
    required this.client,
    required this.item,
  });

  @override
  Widget build(context) {
    final answer = item.answer;
    final isImage =
        item.type == QuestionType.imageUpload &&
        answer != null &&
        answer.fileKeys.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
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
            item.text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: HuxTokens.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          if (isImage)
            AdminMediaGallery(client: client, fileKeys: answer.fileKeys)
          else
            SelectableText(
              _formatFollowUpAnswer(item),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  String _formatFollowUpAnswer(FollowUpItem item) {
    final answer = item.answer;
    if (answer == null) return '—';
    final text = answer.textValue?.trim();
    if (text != null && text.isNotEmpty) return text;
    if (answer.selectedChoiceIds.isEmpty) return '—';
    final labelsById = {
      for (final choice in item.choices) choice.id: choice.label,
    };
    return answer.selectedChoiceIds
        .map((id) => labelsById[id] ?? id)
        .join(', ');
  }
}

class _AnswerRow extends StatelessWidget {
  final Client client;
  final Question? question;
  final Answer answer;
  final List<Choice> choices;

  const _AnswerRow({
    super.key,
    required this.client,
    required this.question,
    required this.answer,
    required this.choices,
  });

  @override
  Widget build(context) {
    final questionLabel = question?.text ?? 'Q${answer.questionId}';
    final fileKeys = answer.fileKeys;
    final isImage =
        (question?.type == QuestionType.imageUpload ||
            (fileKeys != null && fileKeys.isNotEmpty)) &&
        fileKeys != null &&
        fileKeys.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
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
            questionLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: HuxTokens.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          if (isImage)
            AdminMediaGallery(client: client, fileKeys: fileKeys)
          else
            SelectableText(
              _formatAnswerValue(answer, choices),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  String _formatAnswerValue(Answer answer, List<Choice> choices) {
    final text = answer.textValue?.trim();
    if (text != null && text.isNotEmpty) return text;

    final selected = answer.selectedChoiceIds ?? const <int>[];
    if (selected.isEmpty) return '—';

    final labelsById = {
      for (final choice in choices)
        if (choice.id != null) choice.id!: choice.text,
    };
    return selected.map((id) => labelsById[id] ?? '[#$id]').join(', ');
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(context) => Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
      ),
    ],
  );
}
