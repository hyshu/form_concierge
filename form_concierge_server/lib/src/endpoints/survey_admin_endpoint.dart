import 'package:serverpod/serverpod.dart';

import '../domain/survey_rules.dart';
import '../generated/protocol.dart';
import '../services/survey_deletion_service.dart';
import '../utils/exceptions.dart';
import '../utils/repository_extensions.dart';

/// Admin endpoint for managing surveys.
/// All methods require authentication.
class SurveyAdminEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Create a new survey.
  Future<Survey> create(Session session, Survey survey) async {
    final userId = session.authenticated?.userIdentifier;

    // Check for duplicate slug
    final existing = await Survey.db.findFirstRow(
      session,
      where: (t) => t.slug.equals(survey.slug),
    );
    if (existing != null) {
      throw const ValidationException('A survey with this slug already exists');
    }

    final newSurvey = survey.copyWith(
      createdByUserId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: SurveyStatus.draft,
    );

    return await Survey.db.insertRow(session, newSurvey);
  }

  /// Update an existing survey.
  Future<Survey> update(Session session, Survey survey) async {
    if (survey.id == null) {
      throw const ValidationException('Survey ID is required for update');
    }

    throwIfNotFound(
      await Survey.db.findById(session, survey.id!),
      'Survey',
      survey.id,
    );

    // Check for duplicate slug (excluding current survey)
    final duplicateSlug = await Survey.db.findFirstRow(
      session,
      where: (t) => t.slug.equals(survey.slug) & t.id.notEquals(survey.id),
    );
    if (duplicateSlug != null) {
      throw const ValidationException('A survey with this slug already exists');
    }

    final updatedSurvey = survey.copyWith(
      updatedAt: DateTime.now(),
    );

    return await Survey.db.updateRow(session, updatedSurvey);
  }

  /// Delete a survey and all related data.
  Future<bool> delete(Session session, int surveyId) async {
    final survey = throwIfNotFound(
      await Survey.db.findById(session, surveyId),
      'Survey',
      surveyId,
    );

    await SurveyDeletionService.deleteSurvey(session, survey);
    return true;
  }

  /// List all surveys for the current admin.
  Future<List<Survey>> list(Session session) async {
    final authInfo = session.authenticated;
    final userId = authInfo?.userIdentifier;

    return await Survey.db.find(
      session,
      where: (t) => t.createdByUserId.equals(userId),
      orderBy: (t) => t.updatedAt,
      orderDescending: true,
    );
  }

  /// Get a survey by ID.
  Future<Survey?> getById(Session session, int surveyId) async {
    return await Survey.db.findById(session, surveyId);
  }

  /// Publish a survey.
  Future<Survey> publish(Session session, int surveyId) async {
    final survey = throwIfNotFound(
      await Survey.db.findById(session, surveyId),
      'Survey',
      surveyId,
    );

    final questions = await Question.db.find(
      session,
      where: (t) => t.surveyId.equals(surveyId),
    );

    if (!SurveyRules.canPublish(
      status: survey.status,
      questionCount: questions.length,
    )) {
      if (survey.status != SurveyStatus.draft) {
        throw const InvalidStateTransitionException(
          'Only draft surveys can be published',
        );
      }
      throw const ValidationException(
        'Survey must have at least one question',
      );
    }

    // Check that all choice-type questions have at least one choice
    final choiceQuestions = questions.where(
      (q) =>
          q.type == QuestionType.singleChoice ||
          q.type == QuestionType.multipleChoice,
    );

    for (final question in choiceQuestions) {
      final choiceCount = await Choice.db.count(
        session,
        where: (t) => t.questionId.equals(question.id!),
      );
      if (choiceCount == 0) {
        throw ValidationException(
          'Question "${question.text}" must have at least one choice',
        );
      }
    }

    final updatedSurvey = survey.copyWith(
      status: SurveyStatus.published,
      updatedAt: DateTime.now(),
    );

    return await Survey.db.updateRow(session, updatedSurvey);
  }

  /// Close a survey (stop accepting responses).
  Future<Survey> close(Session session, int surveyId) async {
    return _updateStatus(
      session,
      surveyId,
      SurveyStatus.closed,
      transitionErrorMessage: 'Only published surveys can be closed',
    );
  }

  /// Reopen a closed survey.
  Future<Survey> reopen(Session session, int surveyId) async {
    return _updateStatus(
      session,
      surveyId,
      SurveyStatus.published,
      transitionErrorMessage: 'Only closed surveys can be reopened',
    );
  }

  Future<Survey> _updateStatus(
    Session session,
    int surveyId,
    SurveyStatus newStatus, {
    String? transitionErrorMessage,
  }) async {
    final survey = throwIfNotFound(
      await Survey.db.findById(session, surveyId),
      'Survey',
      surveyId,
    );

    if (transitionErrorMessage != null &&
        !SurveyRules.canTransition(survey.status, newStatus)) {
      throw InvalidStateTransitionException(transitionErrorMessage);
    }

    final updatedSurvey = survey.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    return await Survey.db.updateRow(session, updatedSurvey);
  }
}
