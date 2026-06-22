import SwiftUI

public struct FormConciergeSurveyView: View {
  private let client: FormConciergeClient
  private let surveySlug: String
  private let anonymousToken: String?
  private let deviceInfo: DeviceInfo?
  private let metadata: [String: FormConciergeMetadataValue]?
  private let onAnonymousSession: ((AnonymousSession) -> Void)?
  private let onResponseSubmitted: ((SurveyResponse) -> Void)?
  private let onSubmitted: (() -> Void)?

  @State private var survey: Survey?
  @State private var questions: [Question] = []
  @State private var visibilityRules: [QuestionVisibilityRule] = []
  @State private var choicesByQuestion: [Int: [Choice]] = [:]
  @State private var answers: [Int: SurveyAnswerValue] = [:]
  @State private var isLoading = true
  @State private var isSubmitting = false
  @State private var errorMessage: String?
  @State private var completed = false

  public init(
    client: FormConciergeClient,
    surveySlug: String,
    anonymousToken: String? = nil,
    deviceInfo: DeviceInfo? = nil,
    metadata: [String: FormConciergeMetadataValue]? = nil,
    onAnonymousSession: ((AnonymousSession) -> Void)? = nil,
    onResponseSubmitted: ((SurveyResponse) -> Void)? = nil,
    onSubmitted: (() -> Void)? = nil
  ) {
    self.client = client
    self.surveySlug = surveySlug
    self.anonymousToken = anonymousToken
    self.deviceInfo = deviceInfo
    self.metadata = metadata
    self.onAnonymousSession = onAnonymousSession
    self.onResponseSubmitted = onResponseSubmitted
    self.onSubmitted = onSubmitted
  }

  public var body: some View {
    Group {
      if isLoading {
        ProgressView()
      } else if completed, let survey {
        VStack(spacing: 12) {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 48))
            .foregroundStyle(.green)
          Text("Thanks for completing \(survey.title).")
            .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let survey {
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
              Text(survey.title)
                .font(.largeTitle.bold())
              if let description = survey.description, !description.isEmpty {
                Text(description)
                  .foregroundStyle(.secondary)
              }
            }

            ForEach(visibleQuestions) { question in
              QuestionView(
                question: question,
                choices: choicesByQuestion[question.id] ?? [],
                value: answers[question.id],
                onChange: { updateAnswer(questionId: question.id, value: $0) }
              )
            }

            if let errorMessage {
              Text(errorMessage)
                .foregroundStyle(.red)
            }

            Button {
              Task { await submit() }
            } label: {
              if isSubmitting {
                ProgressView()
              } else {
                Text("Submit")
                  .frame(maxWidth: .infinity)
              }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitting)
          }
          .padding()
        }
      } else {
        VStack(spacing: 12) {
          Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 42))
            .foregroundStyle(.secondary)
          Text("Survey unavailable")
            .font(.headline)
          Text(errorMessage ?? "Please try again later.")
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding()
      }
    }
    .task { await load() }
  }

  private func load() async {
    isLoading = true
    defer { isLoading = false }
    do {
      if let anonymousToken {
        await client.setAnonymousToken(anonymousToken)
      }
      if !(await client.hasAnonymousToken()) {
        let session = try await client.createAnonymousAccount()
        onAnonymousSession?(session)
      }
      let loadedSurvey = try await client.survey(slug: surveySlug)
      let loadedQuestions = try await client.questions(surveyId: loadedSurvey.id)
      let loadedVisibilityRules = try await client.visibilityRules(surveyId: loadedSurvey.id)
      var loadedChoices: [Int: [Choice]] = [:]
      for question in loadedQuestions
      where question.type == .singleChoice || question.type == .multipleChoice {
        loadedChoices[question.id] = try await client.choices(questionId: question.id)
      }
      survey = loadedSurvey
      questions = loadedQuestions
      visibilityRules = loadedVisibilityRules
      choicesByQuestion = loadedChoices
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func submit() async {
    guard let survey else { return }
    let validationError = validate()
    guard validationError == nil else {
      errorMessage = validationError
      return
    }

    isSubmitting = true
    defer { isSubmitting = false }

    do {
      let payload = visibleQuestions.compactMap { question -> Answer? in
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
        }
      }
      let response = try await client.submitResponse(
        surveyId: survey.id,
        answers: payload,
        deviceInfo: deviceInfo,
        metadata: metadata
      )
      completed = true
      onResponseSubmitted?(response)
      onSubmitted?()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func validate() -> String? {
    for question in visibleQuestions {
      let value = answers[question.id]
      if question.isRequired, value == nil || value?.isEmpty == true {
        return "\(question.text) is required."
      }
      if case .text(let text) = value {
        let count = text.trimmingCharacters(in: .whitespacesAndNewlines).count
        if let minLength = question.minLength, count > 0, count < minLength {
          return "\(question.text) must be at least \(minLength) characters."
        }
        if let maxLength = question.maxLength, count > maxLength {
          return "\(question.text) must be at most \(maxLength) characters."
        }
      }
      let selectedCount: Int
      switch value {
      case .single:
        selectedCount = 1
      case .multiple(let values):
        selectedCount = values.count
      case .text, nil:
        selectedCount = 0
      }
      if let minSelected = question.minSelected, selectedCount < minSelected {
        return "\(question.text) requires at least \(minSelected) choices."
      }
      if let maxSelected = question.maxSelected, selectedCount > maxSelected {
        return "\(question.text) allows at most \(maxSelected) choices."
      }
    }
    return nil
  }

  private var visibleQuestions: [Question] {
    resolveVisibleQuestions(
      questions: questions,
      rules: visibilityRules,
      answers: answers
    )
  }

  private func updateAnswer(questionId: Int, value: SurveyAnswerValue) {
    var next = answers
    next[questionId] = value
    let visibleIds = Set(
      resolveVisibleQuestions(
        questions: questions,
        rules: visibilityRules,
        answers: next
      ).map(\.id)
    )
    answers = next.filter { visibleIds.contains($0.key) }
  }
}

public enum SurveyAnswerValue: Equatable, Sendable {
  case text(String)
  case single(Int)
  case multiple(Set<Int>)

  var isEmpty: Bool {
    switch self {
    case .text(let text):
      text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .single:
      false
    case .multiple(let values):
      values.isEmpty
    }
  }
}

private func resolveVisibleQuestions(
  questions: [Question],
  rules: [QuestionVisibilityRule],
  answers: [Int: SurveyAnswerValue]
) -> [Question] {
  let questionsById = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0) })
  let rulesByTarget = Dictionary(grouping: rules, by: \.targetQuestionId)
  var visibleIds = Set<Int>()
  var visibleQuestions: [Question] = []

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
      isVisible = question.visibilityConditionMode == .any
        ? outcomes.contains(true)
        : outcomes.allSatisfy { $0 }
    }
    if isVisible {
      visibleIds.insert(question.id)
      visibleQuestions.append(question)
    }
  }

  return visibleQuestions
}

