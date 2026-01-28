import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/auth_state_capsule.dart';
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

    // Load surveys on first build
    if (use.isFirstBuild()) {
      surveyManager.loadSurveys();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveys'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: surveyManager.loadSurveys,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => context.go('/admin/users'),
            tooltip: 'User Management',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authManager.logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context, surveyManager),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/surveys/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Survey'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SurveyListManager manager) {
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
            Text(manager.state.error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: manager.loadSurveys,
              child: const Text('Retry'),
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
              'No surveys yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first survey to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/admin/surveys/new'),
              icon: const Icon(Icons.add),
              label: const Text('Create Survey'),
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
            onPublish: survey.status == SurveyStatus.draft
                ? () => manager.publishSurvey(survey.id!)
                : null,
            onClose: survey.status == SurveyStatus.published
                ? () => manager.closeSurvey(survey.id!)
                : null,
            onReopen: survey.status == SurveyStatus.closed
                ? () => manager.reopenSurvey(survey.id!)
                : null,
            onDelete: () => _confirmDelete(context, survey, manager),
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
      title: 'Delete Survey',
      content:
          'Are you sure you want to delete "${survey.title}"?\n\n'
          'This will also delete all questions and responses. This action cannot be undone.',
    );

    if (confirmed) {
      await manager.deleteSurvey(survey.id!);
    }
  }
}
