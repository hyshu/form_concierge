import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import 'survey_status_chip.dart';

/// List tile for displaying a survey with actions.
class SurveyListTile extends StatelessWidget {
  final Survey survey;
  final VoidCallback onTap;
  final VoidCallback onViewResponses;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;
  final VoidCallback onDelete;

  const SurveyListTile({
    super.key,
    required this.survey,
    required this.onTap,
    required this.onViewResponses,
    this.onPublish,
    this.onClose,
    this.onReopen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      survey.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SurveyStatusChip(status: survey.status),
                ],
              ),
              if (survey.description != null &&
                  survey.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  survey.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/${survey.slug}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.update,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(survey.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  _buildActions(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onPublish != null)
          IconButton(
            icon: const Icon(Icons.publish),
            onPressed: onPublish,
            tooltip: 'Publish',
            visualDensity: VisualDensity.compact,
          ),
        if (onClose != null)
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: onClose,
            tooltip: 'Close',
            visualDensity: VisualDensity.compact,
          ),
        if (onReopen != null)
          IconButton(
            icon: const Icon(Icons.play_circle_outlined),
            onPressed: onReopen,
            tooltip: 'Reopen',
            visualDensity: VisualDensity.compact,
          ),
        IconButton(
          icon: const Icon(Icons.analytics_outlined),
          onPressed: onViewResponses,
          tooltip: 'View Responses',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          tooltip: 'Delete',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) => date.toIsoDateString();
}
