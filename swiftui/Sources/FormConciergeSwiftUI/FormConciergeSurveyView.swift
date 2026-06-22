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

            ForEach(questions) { question in
              QuestionView(
                question: question,
                choices: choicesByQuestion[question.id] ?? [],
                value: answers[question.id],
                onChange: { answers[question.id] = $0 }
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
      var loadedChoices: [Int: [Choice]] = [:]
      for question in loadedQuestions
      where question.type == .singleChoice || question.type == .multipleChoice {
        loadedChoices[question.id] = try await client.choices(questionId: question.id)
      }
      survey = loadedSurvey
      questions = loadedQuestions
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
      let payload = questions.compactMap { question -> Answer? in
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
    for question in questions where question.isRequired {
      guard let value = answers[question.id], !value.isEmpty else {
        return "\(question.text) is required."
      }
    }
    return nil
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
