import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../utils/exceptions.dart';
import '../utils/repository_extensions.dart';

/// Admin endpoint for managing questions.
/// All methods require authentication.
class QuestionAdminEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Add a question to a survey.
  ///
  /// For choice-type questions (singleChoice, multipleChoice), two default
  /// choices are automatically added: "Choice 1" and "Choice 2".
  Future<Question> create(Session session, Question question) async {
    // Verify survey exists
    throwIfNotFound(
      await Survey.db.findById(session, question.surveyId),
      'Survey',
      question.surveyId,
    );

    // Get the next order index
    final maxOrder = await Question.db.findFirstRow(
      session,
      where: (t) => t.surveyId.equals(question.surveyId),
      orderBy: (t) => t.orderIndex,
      orderDescending: true,
    );
    final nextOrderIndex = (maxOrder?.orderIndex ?? -1) + 1;

    final newQuestion = question.copyWith(
      orderIndex: nextOrderIndex,
    );

    final createdQuestion = await Question.db.insertRow(session, newQuestion);

    // For choice-type questions, add two default choices
    if (createdQuestion.type == QuestionType.singleChoice ||
        createdQuestion.type == QuestionType.multipleChoice) {
      await Choice.db.insert(session, [
        Choice(
          questionId: createdQuestion.id!,
          text: 'Choice 1',
          orderIndex: 0,
        ),
        Choice(
          questionId: createdQuestion.id!,
          text: 'Choice 2',
          orderIndex: 1,
        ),
      ]);
    }

    return createdQuestion;
  }

  /// Update a question.
  Future<Question> update(Session session, Question question) async {
    if (question.id == null) {
      throw const ValidationException('Question ID is required for update');
    }

    throwIfNotFound(
      await Question.db.findById(session, question.id!),
      'Question',
      question.id,
    );

    return await Question.db.updateRow(session, question);
  }

  /// Delete a question and its options.
  Future<bool> delete(Session session, int questionId) async {
    final question = throwIfNotFound(
      await Question.db.findById(session, questionId),
      'Question',
      questionId,
    );

    await session.db.transaction((transaction) async {
      // Delete answers referencing this question
      await Answer.db.deleteWhere(
        session,
        where: (t) => t.questionId.equals(questionId),
      );

      // Delete all choices for this question
      await Choice.db.deleteWhere(
        session,
        where: (t) => t.questionId.equals(questionId),
      );

      // Delete the question
      await Question.db.deleteRow(session, question);

      // Re-order remaining questions
      final remainingQuestions = await Question.db.find(
        session,
        where: (t) => t.surveyId.equals(question.surveyId),
        orderBy: (t) => t.orderIndex,
      );

      for (var i = 0; i < remainingQuestions.length; i++) {
        if (remainingQuestions[i].orderIndex != i) {
          await Question.db.updateRow(
            session,
            remainingQuestions[i].copyWith(orderIndex: i),
          );
        }
      }
    });

    return true;
  }

  /// Reorder questions within a survey.
  /// Pass the question IDs in the desired order.
  Future<List<Question>> reorder(
    Session session,
    int surveyId,
    List<int> questionIds,
  ) async {
    // Verify all questions belong to the survey
    final questions = await Question.db.find(
      session,
      where: (t) => t.surveyId.equals(surveyId),
    );

    final questionIdSet = questions.map((q) => q.id).toSet();
    for (final id in questionIds) {
      if (!questionIdSet.contains(id)) {
        throw ValidationException(
          'Question $id does not belong to this survey',
        );
      }
    }

    // Update order indices
    final updatedQuestions = <Question>[];
    for (var i = 0; i < questionIds.length; i++) {
      final question = questions.firstWhere((q) => q.id == questionIds[i]);
      if (question.orderIndex != i) {
        final updated = await Question.db.updateRow(
          session,
          question.copyWith(orderIndex: i),
        );
        updatedQuestions.add(updated);
      } else {
        updatedQuestions.add(question);
      }
    }

    return updatedQuestions;
  }

  /// Get all questions for a survey.
  Future<List<Question>> getForSurvey(Session session, int surveyId) async {
    return await Question.db.find(
      session,
      where: (t) => t.surveyId.equals(surveyId),
      orderBy: (t) => t.orderIndex,
    );
  }

  /// Get a question by ID.
  Future<Question?> getById(Session session, int questionId) async {
    return await Question.db.findById(session, questionId);
  }

  /// Get all choices for a question.
  Future<List<Choice>> getChoicesForQuestion(
    Session session,
    int questionId,
  ) async {
    return await Choice.db.find(
      session,
      where: (t) => t.questionId.equals(questionId),
      orderBy: (t) => t.orderIndex,
    );
  }
}
