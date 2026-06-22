import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/download_file.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../capsules/aggregated_results_capsule.dart';
import '../capsules/notification_settings_capsule.dart';
import '../capsules/response_list_capsule.dart';
import '../widgets/aggregated_results_view.dart';
import '../widgets/notification_settings_view.dart';
import '../widgets/response_list.dart';

/// Page showing survey responses and aggregated results.
class ResponsesPage extends RearchConsumer {
  final int surveyId;

  const ResponsesPage({super.key, required this.surveyId});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final responseManager = use(responseListManagerCapsule);
    final resultsManager = use(aggregatedResultsManagerCapsule);
    final notificationManager = use(notificationSettingsManagerCapsule);
    final client = use(clientCapsule);
    final role = client.auth.signedInUser?.role;
    final canManageResponses =
        role == AdminRole.admin || role == AdminRole.editor;

    final responseState = responseManager.getState(surveyId);
    final resultsState = resultsManager.getState(surveyId);
    final notificationState = notificationManager.getState(surveyId);

    // Load data on first build
    if (use.isFirstBuild()) {
      responseManager.loadResponses(surveyId);
      resultsManager.loadResults(surveyId);
      notificationManager.loadSettings(surveyId);
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('Responses')),
          actions: [
            PopupMenuButton<ResponseExportFormat>(
              enabled: !responseState.isExporting,
              icon: responseState.isExporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              tooltip: context.tr('Export responses'),
              onSelected: (format) =>
                  _exportResponses(context, responseManager, format),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ResponseExportFormat.csv,
                  child: ListTile(
                    leading: const Icon(Icons.table_chart_outlined),
                    title: Text(context.tr('Export CSV')),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: ResponseExportFormat.json,
                  child: ListTile(
                    leading: const Icon(Icons.data_object_outlined),
                    title: Text(context.tr('Export JSON')),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.analytics_outlined),
                text: context.tr('Results'),
              ),
              Tab(
                icon: const Icon(Icons.list_alt),
                text: context.tr('Individual'),
              ),
              Tab(
                icon: const Icon(Icons.notifications_outlined),
                text: context.tr('Notifications'),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // Aggregated Results Tab
              AggregatedResultsView(
                results: resultsState.results,
                choicesByQuestion: resultsState.choicesByQuestion,
                isLoading: resultsState.isLoading,
                error: resultsState.error,
                onRefresh: () => resultsManager.loadResults(surveyId),
              ),
              // Individual Responses Tab
              ResponseList(
                responses: responseState.responses,
                totalCount: responseState.totalCount,
                currentPage: responseState.currentPage,
                totalPages: responseState.totalPages,
                isLoading: responseState.isLoading,
                canManageResponses: canManageResponses,
                error: responseState.error,
                onPageChange: (page) =>
                    responseManager.loadResponses(surveyId, page: page),
                onDelete: (response) =>
                    _confirmDelete(context, response, responseManager),
                onReply: (response) =>
                    _showReplyDialog(context, response, responseManager),
              ),
              // Notification Settings Tab
              NotificationSettingsView(
                surveyId: surveyId,
                settings: notificationState.settings,
                isLoading: notificationState.isLoading,
                isSaving: notificationState.isSaving,
                isSendingTest: notificationState.isSendingTest,
                error: notificationState.error,
                successMessage: notificationState.successMessage,
                isEmailConfigured: notificationState.isEmailConfigured,
                onRefresh: () => notificationManager.loadSettings(surveyId),
                onSave: (settings) =>
                    notificationManager.saveSettings(surveyId, settings),
                onToggleEnabled: () =>
                    notificationManager.toggleEnabled(surveyId),
                onSendTest: () =>
                    notificationManager.sendTestNotification(surveyId),
                onClearMessages: () =>
                    notificationManager.clearMessages(surveyId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SurveyResponse response,
    ResponseListManager manager,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: context.tr('Delete Response'),
      content: context.tr('Delete response confirmation'),
    );

    if (confirmed) {
      await manager.deleteResponse(surveyId, response.id!);
    }
  }

  Future<void> _showReplyDialog(
    BuildContext context,
    SurveyResponse response,
    ResponseListManager manager,
  ) async {
    final controller = TextEditingController();
    final body = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Reply to respondent')),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.tr('Message'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(context.tr('Send')),
          ),
        ],
      ),
    );
    controller.dispose();

    final trimmed = body?.trim();
    if (trimmed == null || trimmed.isEmpty || response.id == null) return;
    final sent = await manager.sendReply(surveyId, response.id!, trimmed);
    if (sent && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Reply sent'))),
      );
    }
  }

  Future<void> _exportResponses(
    BuildContext context,
    ResponseListManager manager,
    ResponseExportFormat format,
  ) async {
    final file = await manager.exportResponses(surveyId, format);
    if (file == null || !context.mounted) return;
    try {
      await downloadFile(
        bytes: file.bytes,
        filename: file.filename,
        contentType: file.contentType,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('Exported {filename}', {'filename': file.filename}),
            ),
          ),
        );
      }
    } on UnsupportedError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.trMessage(error.message ?? error.toString())),
          ),
        );
      }
    }
  }
}
