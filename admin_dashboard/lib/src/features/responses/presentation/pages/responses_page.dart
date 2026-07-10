import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';
import 'package:hux/hux.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/download_file.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/hux_admin_shell.dart';
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
  Widget build(context, use) {
    final responseManager = use(responseListManagerCapsule);
    final resultsManager = use(aggregatedResultsManagerCapsule);
    final notificationManager = use(notificationSettingsManagerCapsule);
    final client = use(clientCapsule);
    final role = client.auth.signedInUser?.role;
    final canManageResponses =
        role == AdminRole.admin || role == AdminRole.editor;
    final canManageUsers = role == AdminRole.admin;

    final responseState = responseManager.getState(surveyId);
    final resultsState = resultsManager.getState(surveyId);
    final notificationState = notificationManager.getState(surveyId);

    // Load data on first build
    if (use.isFirstBuild()) {
      responseManager.loadResponses(surveyId);
      resultsManager.loadResults(surveyId);
      notificationManager.loadSettings(surveyId);
    }

    return HuxAdminShell(
      title: context.tr('Responses'),
      selectedItemId: 'surveys',
      showUsers: canManageUsers,
      showSettings: canManageUsers,
      onBack: () => context.go('/admin'),
      actions: [
        if (responseState.isExporting)
          HuxButton(
            onPressed: null,
            isLoading: true,
            child: Text(context.tr('Export responses')),
          )
        else
          SizedBox(
            width: 180,
            child: HuxDropdown<ResponseExportFormat>(
              placeholder: context.tr('Export responses'),
              useItemWidgetAsValue: true,
              items: [
                HuxDropdownItem(
                  value: ResponseExportFormat.csv,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.table, size: 18),
                      const SizedBox(width: 8),
                      Text(context.tr('Export CSV')),
                    ],
                  ),
                ),
                HuxDropdownItem(
                  value: ResponseExportFormat.json,
                  child: Row(
                    children: [
                      const Icon(LucideIcons.braces, size: 18),
                      const SizedBox(width: 8),
                      Text(context.tr('Export JSON')),
                    ],
                  ),
                ),
              ],
              onChanged: (format) =>
                  _exportResponses(context, responseManager, format),
            ),
          ),
      ],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: HuxTabs(
            expandContent: true,
            variant: HuxTabVariant.pill,
            tabs: [
              HuxTabItem(
                icon: LucideIcons.chartNoAxesColumn,
                label: context.tr('Results'),
                content: AggregatedResultsView(
                  client: client,
                  results: resultsState.results,
                  choicesByQuestion: resultsState.choicesByQuestion,
                  isLoading: resultsState.isLoading,
                  error: resultsState.error,
                  onRefresh: () => resultsManager.loadResults(surveyId),
                ),
              ),
              HuxTabItem(
                icon: LucideIcons.list,
                label: context.tr('Individual'),
                content: ResponseList(
                  client: client,
                  responses: responseState.responses,
                  totalCount: responseState.totalCount,
                  currentPage: responseState.currentPage,
                  totalPages: responseState.totalPages,
                  isLoading: responseState.isLoading,
                  canManageResponses: canManageResponses,
                  error: responseState.error,
                  questions: responseState.questions,
                  choicesByQuestion: responseState.choicesByQuestion,
                  answersByResponseId: responseState.answersByResponseId,
                  loadingAnswerIds: responseState.loadingAnswerIds,
                  answerErrorsByResponseId:
                      responseState.answerErrorsByResponseId,
                  onPageChange: (page) =>
                      responseManager.loadResponses(surveyId, page: page),
                  onDelete: (response) =>
                      _confirmDelete(context, response, responseManager),
                  onReply: (response) =>
                      _showReplyDialog(context, response, responseManager),
                  onExpandAnswers: (responseId) => responseManager
                      .loadAnswersForResponse(surveyId, responseId),
                ),
              ),
              HuxTabItem(
                icon: LucideIcons.bell,
                label: context.tr('Notifications'),
                content: NotificationSettingsView(
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
      builder: (context) => HuxDialog(
        title: context.tr('Reply to respondent'),
        size: HuxDialogSize.medium,
        content: SizedBox(
          width: 420,
          child: HuxTextarea(
            controller: controller,
            label: context.tr('Message'),
            minLines: 4,
            maxLines: 8,
          ),
        ),
        actions: [
          HuxButton(
            onPressed: () => Navigator.of(context).pop(),
            variant: HuxButtonVariant.secondary,
            child: Text(context.tr('Cancel')),
          ),
          HuxButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            icon: LucideIcons.send,
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
      context.showHuxSnackbar(
        message: context.tr('Reply sent'),
        variant: HuxSnackbarVariant.success,
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
        context.showHuxSnackbar(
          message: context.tr('Exported {filename}', {
            'filename': file.filename,
          }),
          variant: HuxSnackbarVariant.success,
        );
      }
    } on UnsupportedError catch (error) {
      if (context.mounted) {
        context.showHuxSnackbar(
          message: context.trMessage(error.message ?? error.toString()),
          variant: HuxSnackbarVariant.error,
        );
      }
    }
  }
}
