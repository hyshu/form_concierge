import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

/// Chip displaying survey status with appropriate colors.
class SurveyStatusChip extends StatelessWidget {
  final SurveyStatus status;

  const SurveyStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (label, backgroundColor, foregroundColor) = switch (status) {
      SurveyStatus.draft => (
        'Draft',
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      SurveyStatus.published => (
        'Published',
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      SurveyStatus.closed => (
        'Closed',
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      SurveyStatus.archived => (
        'Archived',
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
