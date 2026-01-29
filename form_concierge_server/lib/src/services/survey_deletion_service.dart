import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Service for handling survey deletion with all related data.
class SurveyDeletionService {
  /// Delete a survey and all its related data in a single transaction.
  ///
  /// Deletes in the correct order to respect foreign key constraints:
  /// 1. Answers (references responses and questions)
  /// 2. Responses (references survey)
  /// 3. Choices (references questions)
  /// 4. Questions (references survey)
  /// 5. Survey
  static Future<void> deleteSurvey(Session session, Survey survey) async {
    final surveyId = survey.id!;

    await session.db.transaction((transaction) async {
      final questions = await Question.db.find(
        session,
        where: (t) => t.surveyId.equals(surveyId),
      );

      await _deleteAnswersForSurvey(session, surveyId);
      await _deleteResponses(session, surveyId);
      await _deleteChoicesForQuestions(session, questions);
      await _deleteQuestions(session, surveyId);
      await Survey.db.deleteRow(session, survey);
    });
  }

  static Future<void> _deleteAnswersForSurvey(
    Session session,
    int surveyId,
  ) async {
    final responseIds = await SurveyResponse.db
        .find(session, where: (t) => t.surveyId.equals(surveyId))
        .then((responses) => responses.map((r) => r.id!).toSet());

    if (responseIds.isEmpty) return;

    await Answer.db.deleteWhere(
      session,
      where: (t) => t.surveyResponseId.inSet(responseIds),
    );
  }

  static Future<void> _deleteResponses(Session session, int surveyId) async {
    await SurveyResponse.db.deleteWhere(
      session,
      where: (t) => t.surveyId.equals(surveyId),
    );
  }

  static Future<void> _deleteChoicesForQuestions(
    Session session,
    List<Question> questions,
  ) async {
    final questionIds = questions.map((q) => q.id!).toSet();
    if (questionIds.isEmpty) return;

    await Choice.db.deleteWhere(
      session,
      where: (t) => t.questionId.inSet(questionIds),
    );
  }

  static Future<void> _deleteQuestions(Session session, int surveyId) async {
    await Question.db.deleteWhere(
      session,
      where: (t) => t.surveyId.equals(surveyId),
    );
  }
}
