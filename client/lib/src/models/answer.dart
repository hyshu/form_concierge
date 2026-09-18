part of form_concierge_client;

/// A question's text, choice identifier, choice list, or uploaded file keys.
typedef AnswerValue = Object?;

/// Answers indexed by question identifier.
typedef AnswerValues = Map<int, AnswerValue>;

/// Validation messages indexed by question identifier.
typedef ValidationErrors = Map<int, String>;

/// A submitted answer to one survey question.
class Answer {
  /// The identifier of this answer. Null until the record has been saved.
  final int? id;

  /// The identifier of the associated survey response.
  final int surveyResponseId;

  /// The identifier of the associated question.
  final int questionId;

  /// The submitted text for a text question, when present.
  final String? textValue;

  /// The identifiers of the selected answer choices.
  final List<int>? selectedChoiceIds;

  /// Storage keys for the uploaded files attached to the answer.
  final List<String>? fileKeys;

  /// Creates Answer with the supplied values.
  const Answer({
    this.id,
    required this.surveyResponseId,
    required this.questionId,
    this.textValue,
    this.selectedChoiceIds,
    this.fileKeys,
  });

  /// Decodes Answer from its JSON representation.
  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
    id: json['id'] == null ? null : _int(json['id']),
    surveyResponseId: _int(json['surveyResponseId']),
    questionId: _int(json['questionId']),
    textValue: _optionalString(json['textValue']),
    selectedChoiceIds: _intList(json['selectedChoiceIds']),
    fileKeys: json['fileKeys'] == null ? null : _stringList(json['fileKeys']),
  );

  /// Returns the JSON representation used by the API.
  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'surveyResponseId': surveyResponseId,
    'questionId': questionId,
    'textValue': textValue,
    'selectedChoiceIds': selectedChoiceIds,
    'fileKeys': fileKeys,
  });

  /// Returns a copy with the supplied non-null values replacing the current values.
  Answer copyWith({
    int? id,
    int? surveyResponseId,
    int? questionId,
    String? textValue,
    List<int>? selectedChoiceIds,
    List<String>? fileKeys,
  }) => Answer(
    id: id ?? this.id,
    surveyResponseId: surveyResponseId ?? this.surveyResponseId,
    questionId: questionId ?? this.questionId,
    textValue: textValue ?? this.textValue,
    selectedChoiceIds: selectedChoiceIds ?? this.selectedChoiceIds,
    fileKeys: fileKeys ?? this.fileKeys,
  );
}

/// Answers and validation errors after applying an edit.
class AnswerChange {
  /// The current answers indexed by question identifier.
  final AnswerValues answers;

  /// Validation messages indexed by question identifier.
  final ValidationErrors validationErrors;

  /// Creates AnswerChange with the supplied values.
  const AnswerChange({
    required this.answers,
    required this.validationErrors,
  });
}

/// Converts valid nonempty input values into submission answers. Questions without
/// identifiers and values of the wrong type are skipped.
List<Answer> buildAnswers(
  AnswerValues answerValues,
  Iterable<Question> questions, {
  int surveyResponseId = 0,
}) {
  final result = <Answer>[];

  for (final question in questions) {
    final questionId = question.id;
    if (questionId == null) continue;

    final value = answerValues[questionId];
    if (value == null) continue;

    switch (question.type) {
      case QuestionType.singleChoice:
        if (value is int) {
          result.add(
            Answer(
              surveyResponseId: surveyResponseId,
              questionId: questionId,
              selectedChoiceIds: [value],
            ),
          );
        }
      case QuestionType.multipleChoice:
        if (value is List<int> && value.isNotEmpty) {
          result.add(
            Answer(
              surveyResponseId: surveyResponseId,
              questionId: questionId,
              selectedChoiceIds: value,
            ),
          );
        }
      case QuestionType.textSingle:
      case QuestionType.textMultiLine:
        if (value is String && value.trim().isNotEmpty) {
          result.add(
            Answer(
              surveyResponseId: surveyResponseId,
              questionId: questionId,
              textValue: value.trim(),
            ),
          );
        }
      case QuestionType.imageUpload:
        if (value is List<String> && value.isNotEmpty) {
          result.add(
            Answer(
              surveyResponseId: surveyResponseId,
              questionId: questionId,
              fileKeys: List<String>.from(value),
            ),
          );
        }
    }
  }

  return result;
}

/// Returns visible questions in input order by evaluating rules against answers to
/// earlier visible questions.
List<Question> resolveVisibleQuestions(
  List<Question> questions,
  List<QuestionVisibilityRule> visibilityRules,
  AnswerValues answerValues,
) {
  final visible = <int>{};
  final rulesByTarget = <int, List<QuestionVisibilityRule>>{};
  final questionsById = {
    for (final question in questions)
      if (question.id != null) question.id!: question,
  };

  for (final rule in visibilityRules) {
    rulesByTarget.putIfAbsent(rule.targetQuestionId, () => []).add(rule);
  }

  final result = <Question>[];
  for (final question in questions) {
    final questionId = question.id;
    if (questionId == null) continue;
    final rules = rulesByTarget[questionId] ?? const [];
    final isVisible =
        rules.isEmpty ||
        _matchesVisibilityRules(
          question,
          rules,
          questionsById,
          visible,
          answerValues,
        );
    if (isVisible) {
      visible.add(questionId);
      result.add(question);
    }
  }

  return result;
}

/// Returns only answers whose question identifiers are in the visible question list.
AnswerValues pruneHiddenAnswers(
  AnswerValues answerValues,
  List<Question> visibleQuestions,
) {
  final visibleIds = visibleQuestions
      .map((question) => question.id)
      .whereType<int>()
      .toSet();
  return Map.fromEntries(
    answerValues.entries.where((entry) => visibleIds.contains(entry.key)),
  );
}

