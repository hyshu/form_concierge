import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/widgets/hux_states.dart';
import 'survey_action_buttons.dart';
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
  Widget build(context) {
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
              HuxMetadataItem(
                icon: LucideIcons.clock3,
                text: _formatDate(survey.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SurveyActionButtons(
              onPublish: onPublish,
              onClose: onClose,
              onReopen: onReopen,
              onViewResponses: onViewResponses,
              onDelete: onDelete,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => date.toIsoDateString();
}
