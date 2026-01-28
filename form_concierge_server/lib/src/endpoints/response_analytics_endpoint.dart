import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../utils/date_format.dart';
import '../utils/repository_extensions.dart';

/// Admin endpoint for viewing and analyzing survey responses.
/// All methods require authentication.
class ResponseAnalyticsEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Get all responses for a survey with pagination.
  Future<List<SurveyResponse>> getResponses(
    Session session,
    int surveyId, {
    int? limit,
    int? offset,
  }) async {
    return await SurveyResponse.db.find(
      session,
      where: (t) => t.surveyId.equals(surveyId),
      orderBy: (t) => t.submittedAt,
      orderDescending: true,
      limit: limit,
      offset: offset,
    );
  }

  /// Get response count for a survey.
  Future<int> getResponseCount(Session session, int surveyId) async {
    return await SurveyResponse.db.count(
      session,
      where: (t) => t.surveyId.equals(surveyId),
    );
  }

  /// Get all answers for a response.
  Future<List<Answer>> getAnswersForResponse(
    Session session,
    int responseId,
  ) async {
    return await Answer.db.find(
      session,
      where: (t) => t.surveyResponseId.equals(responseId),
    );
  }

  /// Get aggregated results for a survey.
  Future<SurveyResults> getAggregatedResults(
    Session session,
    int surveyId,
  ) async {
    final totalResponses = await SurveyResponse.db.count(
      session,
      where: (t) => t.surveyId.equals(surveyId),
    );

    final questions = await Question.db.find(
      session,
      where: (t) => t.surveyId.equals(surveyId),
      orderBy: (t) => t.orderIndex,
    );

    final questionResults = <QuestionResult>[];

    for (final question in questions) {
      final result = await _aggregateQuestionResults(session, question);
      questionResults.add(result);
    }

    return SurveyResults(
      surveyId: surveyId,
      totalResponses: totalResponses,
      questionResults: questionResults,
    );
  }

  Future<QuestionResult> _aggregateQuestionResults(
    Session session,
    Question question,
  ) async {
    final answers = await Answer.db.find(
      session,
      where: (t) => t.questionId.equals(question.id),
    );

    final isChoiceQuestion =
        question.type == QuestionType.singleChoice ||
        question.type == QuestionType.multipleChoice;

    return QuestionResult(
      questionId: question.id!,
      questionText: question.text,
      questionType: question.type,
      optionCounts: isChoiceQuestion
          ? await _countOptions(session, question, answers)
          : null,
      textResponses: isChoiceQuestion ? null : _collectTextResponses(answers),
    );
  }

  Future<Map<int, int>> _countOptions(
    Session session,
    Question question,
    List<Answer> answers,
  ) async {
    final options = await QuestionOption.db.find(
      session,
      where: (t) => t.questionId.equals(question.id),
    );

    final counts = {for (final option in options) option.id!: 0};

    for (final answer in answers) {
      for (final optionId in answer.selectedOptionIds ?? <int>[]) {
        counts[optionId] = (counts[optionId] ?? 0) + 1;
      }
    }

    return counts;
  }

  List<String> _collectTextResponses(List<Answer> answers) {
    return answers
        .where((a) => a.textValue != null && a.textValue!.isNotEmpty)
        .map((a) => a.textValue!)
        .toList();
  }

  /// Get response trends over time (daily counts for the last N days).
  Future<Map<String, int>> getResponseTrends(
    Session session,
    int surveyId, {
    int days = 30,
  }) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final responses = await SurveyResponse.db.find(
      session,
      where: (t) =>
          t.surveyId.equals(surveyId) &
          (t.submittedAt >= startDate) &
          (t.submittedAt <= now),
    );

    // Group by date
    final trends = <String, int>{};

    // Initialize all dates with 0
    for (var i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      trends[date.toIsoDateString()] = 0;
    }

    // Count responses per date
    for (final response in responses) {
      final dateKey = response.submittedAt.toIsoDateString();
      trends[dateKey] = (trends[dateKey] ?? 0) + 1;
    }

    return trends;
  }

  /// Delete a specific response.
  Future<bool> deleteResponse(Session session, int responseId) async {
    final response = throwIfNotFound(
      await SurveyResponse.db.findById(session, responseId),
      'Response',
      responseId,
    );

    await session.db.transaction((transaction) async {
      // Delete all answers for this response
      await Answer.db.deleteWhere(
        session,
        where: (t) => t.surveyResponseId.equals(responseId),
      );

      // Delete the response
      await SurveyResponse.db.deleteRow(session, response);
    });

    return true;
  }
}
