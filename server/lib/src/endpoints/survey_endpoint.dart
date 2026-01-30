import 'package:serverpod/serverpod.dart';

import '../domain/survey_rules.dart';
import '../generated/protocol.dart';
import '../utils/exceptions.dart';
import '../utils/repository_extensions.dart';

/// Public endpoint for accessing surveys and submitting responses.
/// No authentication required for anonymous surveys.
class SurveyEndpoint extends Endpoint {
  /// Get a published survey by its slug.
  /// Returns null if the survey doesn't exist or is not published.
  Future<Survey?> getBySlug(Session session, String slug) async {
    final survey = await Survey.db.findFirstRow(
      session,
      where: (t) =>
          t.slug.equals(slug) & t.status.equals(SurveyStatus.published),
    );

    if (survey == null) return null;

    final isAccepting = SurveyRules.isAcceptingResponses(
      status: survey.status,
      startsAt: survey.startsAt,
      endsAt: survey.endsAt,
    );

    return isAccepting ? survey : null;
  }

  /// Submit a response to a survey.
  /// For authenticated surveys, the user must be logged in.
  /// For anonymous surveys, an anonymousId can be provided for tracking.
  Future<SurveyResponse> submitResponse(
    Session session, {
    required int surveyId,
    required List<Answer> answers,
    String? anonymousId,
  }) async {
    final survey = throwIfNotFound(
      await Survey.db.findById(session, surveyId),
      'Survey',
      surveyId,
    );

    final isAuthenticated = session.authenticated != null;
    final validation = SurveyRules.validateResponseSubmission(
      status: survey.status,
      authRequirement: survey.authRequirement,
      isAuthenticated: isAuthenticated,
      startsAt: survey.startsAt,
      endsAt: survey.endsAt,
    );

    if (!validation.isValid) {
      throw ValidationException(
        validation.errorMessage ?? 'Invalid submission',
      );
    }

    String? userId;
    String? anonId = anonymousId;

    if (survey.authRequirement == AuthRequirement.authenticated) {
      userId = session.authenticated!.userIdentifier;
      anonId = null;
    } else {
      anonId ??= Uuid().v4();
    }

    // Create the response
    final response = SurveyResponse(
      surveyId: surveyId,
      userId: userId,
      anonymousId: anonId,
    );

    // Insert response and answers in a transaction
    return await session.db.transaction((transaction) async {
      final savedResponse = await SurveyResponse.db.insertRow(
        session,
        response,
      );

      for (final answer in answers) {
        final answerWithResponseId = answer.copyWith(
          surveyResponseId: savedResponse.id,
        );
        await Answer.db.insertRow(session, answerWithResponseId);
      }

      return savedResponse;
    });
  }

  /// Get all active questions for a published survey.
  /// Returns empty list if survey is not found or not published.
  Future<List<Question>> getQuestionsForSurvey(
    Session session,
    int surveyId,
  ) async {
    final survey = await Survey.db.findById(session, surveyId);
    if (survey == null || survey.status != SurveyStatus.published) {
      return [];
    }

    return await Question.db.find(
      session,
      where: (t) => t.surveyId.equals(surveyId) & t.isDeleted.equals(false),
      orderBy: (t) => t.orderIndex,
    );
  }

  /// Get all choices for a question.
  /// Only returns choices if the question belongs to a published survey
  /// and the question is not deleted.
  Future<List<Choice>> getChoicesForQuestion(
    Session session,
    int questionId,
  ) async {
    final question = await Question.db.findById(session, questionId);
    if (question == null || question.isDeleted) return [];

    final survey = await Survey.db.findById(session, question.surveyId);
    if (survey == null || survey.status != SurveyStatus.published) {
      return [];
    }

    return await Choice.db.find(
      session,
      where: (t) => t.questionId.equals(questionId),
      orderBy: (t) => t.orderIndex,
    );
  }
}
