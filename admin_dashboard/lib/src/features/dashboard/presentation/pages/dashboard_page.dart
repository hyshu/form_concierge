import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/auth_state_capsule.dart';
import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Surveys')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: surveyManager.loadSurveys,
            tooltip: context.tr('Refresh'),
          ),
          if (canManageUsers)
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () => context.go('/admin/users'),
              tooltip: context.tr('User Management'),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authManager.logout(),
            tooltip: context.tr('Logout'),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context, surveyManager, canWrite),
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/admin/surveys/new'),
              icon: const Icon(Icons.add),
              label: Text(context.tr('New Survey')),
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    SurveyListManager manager,
    bool canWrite,
  ) {
    if (manager.state.isLoading && manager.state.surveys.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (manager.state.error != null && manager.state.surveys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(context.trMessage(manager.state.error!)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: manager.loadSurveys,
              child: Text(context.tr('Retry')),
            ),
          ],
        ),
      );
    }

    if (manager.state.surveys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('No surveys yet'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Create your first survey to get started'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/admin/surveys/new'),
              icon: const Icon(Icons.add),
              label: Text(context.tr('Create Survey')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => manager.loadSurveys(),
      child: ListView.builder(
        itemCount: manager.state.surveys.length,
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemBuilder: (context, index) {
          final survey = manager.state.surveys[index];
          return SurveyListTile(
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
