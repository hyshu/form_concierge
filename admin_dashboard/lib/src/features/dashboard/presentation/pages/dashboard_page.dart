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
import '../widgets/dashboard_project_card.dart';
import '../widgets/project_form.dart';

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

    use.effect(
      () {
        if (authManager.state.hasCheckedAuth &&
            authManager.state.isAuthenticated) {
          surveyManager.loadProjects();
        }
        return null;
      },
      [
        authManager.state.hasCheckedAuth,
        authManager.state.isAuthenticated,
      ],
    );

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
              child: DashboardProjectCard(
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
