import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';
import 'package:hux/hux.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/auth_state_capsule.dart';
import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/hux_admin_shell.dart';
import '../../../../core/widgets/hux_states.dart';
import '../capsules/survey_list_capsule.dart';
import '../widgets/project_form.dart';
import '../widgets/survey_status_chip.dart';

/// Main dashboard page showing list of surveys.
class DashboardPage extends RearchConsumer {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final surveyManager = use(surveyListCapsule);
    final authManager = use(authStateCapsule);
    final client = use(clientCapsule);
    final role = client.auth.signedInUser?.role;
    final canWrite = role == AdminRole.admin || role == AdminRole.editor;
    final canManageUsers = role == AdminRole.admin;
    final (isSavingProject, setSavingProject) = use.state(false);

    if (use.isFirstBuild()) {
      surveyManager.loadProjects();
    }

    return HuxAdminShell(
      title: context.tr('Surveys'),
      selectedItemId: 'surveys',
      showUsers: canManageUsers,
      showSettings: canManageUsers,
      actions: [
        HuxButton(
          onPressed: surveyManager.loadProjects,
          variant: HuxButtonVariant.secondary,
          icon: LucideIcons.refreshCw,
          child: Text(context.tr('Refresh')),
        ),
        Tooltip(
          message: context.tr('Logout'),
          child: HuxButton(
            onPressed: authManager.logout,
            variant: HuxButtonVariant.ghost,
            size: HuxButtonSize.medium,
            icon: LucideIcons.logOut,
            child: const SizedBox(width: 0),
          ),
        ),
      ],
      child: SafeArea(
        child: _buildBody(
          context,
          surveyManager,
          canWrite,
          isSavingProject,
          setSavingProject,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SurveyListManager manager,
    bool canWrite,
    bool isSavingProject,
    void Function(bool) setSavingProject,
  ) {
    if (manager.state.isLoading && manager.state.projects.isEmpty) {
      return HuxLoadingState(message: context.tr('Loading...'));
    }

    if (manager.state.error != null && manager.state.projects.isEmpty) {
      return HuxPageBody(
        child: HuxErrorState(
          message: context.trMessage(manager.state.error!),
          onRetry: manager.loadProjects,
        ),
      );
    }

    if (manager.state.projects.isEmpty) {
      return HuxPageBody(
        maxWidth: 720,
        child: ProjectForm(
          isSaving: isSavingProject,
          error: manager.state.error,
          onSave: (project) async {
            setSavingProject(true);
            final created = await manager.createProject(project);
            setSavingProject(false);
            if (created != null && context.mounted) {
              context.go('/admin');
            }
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => manager.loadProjects(),
      child: ListView.builder(
        itemCount: manager.state.projects.length + 1,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
        itemBuilder: (context, index) {
          if (index == manager.state.projects.length) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: HuxButton(
                    onPressed: canWrite
                        ? () => context.go('/admin/projects/new')
                        : null,
                    variant: HuxButtonVariant.secondary,
                    width: HuxButtonWidth.expand,
                    icon: LucideIcons.plus,
                    child: Text(context.tr('Create Project')),
                  ),
                ),
              ),
            );
          }
          final item = manager.state.projects[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: _ProjectCard(
                item: item,
                canWrite: canWrite,
                manager: manager,
                onEditProject: () =>
                    context.go('/admin/projects/${item.project.id}'),
                onCreateSurvey: () => context.go(
                  '/admin/projects/${item.project.id}/surveys/new',
                ),
                onOpenSurvey: (survey) =>
                    context.go('/admin/surveys/${survey.id}'),
                onViewResponses: (survey) =>
                    context.go('/admin/surveys/${survey.id}/responses'),
                onDeleteSurvey: (survey) =>
                    _confirmDelete(context, item.project, survey, manager),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Project project,
    Survey survey,
    SurveyListManager manager,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: context.tr('Delete Survey'),
      content: context.tr('Delete survey confirmation', {
        'title': survey.titleFor(project.defaultLocale),
      }),
    );

    if (confirmed) {
      await manager.deleteSurvey(survey.id!);
    }
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectWithSurveys item;
  final bool canWrite;
  final SurveyListManager manager;
  final VoidCallback onEditProject;
  final VoidCallback onCreateSurvey;
  final void Function(Survey survey) onOpenSurvey;
  final void Function(Survey survey) onViewResponses;
  final void Function(Survey survey) onDeleteSurvey;

  const _ProjectCard({
    required this.item,
    required this.canWrite,
    required this.manager,
    required this.onEditProject,
    required this.onCreateSurvey,
    required this.onOpenSurvey,
    required this.onViewResponses,
    required this.onDeleteSurvey,
  });

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
                      project.nameFor(project.defaultLocale),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((project.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        project.description!,
                        style: TextStyle(
                          color: HuxTokens.textSecondary(context),
                        ),
                      ),
                    ],
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
              _MetadataItem(icon: LucideIcons.link, text: '/${project.slug}'),
              if (project.customDomain != null)
                _MetadataItem(
                  icon: LucideIcons.globe,
                  text: project.customDomain!,
                ),
              _MetadataItem(
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
                  _SurveyRow(
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

class _SurveyRow extends StatelessWidget {
  final Survey survey;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onViewResponses;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;
  final ValueChanged<bool>? onWebEnabledChanged;
  final VoidCallback? onDelete;

  const _SurveyRow({
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
                  _MetadataItem(
                    icon: LucideIcons.clock3,
                    text: survey.updatedAt.toIsoDateString(),
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
            _SurveyActions(
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

class _SurveyActions extends StatelessWidget {
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;
  final VoidCallback onViewResponses;
  final VoidCallback? onDelete;

  const _SurveyActions({
    this.onPublish,
    this.onClose,
    this.onReopen,
    required this.onViewResponses,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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

  const _MetadataItem({required this.icon, required this.text});

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
