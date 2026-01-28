import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../capsules/aggregated_results_capsule.dart';
import '../capsules/response_list_capsule.dart';
import '../widgets/aggregated_results_view.dart';
import '../widgets/response_list.dart';

/// Page showing survey responses and aggregated results.
class ResponsesPage extends RearchConsumer {
  final int surveyId;

  const ResponsesPage({super.key, required this.surveyId});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final responseManager = use(responseListManagerCapsule);
    final resultsManager = use(aggregatedResultsManagerCapsule);

    final responseState = responseManager.getState(surveyId);
    final resultsState = resultsManager.getState(surveyId);

    // Load data on first build
    if (use.isFirstBuild()) {
      responseManager.loadResponses(surveyId);
      resultsManager.loadResults(surveyId);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Responses'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.analytics_outlined),
                text: 'Results',
              ),
              Tab(
                icon: Icon(Icons.list_alt),
                text: 'Individual',
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
                optionsByQuestion: resultsState.optionsByQuestion,
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
                error: responseState.error,
                onPageChange: (page) =>
                    responseManager.loadResponses(surveyId, page: page),
                onDelete: (response) =>
                    _confirmDelete(context, response, responseManager),
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
      title: 'Delete Response',
      content:
          'Are you sure you want to delete this response?\n\n'
          'This action cannot be undone.',
    );

    if (confirmed) {
      await manager.deleteResponse(surveyId, response.id!);
    }
  }
}
