part of form_concierge_client;

typedef AnswerValue = Object?;
typedef AnswerValues = Map<int, AnswerValue>;
typedef ValidationErrors = Map<int, String>;

class Answer {
  final int? id;
  final int surveyResponseId;
  final int questionId;
  final String? textValue;
  final List<int>? selectedChoiceIds;

  const Answer({
    this.id,
    required this.surveyResponseId,
    required this.questionId,
    this.textValue,
    this.selectedChoiceIds,
  });

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
    id: json['id'] == null ? null : _int(json['id']),
    surveyResponseId: _int(json['surveyResponseId']),
    questionId: _int(json['questionId']),
    textValue: _optionalString(json['textValue']),
    selectedChoiceIds: _intList(json['selectedChoiceIds']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'surveyResponseId': surveyResponseId,
    'questionId': questionId,
    'textValue': textValue,
    'selectedChoiceIds': selectedChoiceIds,
  });

  Answer copyWith({
    int? id,
    int? surveyResponseId,
    int? questionId,
    String? textValue,
    List<int>? selectedChoiceIds,
  }) {
    return Answer(
      id: id ?? this.id,
      surveyResponseId: surveyResponseId ?? this.surveyResponseId,
      questionId: questionId ?? this.questionId,
      textValue: textValue ?? this.textValue,
      selectedChoiceIds: selectedChoiceIds ?? this.selectedChoiceIds,
    );
  }
}

class AnswerChange {
  final AnswerValues answers;
  final ValidationErrors validationErrors;

  const AnswerChange({
    required this.answers,
    required this.validationErrors,
  });
}

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
    }
  }

  return result;
}

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

bool _answerHasValue(AnswerValue answer) {
  return switch (answer) {
    String value => value.trim().isNotEmpty,
    int _ => true,
    List value => value.isNotEmpty,
    _ => false,
  };
}
