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
import '../widgets/survey_list_tile.dart';

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

    // Load surveys on first build
    if (use.isFirstBuild()) {
      surveyManager.loadSurveys();
    }

    return HuxAdminShell(
      title: context.tr('Surveys'),
      selectedItemId: 'surveys',
      showUsers: canManageUsers,
      showSettings: canManageUsers,
      actions: [
        HuxButton(
          onPressed: surveyManager.loadSurveys,
          variant: HuxButtonVariant.secondary,
          icon: LucideIcons.refreshCw,
          child: Text(context.tr('Refresh')),
        ),
        if (canWrite)
          HuxButton(
            onPressed: () => context.go('/admin/surveys/new'),
            icon: LucideIcons.plus,
            child: Text(context.tr('New Survey')),
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
        child: _buildBody(context, surveyManager, canWrite),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SurveyListManager manager,
    bool canWrite,
  ) {
    if (manager.state.isLoading && manager.state.surveys.isEmpty) {
      return const Center(child: HuxLoading(size: HuxLoadingSize.large));
    }

    if (manager.state.error != null && manager.state.surveys.isEmpty) {
      return HuxPageBody(
        child: HuxErrorState(
          message: context.trMessage(manager.state.error!),
          onRetry: manager.loadSurveys,
        ),
      );
    }

    if (manager.state.surveys.isEmpty) {
      return HuxPageBody(
        child: HuxEmptyState(
          icon: LucideIcons.clipboardList,
          title: context.tr('No surveys yet'),
          message: context.tr('Create your first survey to get started'),
          action: canWrite
              ? HuxButton(
                  onPressed: () => context.go('/admin/surveys/new'),
                  icon: LucideIcons.plus,
                  child: Text(context.tr('Create Survey')),
                )
              : null,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => manager.loadSurveys(),
      child: ListView.builder(
        itemCount: manager.state.surveys.length,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
        itemBuilder: (context, index) {
          final survey = manager.state.surveys[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: SurveyListTile(
                survey: survey,
                onTap: () => context.go('/admin/surveys/${survey.id}'),
                onViewResponses: () =>
                    context.go('/admin/surveys/${survey.id}/responses'),
                onPublish: canWrite && survey.status == SurveyStatus.draft
                    ? () => manager.publishSurvey(survey.id!)
                    : null,
                onClose: canWrite && survey.status == SurveyStatus.published
                    ? () => manager.closeSurvey(survey.id!)
                    : null,
                onReopen: canWrite && survey.status == SurveyStatus.closed
                    ? () => manager.reopenSurvey(survey.id!)
                    : null,
                onDelete: canWrite
                    ? () => _confirmDelete(context, survey, manager)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Survey survey,
    SurveyListManager manager,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: context.tr('Delete Survey'),
      content: context.tr('Delete survey confirmation', {
        'title': survey.title,
      }),
    );

    if (confirmed) {
      await manager.deleteSurvey(survey.id!);
    }
  }
}
