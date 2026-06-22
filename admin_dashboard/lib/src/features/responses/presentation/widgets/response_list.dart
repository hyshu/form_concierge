import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/constants/pagination.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_states.dart';

/// Widget showing a paginated list of individual responses.
class ResponseList extends StatelessWidget {
  final List<SurveyResponse> responses;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final bool canManageResponses;
  final String? error;
  final void Function(int page) onPageChange;
  final void Function(SurveyResponse response) onDelete;
  final void Function(SurveyResponse response) onReply;

  const ResponseList({
    super.key,
    required this.responses,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.canManageResponses,
    this.error,
    required this.onPageChange,
    required this.onDelete,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
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
              return _ResponseTile(
                response: response,
                index: currentPage * kDefaultPageSize + index + 1,
                canManageResponses: canManageResponses,
                onDelete: () => onDelete(response),
                onReply: () => onReply(response),
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
                Tooltip(
                  message: context.tr('Previous page'),
                  child: HuxButton(
                    onPressed: currentPage > 0
                        ? () => onPageChange(currentPage - 1)
                        : null,
                    variant: HuxButtonVariant.ghost,
                    size: HuxButtonSize.small,
                    icon: LucideIcons.chevronLeft,
                    child: const SizedBox(width: 0),
                  ),
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
                Tooltip(
                  message: context.tr('Next page'),
                  child: HuxButton(
                    onPressed: currentPage < totalPages - 1
                        ? () => onPageChange(currentPage + 1)
                        : null,
                    variant: HuxButtonVariant.ghost,
                    size: HuxButtonSize.small,
                    icon: LucideIcons.chevronRight,
                    child: const SizedBox(width: 0),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ResponseTile extends StatelessWidget {
  final SurveyResponse response;
  final int index;
  final bool canManageResponses;
  final VoidCallback onDelete;
  final VoidCallback onReply;

  const _ResponseTile({
    required this.response,
    required this.index,
    required this.canManageResponses,
    required this.onDelete,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final deviceInfo = response.deviceInfo;
    final deviceSummary = deviceInfo?.summary;
    final deviceDetails = deviceInfo?.detailSummary;
    final userAgent = deviceInfo?.userAgent;
    final metadataSummary = _metadataSummary(response.metadata);

    return HuxCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: HuxTokens.surfaceSecondary(context),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$index',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: HuxTokens.textSecondary(context),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response.submittedAt.toIsoDateTimeString(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
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
                          ? context.tr('User #{id}', {'id': response.userId})
                          : context.tr('Anonymous'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                if (userAgent != null && userAgent.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Tooltip(
                    message: userAgent,
                    child: _InfoRow(
                      icon: LucideIcons.languages,
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
              ],
            ),
          ),
          if (canManageResponses)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: context.tr('Reply'),
                  child: HuxButton(
                    onPressed: onReply,
                    variant: HuxButtonVariant.ghost,
                    size: HuxButtonSize.small,
                    icon: LucideIcons.reply,
                    child: const SizedBox(width: 0),
                  ),
                ),
                Tooltip(
                  message: context.tr('Delete response'),
                  child: HuxButton(
                    onPressed: onDelete,
                    variant: HuxButtonVariant.ghost,
                    size: HuxButtonSize.small,
                    icon: LucideIcons.trash2,
                    textColor: HuxTokens.textDestructive(context),
                    child: const SizedBox(width: 0),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
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
  Widget build(BuildContext context) {
    return Row(
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
}
