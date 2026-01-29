import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../utils/exceptions.dart';
import '../utils/repository_extensions.dart';

/// Admin endpoint for managing question choices.
/// All methods require authentication.
class ChoiceAdminEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Add a choice to a question.
  Future<Choice> create(Session session, Choice choice) async {
    // Verify question exists
    final question = throwIfNotFound(
      await Question.db.findById(session, choice.questionId),
      'Question',
      choice.questionId,
    );

    // Only choice-type questions can have choices
    if (question.type != QuestionType.singleChoice &&
        question.type != QuestionType.multipleChoice) {
      throw const ValidationException(
        'Only choice-type questions can have choices',
      );
    }

    // Get the next order index
    final maxOrder = await Choice.db.findFirstRow(
      session,
      where: (t) => t.questionId.equals(choice.questionId),
      orderBy: (t) => t.orderIndex,
      orderDescending: true,
    );
    final nextOrderIndex = (maxOrder?.orderIndex ?? -1) + 1;

    final newChoice = choice.copyWith(
      orderIndex: nextOrderIndex,
    );

    return await Choice.db.insertRow(session, newChoice);
  }

  /// Update a choice.
  Future<Choice> update(Session session, Choice choice) async {
    if (choice.id == null) {
      throw const ValidationException('Choice ID is required for update');
    }

    throwIfNotFound(
      await Choice.db.findById(session, choice.id!),
      'Choice',
      choice.id,
    );

    return await Choice.db.updateRow(session, choice);
  }

  /// Delete a choice.
  Future<bool> delete(Session session, int choiceId) async {
    final choice = throwIfNotFound(
      await Choice.db.findById(session, choiceId),
      'Choice',
      choiceId,
    );

    await session.db.transaction((transaction) async {
      // Remove this choice from any answers that selected it
      final answers = await Answer.db.find(
        session,
        where: (t) => t.questionId.equals(choice.questionId),
      );

      for (final answer in answers) {
        if (answer.selectedChoiceIds != null &&
            answer.selectedChoiceIds!.contains(choiceId)) {
          final updatedIds = answer.selectedChoiceIds!
              .where((id) => id != choiceId)
              .toList();
          await Answer.db.updateRow(
            session,
            answer.copyWith(selectedChoiceIds: updatedIds),
          );
        }
      }

      // Delete the choice
      await Choice.db.deleteRow(session, choice);

      // Re-order remaining choices
      final remainingChoices = await Choice.db.find(
        session,
        where: (t) => t.questionId.equals(choice.questionId),
        orderBy: (t) => t.orderIndex,
      );

      for (var i = 0; i < remainingChoices.length; i++) {
        if (remainingChoices[i].orderIndex != i) {
          await Choice.db.updateRow(
            session,
            remainingChoices[i].copyWith(orderIndex: i),
          );
        }
      }
    });

    return true;
  }

  /// Reorder choices within a question.
  /// Pass the choice IDs in the desired order.
  Future<List<Choice>> reorder(
    Session session,
    int questionId,
    List<int> choiceIds,
  ) async {
    // Verify all choices belong to the question
    final choices = await Choice.db.find(
      session,
      where: (t) => t.questionId.equals(questionId),
    );

    final choiceIdSet = choices.map((c) => c.id).toSet();
    for (final id in choiceIds) {
      if (!choiceIdSet.contains(id)) {
        throw ValidationException(
          'Choice $id does not belong to this question',
        );
      }
    }

    // Update order indices
    final updatedChoices = <Choice>[];
    for (var i = 0; i < choiceIds.length; i++) {
      final choice = choices.firstWhere((c) => c.id == choiceIds[i]);
      if (choice.orderIndex != i) {
        final updated = await Choice.db.updateRow(
          session,
          choice.copyWith(orderIndex: i),
        );
        updatedChoices.add(updated);
      } else {
        updatedChoices.add(choice);
      }
    }

    return updatedChoices;
  }

  /// Get a choice by ID.
  Future<Choice?> getById(Session session, int choiceId) async {
    return await Choice.db.findById(session, choiceId);
  }
}