/// Returns localized errors for missing required answers and violated input limits.
ValidationErrors validateSurveyAnswers(
  AnswerValues answerValues,
  List<Question> questions,
  String locale,
) {
  final errors = <int, String>{};

  for (final question in questions) {
    final questionId = question.id;
    if (questionId == null) continue;
    final answer = answerValues[questionId];

    if (question.isRequired) {
      if (answer == null ||
          (answer is String && answer.trim().isEmpty) ||
          (answer is List && answer.isEmpty)) {
        errors[questionId] = FormContentMessages.requiredQuestion(locale);
        continue;
      }
    }

    if (question.type.usesImageUpload) {
      final files = answer is List<String>
          ? answer
          : answer is List
          ? answer.whereType<String>().toList()
          : const <String>[];
      if (question.minSelected != null &&
          files.length < question.minSelected!) {
        errors[questionId] = FormContentMessages.minChoices(
          locale,
          question.minSelected!,
        );
        continue;
      }
      if (question.maxSelected != null &&
          files.length > question.maxSelected!) {
        errors[questionId] = FormContentMessages.maxChoices(
          locale,
          question.maxSelected!,
        );
        continue;
      }
      continue;
    }

    if (answer is String && answer.trim().isNotEmpty) {
      final length = answer.trim().length;
      if (question.minLength != null && length < question.minLength!) {
        errors[questionId] = FormContentMessages.minCharacters(
          locale,
          question.minLength!,
        );
        continue;
      }
      if (question.maxLength != null && length > question.maxLength!) {
        errors[questionId] = FormContentMessages.maxCharacters(
          locale,
          question.maxLength!,
        );
        continue;
      }
    }

    final selected = answer is List<int>
        ? answer
        : answer is int
        ? [answer]
        : const <int>[];
    if (selected.isNotEmpty || question.minSelected != null) {
      if (question.minSelected != null &&
          selected.length < question.minSelected!) {
        errors[questionId] = FormContentMessages.minChoices(
          locale,
          question.minSelected!,
        );
        continue;
      }
      if (question.maxSelected != null &&
          selected.length > question.maxSelected!) {
        errors[questionId] = FormContentMessages.maxChoices(
          locale,
          question.maxSelected!,
        );
      }
    }
  }

  return errors;
}

/// Updates one answer, removes answers to newly hidden questions, and clears the edited
/// question's validation error.
AnswerChange applyAnswerChange({
  required AnswerValues answers,
  required ValidationErrors validationErrors,
  required List<Question> questions,
  required List<QuestionVisibilityRule> visibilityRules,
  required int questionId,
  required AnswerValue value,
}) {
  final updatedAnswers = Map<int, AnswerValue>.from(answers)
    ..[questionId] = value;
  final visibleQuestions = resolveVisibleQuestions(
    questions,
    visibilityRules,
    updatedAnswers,
  );
  final updatedErrors = Map<int, String>.from(validationErrors)
    ..remove(questionId);
  return AnswerChange(
    answers: pruneHiddenAnswers(updatedAnswers, visibleQuestions),
    validationErrors: updatedErrors,
  );
}

bool _matchesVisibilityRules(
  Question target,
  List<QuestionVisibilityRule> rules,
  Map<int, Question> questionsById,
  Set<int> visibleQuestionIds,
  AnswerValues answerValues,
) {
  final results = rules.map((rule) {
    final source = questionsById[rule.sourceQuestionId];
    if (source == null || !visibleQuestionIds.contains(source.id)) {
      return false;
    }
    return _matchesVisibilityRule(source, rule, answerValues[source.id]);
  }).toList();
  return target.visibilityConditionMode == VisibilityConditionMode.any
      ? results.any((result) => result)
      : results.every((result) => result);
}

bool _matchesVisibilityRule(
  Question source,
  QuestionVisibilityRule rule,
  AnswerValue answer,
) {
  final hasAnswer = _answerHasValue(answer);
  switch (rule.operator) {
    case VisibilityOperator.isAnswered:
      return hasAnswer;
    case VisibilityOperator.isNotAnswered:
      return !hasAnswer;
    case VisibilityOperator.equals:
    case VisibilityOperator.notEquals:
    case VisibilityOperator.contains:
    case VisibilityOperator.notContains:
      if (!hasAnswer) return false;
      return _matchesValueOperator(source, rule, answer);
  }
}

bool _matchesValueOperator(
  Question source,
  QuestionVisibilityRule rule,
  AnswerValue answer,
) {
  if (source.type.usesTextAnswer) {
    final actual = answer is String ? answer.trim() : '';
    final expected = rule.value is String ? rule.value as String : null;
    if (expected == null) return false;
    return switch (rule.operator) {
      VisibilityOperator.equals => actual == expected,
      VisibilityOperator.notEquals => actual != expected,
      VisibilityOperator.contains => actual.contains(expected),
      VisibilityOperator.notContains => !actual.contains(expected),
      _ => false,
    };
  }

  final selected = answer is int
      ? [answer]
      : answer is List<int>
      ? answer
      : const <int>[];
  final expected = rule.value == null ? null : _int(rule.value);
  if (expected == null) return false;
  return switch (rule.operator) {
    VisibilityOperator.equals ||
    VisibilityOperator.contains => selected.contains(expected),
    VisibilityOperator.notEquals ||
    VisibilityOperator.notContains => !selected.contains(expected),
    _ => false,
  };
}

bool _answerHasValue(AnswerValue answer) => switch (answer) {
  String value => value.trim().isNotEmpty,
  int _ => true,
  List value => value.isNotEmpty,
  _ => false,
};
