import Foundation

public enum FormConciergeSurveyLogic {
  public static func visibleQuestions(
    questions: [Question],
    rules: [QuestionVisibilityRule],
    answers: [Int: SurveyAnswerValue]
  ) -> [Question] {
    let questionsById = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0) })
    let rulesByTarget = Dictionary(grouping: rules, by: \.targetQuestionId)
    var visibleIds = Set<Int>()
    var result: [Question] = []

    for question in questions {
      let questionRules = rulesByTarget[question.id] ?? []
      let isVisible: Bool
      if questionRules.isEmpty {
        isVisible = true
      } else {
        let outcomes = questionRules.map { rule -> Bool in
          guard
            let source = questionsById[rule.sourceQuestionId],
            visibleIds.contains(source.id)
          else { return false }
          return matchesRule(source: source, rule: rule, answer: answers[source.id])
        }
        isVisible =
          question.visibilityConditionMode == .any
          ? outcomes.contains(true)
          : outcomes.allSatisfy { $0 }
      }
      if isVisible {
        visibleIds.insert(question.id)
        result.append(question)
      }
    }

    return result
  }

  public static func validationError(
    questions: [Question],
    answers: [Int: SurveyAnswerValue],
    locale: String
  ) -> String? {
    for question in questions {
      let value = answers[question.id]
      let questionText = question.text(for: locale)
      if question.isRequired, value == nil || value?.isEmpty == true {
        return FormContentMessages.requiredQuestion(locale, question: questionText)
      }
      if case .text(let text) = value {
        let count = text.trimmingCharacters(in: .whitespacesAndNewlines).count
        if let minLength = question.minLength, count > 0, count < minLength {
          return FormContentMessages.minCharacters(
            locale, question: questionText, count: minLength)
        }
        if let maxLength = question.maxLength, count > maxLength {
          return FormContentMessages.maxCharacters(
            locale, question: questionText, count: maxLength)
        }
      }

      let selectedCount: Int
      switch value {
      case .single:
        selectedCount = 1
      case .multiple(let values):
        selectedCount = values.count
      case .images(let fileKeys):
        selectedCount = fileKeys.count
      case .text, nil:
        selectedCount = 0
      }
      if question.type == .singleChoice
        || question.type == .multipleChoice
        || question.type == .imageUpload
      {
        if let minSelected = question.minSelected, selectedCount < minSelected {
          return FormContentMessages.minChoices(
            locale, question: questionText, count: minSelected)
        }
        if let maxSelected = question.maxSelected, selectedCount > maxSelected {
          return FormContentMessages.maxChoices(
            locale, question: questionText, count: maxSelected)
        }
      }
    }
    return nil
  }

  public static func answerPayload(
    questions: [Question],
    answers: [Int: SurveyAnswerValue]
  ) -> [Answer] {
    questions.compactMap { question in
      guard let value = answers[question.id] else { return nil }
      switch value {
      case .text(let text):
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : Answer(questionId: question.id, textValue: trimmed)
      case .single(let choiceId):
        return Answer(questionId: question.id, selectedChoiceIds: [choiceId])
      case .multiple(let choiceIds):
        return choiceIds.isEmpty
          ? nil : Answer(questionId: question.id, selectedChoiceIds: Array(choiceIds))
      case .images(let fileKeys):
        return fileKeys.isEmpty ? nil : Answer(questionId: question.id, fileKeys: fileKeys)
      }
    }
  }

  private static func matchesRule(
    source: Question,
    rule: QuestionVisibilityRule,
    answer: SurveyAnswerValue?
  ) -> Bool {
    let hasAnswer = !(answer?.isEmpty ?? true)
    switch rule.operator {
    case .isAnswered:
      return hasAnswer
    case .isNotAnswered:
      return !hasAnswer
    case .equals, .notEquals, .contains, .notContains:
      guard hasAnswer else { return false }
    }

    switch source.type {
    case .textSingle, .textMultiLine:
      let actual: String
      if case .text(let value) = answer {
        actual = value.trimmingCharacters(in: .whitespacesAndNewlines)
      } else {
        actual = ""
      }
      guard let expected = rule.value?.stringValue else { return false }
      switch rule.operator {
      case .equals:
        return actual == expected
      case .notEquals:
        return actual != expected
      case .contains:
        return actual.contains(expected)
      case .notContains:
        return !actual.contains(expected)
      case .isAnswered, .isNotAnswered:
        return false
      }
    case .singleChoice, .multipleChoice:
      guard let expected = rule.value?.intValue else { return false }
      let selected: Set<Int>
      switch answer {
      case .single(let choiceId):
        selected = [choiceId]
      case .multiple(let choiceIds):
        selected = choiceIds
      case .text, .images, nil:
        selected = []
      }
      switch rule.operator {
      case .equals, .contains:
        return selected.contains(expected)
      case .notEquals, .notContains:
        return !selected.contains(expected)
      case .isAnswered, .isNotAnswered:
        return false
      }
    case .imageUpload:
      return hasAnswer
    }
  }
}
