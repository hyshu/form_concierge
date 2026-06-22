import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import 'survey_status_chip.dart';

/// List tile for displaying a survey with actions.
class SurveyListTile extends StatelessWidget {
  final Survey survey;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onViewResponses;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;
  final VoidCallback? onDelete;

  const SurveyListTile({
    super.key,
    required this.survey,
    required this.locale,
    required this.onTap,
    required this.onViewResponses,
    this.onPublish,
    this.onClose,
    this.onReopen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = survey.titleFor(locale);
    final description = survey.descriptionFor(locale).trim();
    return HuxCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SurveyStatusChip(status: survey.status),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HuxTokens.textSecondary(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _MetadataItem(
                icon: LucideIcons.clock3,
                text: _formatDate(survey.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _buildActions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onPublish != null)
          _ActionButton(
            icon: LucideIcons.upload,
            onPressed: onPublish,
            tooltip: context.tr('Publish'),
          ),
        if (onClose != null)
          _ActionButton(
            icon: LucideIcons.circleStop,
            onPressed: onClose,
            tooltip: context.tr('Close'),
          ),
        if (onReopen != null)
          _ActionButton(
            icon: LucideIcons.circlePlay,
            onPressed: onReopen,
            tooltip: context.tr('Reopen'),
          ),
        _ActionButton(
          icon: LucideIcons.chartNoAxesColumn,
          onPressed: onViewResponses,
          tooltip: context.tr('View Responses'),
        ),
        if (onDelete != null)
          _ActionButton(
            icon: LucideIcons.trash2,
            onPressed: onDelete,
            tooltip: context.tr('Delete'),
            destructive: true,
          ),
      ],
    );
  }

  String _formatDate(DateTime date) => date.toIsoDateString();
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: HuxButton(
        onPressed: onPressed,
        variant: HuxButtonVariant.ghost,
        size: HuxButtonSize.small,
        icon: icon,
        textColor: destructive ? HuxTokens.textDestructive(context) : null,
        child: const SizedBox(width: 0),
      ),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetadataItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final color = HuxTokens.textSecondary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
