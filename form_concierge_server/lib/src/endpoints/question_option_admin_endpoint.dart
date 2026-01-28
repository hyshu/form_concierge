import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../utils/exceptions.dart';
import '../utils/repository_extensions.dart';

/// Admin endpoint for managing question options.
/// All methods require authentication.
class QuestionOptionAdminEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Add an option to a question.
  Future<QuestionOption> create(Session session, QuestionOption option) async {
    // Verify question exists
    final question = throwIfNotFound(
      await Question.db.findById(session, option.questionId),
      'Question',
      option.questionId,
    );

    // Only choice-type questions can have options
    if (question.type != QuestionType.singleChoice &&
        question.type != QuestionType.multipleChoice) {
      throw const ValidationException(
        'Only choice-type questions can have options',
      );
    }

    // Get the next order index
    final maxOrder = await QuestionOption.db.findFirstRow(
      session,
      where: (t) => t.questionId.equals(option.questionId),
      orderBy: (t) => t.orderIndex,
      orderDescending: true,
    );
    final nextOrderIndex = (maxOrder?.orderIndex ?? -1) + 1;

    final newOption = option.copyWith(
      orderIndex: nextOrderIndex,
    );

    return await QuestionOption.db.insertRow(session, newOption);
  }

  /// Update an option.
  Future<QuestionOption> update(Session session, QuestionOption option) async {
    if (option.id == null) {
      throw const ValidationException('Option ID is required for update');
    }

    throwIfNotFound(
      await QuestionOption.db.findById(session, option.id!),
      'Option',
      option.id,
    );

    return await QuestionOption.db.updateRow(session, option);
  }

  /// Delete an option.
  Future<bool> delete(Session session, int optionId) async {
    final option = throwIfNotFound(
      await QuestionOption.db.findById(session, optionId),
      'Option',
      optionId,
    );

    await session.db.transaction((transaction) async {
      // Remove this option from any answers that selected it
      final answers = await Answer.db.find(
        session,
        where: (t) => t.questionId.equals(option.questionId),
      );

      for (final answer in answers) {
        if (answer.selectedOptionIds != null &&
            answer.selectedOptionIds!.contains(optionId)) {
          final updatedIds = answer.selectedOptionIds!
              .where((id) => id != optionId)
              .toList();
          await Answer.db.updateRow(
            session,
            answer.copyWith(selectedOptionIds: updatedIds),
          );
        }
      }

      // Delete the option
      await QuestionOption.db.deleteRow(session, option);

      // Re-order remaining options
      final remainingOptions = await QuestionOption.db.find(
        session,
        where: (t) => t.questionId.equals(option.questionId),
        orderBy: (t) => t.orderIndex,
      );

      for (var i = 0; i < remainingOptions.length; i++) {
        if (remainingOptions[i].orderIndex != i) {
          await QuestionOption.db.updateRow(
            session,
            remainingOptions[i].copyWith(orderIndex: i),
          );
        }
      }
    });

    return true;
  }

  /// Reorder options within a question.
  /// Pass the option IDs in the desired order.
  Future<List<QuestionOption>> reorder(
    Session session,
    int questionId,
    List<int> optionIds,
  ) async {
    // Verify all options belong to the question
    final options = await QuestionOption.db.find(
      session,
      where: (t) => t.questionId.equals(questionId),
    );

    final optionIdSet = options.map((o) => o.id).toSet();
    for (final id in optionIds) {
      if (!optionIdSet.contains(id)) {
        throw ValidationException(
          'Option $id does not belong to this question',
        );
      }
    }

    // Update order indices
    final updatedOptions = <QuestionOption>[];
    for (var i = 0; i < optionIds.length; i++) {
      final option = options.firstWhere((o) => o.id == optionIds[i]);
      if (option.orderIndex != i) {
        final updated = await QuestionOption.db.updateRow(
          session,
          option.copyWith(orderIndex: i),
        );
        updatedOptions.add(updated);
      } else {
        updatedOptions.add(option);
      }
    }

    return updatedOptions;
  }

  /// Get an option by ID.
  Future<QuestionOption?> getById(Session session, int optionId) async {
    return await QuestionOption.db.findById(session, optionId);
  }
}
