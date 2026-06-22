import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/constants/pagination.dart';
import '../../../../core/localization/app_localizations.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading && responses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && responses.isEmpty) {
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
            Text(context.trMessage(error!)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onPageChange(0),
              child: Text(context.tr('Retry')),
            ),
          ],
        ),
      );
    }

    if (responses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('No responses yet'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: responses.length,
            padding: const EdgeInsets.all(16),
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
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: currentPage > 0
                      ? () => onPageChange(currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
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
                IconButton(
                  onPressed: currentPage < totalPages - 1
                      ? () => onPageChange(currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
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
    final colorScheme = Theme.of(context).colorScheme;
    final deviceInfo = response.deviceInfo;
    final deviceSummary = deviceInfo?.summary;
    final deviceDetails = deviceInfo?.detailSummary;
    final userAgent = deviceInfo?.userAgent;
    final metadataSummary = _metadataSummary(response.metadata);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '#$index',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
                            ? Icons.person
                            : Icons.person_outline,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        response.userId != null
                            ? context.tr('User #{id}', {'id': response.userId})
                            : context.tr('Anonymous'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (deviceSummary != null) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.devices_outlined,
                      text: deviceSummary,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                  if (deviceDetails != null) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.info_outline,
                      text: deviceDetails,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                  if (userAgent != null && userAgent.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Tooltip(
                      message: userAgent,
                      child: _InfoRow(
                        icon: Icons.language,
                        text: userAgent,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (metadataSummary != null) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.sell_outlined,
                      text: metadataSummary,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
            if (canManageResponses)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.reply_outlined),
                    onPressed: onReply,
                    tooltip: context.tr('Reply'),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    onPressed: onDelete,
                    tooltip: context.tr('Delete response'),
                  ),
                ],
              ),
          ],
        ),
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
