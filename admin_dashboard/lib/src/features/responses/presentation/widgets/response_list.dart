import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/constants/pagination.dart';

/// Widget showing a paginated list of individual responses.
class ResponseList extends StatelessWidget {
  final List<SurveyResponse> responses;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final void Function(int page) onPageChange;
  final void Function(SurveyResponse response) onDelete;

  const ResponseList({
    super.key,
    required this.responses,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    this.error,
    required this.onPageChange,
    required this.onDelete,
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
            Text(error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onPageChange(0),
              child: const Text('Retry'),
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
              'No responses yet',
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
                onDelete: () => onDelete(response),
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
                  tooltip: 'Previous page',
                ),
                const SizedBox(width: 16),
                Text(
                  'Page ${currentPage + 1} of $totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: currentPage < totalPages - 1
                      ? () => onPageChange(currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next page',
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
  final VoidCallback onDelete;

  const _ResponseTile({
    required this.response,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                            ? 'User #${response.userId}'
                            : 'Anonymous',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: onDelete,
              tooltip: 'Delete response',
            ),
          ],
        ),
      ),
    );
  }
}
