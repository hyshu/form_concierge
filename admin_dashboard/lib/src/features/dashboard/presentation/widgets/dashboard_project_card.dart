import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';
import '../../../../core/widgets/hux_states.dart';
import '../capsules/survey_list_capsule.dart';
import 'survey_status_chip.dart';

class DashboardProjectCard extends StatelessWidget {
  const DashboardProjectCard({
    super.key,
    required this.item,
    required this.canWrite,
    required this.manager,
    required this.onEditProject,
    required this.onCreateSurvey,
    required this.onOpenSurvey,
    required this.onViewResponses,
    required this.onDeleteSurvey,
  });

  final ProjectWithSurveys item;
  final bool canWrite;
  final SurveyListManager manager;
  final VoidCallback onEditProject;
  final VoidCallback onCreateSurvey;
  final void Function(Survey survey) onOpenSurvey;
  final void Function(Survey survey) onViewResponses;
  final void Function(Survey survey) onDeleteSurvey;

  @override
  Widget build(BuildContext context) {
    final project = item.project;
    return HuxCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  HuxButton(
                    onPressed: canWrite ? onCreateSurvey : null,
                    variant: HuxButtonVariant.secondary,
                    size: HuxButtonSize.small,
                    icon: LucideIcons.plus,
                    child: Text(context.tr('Create Survey')),
                  ),
                  HuxButton(
                    onPressed: onEditProject,
                    variant: HuxButtonVariant.secondary,
                    size: HuxButtonSize.small,
                    icon: LucideIcons.settings,
                    child: Text(context.tr('Settings')),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              HuxMetadataItem(icon: LucideIcons.link, text: '/${project.slug}'),
              if (project.customDomain != null)
                HuxMetadataItem(
                  icon: LucideIcons.globe,
                  text: project.customDomain!,
                ),
              HuxMetadataItem(
                icon: LucideIcons.languages,
                text:
                    formContentLocaleLabels[project.defaultLocale] ??
                    project.defaultLocale,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (item.surveys.isEmpty)
            HuxEmptyState(
              icon: LucideIcons.circleHelp,
              title: context.tr('No surveys yet'),
              message: context.tr('Create your first survey to get started'),
              action: HuxButton(
                onPressed: canWrite ? onCreateSurvey : null,
                icon: LucideIcons.plus,
                child: Text(context.tr('Create Survey')),
              ),
            )
          else
            Column(
              children: [
                for (final survey in item.surveys)
                  _DashboardSurveyRow(
                    survey: survey,
                    locale: project.defaultLocale,
                    onTap: () => onOpenSurvey(survey),
                    onViewResponses: () => onViewResponses(survey),
                    onPublish: canWrite && survey.status == SurveyStatus.draft
                        ? () => manager.publishSurvey(survey.id!)
                        : null,
                    onClose: canWrite && survey.status == SurveyStatus.published
                        ? () => manager.closeSurvey(survey.id!)
                        : null,
                    onReopen: canWrite && survey.status == SurveyStatus.closed
                        ? () => manager.reopenSurvey(survey.id!)
                        : null,
                    onWebEnabledChanged: canWrite
                        ? (enabled) =>
                              manager.updateSurveyWebEnabled(survey, enabled)
                        : null,
                    onDelete: canWrite ? () => onDeleteSurvey(survey) : null,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DashboardSurveyRow extends StatelessWidget {
  const _DashboardSurveyRow({
    required this.survey,
    required this.locale,
    required this.onTap,
    required this.onViewResponses,
    this.onPublish,
    this.onClose,
    this.onReopen,
    this.onWebEnabledChanged,
    this.onDelete,
  });

  final Survey survey;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onViewResponses;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;
  final ValueChanged<bool>? onWebEnabledChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final description = survey.descriptionFor(locale).trim();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          survey.titleFor(locale),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SurveyStatusChip(status: survey.status),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: HuxTokens.textSecondary(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      HuxMetadataItem(
                        icon: LucideIcons.link,
                        text: survey.slug,
                      ),
                      HuxMetadataItem(
                        icon: LucideIcons.clock3,
                        text: survey.updatedAt.toIsoDateString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HuxSwitch(
                        value: survey.webEnabled,
                        onChanged: onWebEnabledChanged,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('Web public'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HuxTokens.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _DashboardSurveyActions(
              onPublish: onPublish,
              onClose: onClose,
              onReopen: onReopen,
              onViewResponses: onViewResponses,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSurveyActions extends StatelessWidget {
  const _DashboardSurveyActions({
    this.onPublish,
    this.onClose,
    this.onReopen,
    required this.onViewResponses,
    this.onDelete,
  });

  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;
  final VoidCallback onViewResponses;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onPublish != null)
          HuxIconActionButton(
            icon: LucideIcons.upload,
            onPressed: onPublish,
            tooltip: context.tr('Publish'),
          ),
        if (onClose != null)
          HuxIconActionButton(
            icon: LucideIcons.circleStop,
            onPressed: onClose,
            tooltip: context.tr('Close'),
          ),
        if (onReopen != null)
          HuxIconActionButton(
            icon: LucideIcons.circlePlay,
            onPressed: onReopen,
            tooltip: context.tr('Reopen'),
          ),
        HuxIconActionButton(
          icon: LucideIcons.chartNoAxesColumn,
          onPressed: onViewResponses,
          tooltip: context.tr('View Responses'),
        ),
        if (onDelete != null)
          HuxIconActionButton(
            icon: LucideIcons.trash2,
            onPressed: onDelete,
            tooltip: context.tr('Delete'),
            destructive: true,
          ),
      ],
    );
  }
}