private func matchesRule(
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
    let expected = rule.value?.stringValue ?? ""
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
    case .text, nil:
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
  }
}

private struct QuestionView: View {
  let question: Question
  let choices: [Choice]
  let value: SurveyAnswerValue?
  let onChange: (SurveyAnswerValue) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(question.text)
        .font(.headline)
      switch question.type {
      case .textSingle:
        TextField(question.placeholder ?? "", text: textBinding)
          .textFieldStyle(.roundedBorder)
      case .textMultiLine:
        TextEditor(text: textBinding)
          .frame(minHeight: 120)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(.quaternary)
          )
      case .singleChoice:
        Picker(question.text, selection: singleBinding) {
          Text("Select").tag(-1)
          ForEach(choices) { choice in
            Text(choice.text).tag(choice.id)
          }
        }
        .pickerStyle(.inline)
      case .multipleChoice:
        ForEach(choices) { choice in
          Toggle(
            choice.text,
            isOn: Binding(
              get: { multipleValue.contains(choice.id) },
              set: { enabled in
                var next = multipleValue
                if enabled {
                  next.insert(choice.id)
                } else {
                  next.remove(choice.id)
                }
                onChange(.multiple(next))
              }
            )
          )
        }
      }
    }
  }

  private var textBinding: Binding<String> {
    Binding(
      get: {
        if case .text(let text) = value { return text }
        return ""
      },
      set: { onChange(.text($0)) }
    )
  }

  private var singleBinding: Binding<Int> {
    Binding(
      get: {
        if case .single(let choiceId) = value { return choiceId }
        return -1
      },
      set: { if $0 >= 0 { onChange(.single($0)) } }
    )
  }

  private var multipleValue: Set<Int> {
    if case .multiple(let choiceIds) = value {
      return choiceIds
    }
    return []
  }
}
