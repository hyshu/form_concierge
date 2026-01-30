import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'gemini_service.dart';

/// Data transfer object for a survey's daily response summary.
class DailyResponseSummary {
  final Survey survey;
  final int responseCount;
  final List<ResponseDetail> responses;
  final String? aiSummary;

  DailyResponseSummary({
    required this.survey,
    required this.responseCount,
    required this.responses,
    this.aiSummary,
  });
}

/// Detail of a single response with its answers.
class ResponseDetail {
  final SurveyResponse response;
  final List<AnswerDetail> answers;

  ResponseDetail({required this.response, required this.answers});
}

/// Answer with question text for display.
class AnswerDetail {
  final String questionText;
  final QuestionType questionType;
  final String displayValue;

  AnswerDetail({
    required this.questionText,
    required this.questionType,
    required this.displayValue,
  });
}

/// Service for generating response summaries for notifications.
class ResponseSummaryService {
  /// Get responses from a specific time period for a survey.
  static Future<List<SurveyResponse>> getRecentResponses(
    Session session,
    int surveyId, {
    Duration period = const Duration(hours: 24),
  }) async {
    final cutoff = DateTime.now().toUtc().subtract(period);

    return await SurveyResponse.db.find(
      session,
      where: (t) => t.surveyId.equals(surveyId) & (t.submittedAt >= cutoff),
      orderBy: (t) => t.submittedAt,
      orderDescending: true,
    );
  }

  /// Build a complete summary for a survey's recent responses.
  static Future<DailyResponseSummary> buildSummary(
    Session session,
    Survey survey, {
    Duration period = const Duration(hours: 24),
  }) async {
    final responses = await getRecentResponses(
      session,
      survey.id!,
      period: period,
    );

    if (responses.isEmpty) {
      return DailyResponseSummary(
        survey: survey,
        responseCount: 0,
        responses: [],
      );
    }

    // Get questions for the survey (including soft-deleted for historical answers)
    final questions = await Question.db.find(
      session,
      where: (t) => t.surveyId.equals(survey.id!),
      orderBy: (t) => t.orderIndex,
    );
    final questionMap = {for (var q in questions) q.id!: q};

    // Get all choices for lookup
    final questionIds = questions.map((q) => q.id!).toSet();
    final choices = questionIds.isEmpty
        ? <Choice>[]
        : await Choice.db.find(
            session,
            where: (t) => t.questionId.inSet(questionIds),
          );
    final choiceMap = {for (var c in choices) c.id!: c};

    // Build response details
    final responseDetails = <ResponseDetail>[];
    for (final response in responses) {
      final answers = await Answer.db.find(
        session,
        where: (t) => t.surveyResponseId.equals(response.id!),
      );

      final answerDetails = <AnswerDetail>[];
      for (final answer in answers) {
        final question = questionMap[answer.questionId];
        if (question == null) continue;

        answerDetails.add(
          AnswerDetail(
            questionText: question.text,
            questionType: question.type,
            displayValue: _formatAnswerValue(answer, choiceMap),
          ),
        );
      }

      responseDetails.add(
        ResponseDetail(
          response: response,
          answers: answerDetails,
        ),
      );
    }

    // Generate AI summary if Gemini is configured
    String? aiSummary;
    if (GeminiService.isConfigured && responseDetails.isNotEmpty) {
      aiSummary = await _generateAiSummary(session, survey, responseDetails);
    }

    return DailyResponseSummary(
      survey: survey,
      responseCount: responses.length,
      responses: responseDetails,
      aiSummary: aiSummary,
    );
  }

  static String _formatAnswerValue(
    Answer answer,
    Map<int, Choice> choiceMap,
  ) {
    if (answer.textValue != null && answer.textValue!.isNotEmpty) {
      return answer.textValue!;
    }

    if (answer.selectedChoiceIds != null &&
        answer.selectedChoiceIds!.isNotEmpty) {
      return answer.selectedChoiceIds!
          .map((id) => choiceMap[id]?.text ?? 'Unknown')
          .join(', ');
    }

    return '(No answer)';
  }

  static Future<String?> _generateAiSummary(
    Session session,
    Survey survey,
    List<ResponseDetail> responses,
  ) async {
    // Build text representation for AI
    final buffer = StringBuffer();
    buffer.writeln('Survey: ${survey.title}');
    if (survey.description != null && survey.description!.isNotEmpty) {
      buffer.writeln('Description: ${survey.description}');
    }
    buffer.writeln('Responses in last 24 hours: ${responses.length}');
    buffer.writeln();

    // Include up to 50 responses to avoid token limits
    final maxResponses = responses.length > 50 ? 50 : responses.length;
    for (var i = 0; i < maxResponses; i++) {
      buffer.writeln('Response ${i + 1}:');
      for (final answer in responses[i].answers) {
        buffer.writeln('  ${answer.questionText}: ${answer.displayValue}');
      }
      buffer.writeln();
    }

    if (responses.length > 50) {
      buffer.writeln('... and ${responses.length - 50} more responses');
    }

    // Call Gemini for summary
    return await GeminiService.instance.generateResponseSummary(
      session: session,
      responseData: buffer.toString(),
    );
  }
}
