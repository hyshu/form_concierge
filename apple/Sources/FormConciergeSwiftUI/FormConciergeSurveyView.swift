import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

public struct FormConciergeSurveyView: View {
  private let client: FormConciergeClient
  private let projectSlug: String
  private let surveySlug: String?
  private let surveyId: Int?
  private let anonymousToken: String?
  private let locale: String?
  private let deviceInfo: DeviceInfo?
  private let metadata: [String: FormConciergeMetadataValue]?
  private let onAnonymousSession: ((AnonymousSession) -> Void)?
  private let onResponseSubmitted: ((SurveyResponse) -> Void)?
  private let onFollowUpSubmitted: ((SurveyResponse) -> Void)?
  private let onSubmitted: (() -> Void)?
  /// Called when the user taps the completion-screen "Done" button.
  private let onDone: (() -> Void)?
  /// Optional host-side image transform before upload (resize/compress/edit).
  ///
  /// Called for each picked image. Return the image to upload, or `nil` to skip
  /// that image. When omitted, HEIC/unknown formats are converted to JPEG.
  private let processImage: ProcessSurveyImage?

  /// Supplies a CAPTCHA token when the survey has CAPTCHA enabled.
  ///
  /// The view never embeds a CAPTCHA implementation: the host resolves a token
  /// with whatever provider it chooses (e.g. Cloudflare Turnstile in a web view)
  /// and returns it here. Return `nil` to abort the submission.
  private let captchaTokenProvider: (() async -> String?)?

  @State private var project: Project?
  @State private var survey: Survey?
  @State private var questions: [Question] = []
  @State private var visibilityRules: [QuestionVisibilityRule] = []
  @State private var choicesByQuestion: [Int: [Choice]] = [:]
  @State private var answers: [Int: SurveyAnswerValue] = [:]
  @State private var isLoading = true
  @State private var isSubmitting = false
  @State private var isGeneratingFollowUp = false
  @State private var errorMessage: String?
  @State private var completed = false
  @State private var submittedResponse: SurveyResponse?
  @State private var followUp: FollowUp?
  @State private var followUpAnswers: [String: FollowUpAnswerValue] = [:]

  public init(
    client: FormConciergeClient,
    projectSlug: String,
    surveySlug: String? = nil,
    surveyId: Int? = nil,
    anonymousToken: String? = nil,
    locale: String? = nil,
    deviceInfo: DeviceInfo? = nil,
    metadata: [String: FormConciergeMetadataValue]? = nil,
    onAnonymousSession: ((AnonymousSession) -> Void)? = nil,
    onResponseSubmitted: ((SurveyResponse) -> Void)? = nil,
    onFollowUpSubmitted: ((SurveyResponse) -> Void)? = nil,
    onSubmitted: (() -> Void)? = nil,
    onDone: (() -> Void)? = nil,
    processImage: ProcessSurveyImage? = nil,
    captchaTokenProvider: (() async -> String?)? = nil
  ) {
    self.client = client
    self.projectSlug = projectSlug
    self.surveySlug = surveySlug
    self.surveyId = surveyId
    self.anonymousToken = anonymousToken
    self.locale = locale
    self.deviceInfo = deviceInfo
    self.metadata = metadata
    self.onAnonymousSession = onAnonymousSession
    self.onResponseSubmitted = onResponseSubmitted
    self.onFollowUpSubmitted = onFollowUpSubmitted
    self.onSubmitted = onSubmitted
    self.onDone = onDone
    self.processImage = processImage
    self.captchaTokenProvider = captchaTokenProvider
  }

  public var body: some View {
    Group {
      if isLoading {
        ProgressView(FormContentMessages.text(activeLocale, "loadingSurvey"))
      } else if isGeneratingFollowUp {
        ProgressView(FormContentMessages.text(activeLocale, "followUpLoading"))
      } else if let followUp {
        FollowUpView(
          client: client,
          followUp: followUp,
          answers: followUpAnswers,
          locale: activeLocale,
          isSubmitting: isSubmitting,
          errorMessage: errorMessage,
          ensureAuthenticated: ensureAuthenticated,
          processImage: processImage,
          onChange: { followUpAnswers[$0] = $1 },
          onSubmit: { Task { await submitFollowUp() } }
        )
      } else if completed, let survey {
        VStack(spacing: 16) {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 48))
            .foregroundStyle(.green)
          Text(FormContentMessages.text(activeLocale, "thankYou"))
            .font(.headline)
          Text(
            FormContentMessages.submittedWithTitle(
              activeLocale, title: survey.title(for: activeLocale))
          )
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
          if let onDone {
            Button(FormContentMessages.text(activeLocale, "done"), action: onDone)
              .buttonStyle(.borderedProminent)
              .padding(.top, 8)
          }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let survey {
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
              Text(survey.title(for: activeLocale))
                .font(.largeTitle.bold())
              let description = survey.description(for: activeLocale)
              if !description.isEmpty {
                Text(description)
                  .foregroundStyle(.secondary)
              }
            }

            ForEach(visibleQuestions) { question in
              QuestionView(
                client: client,
                question: question,
                choices: choicesByQuestion[question.id] ?? [],
                value: answers[question.id],
                locale: activeLocale,
                ensureAuthenticated: ensureAuthenticated,
                processImage: processImage,
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
              ZStack {
                Text(FormContentMessages.text(activeLocale, "submit"))
                  .opacity(isSubmitting ? 0 : 1)
                if isSubmitting {
                  ProgressView(FormContentMessages.text(activeLocale, "submitting"))
                }
              }
              .frame(maxWidth: .infinity)
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
          Text(FormContentMessages.text(activeLocale, "surveyUnavailable"))
            .font(.headline)
          Text(errorMessage ?? FormContentMessages.text(activeLocale, "tryAgainLater"))
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
      // Restore provided token only. Create anonymously on submit so notFound /
      // abandoned page views do not insert unused anonymous_accounts rows.
      if let anonymousToken {
        await client.setAnonymousToken(anonymousToken)
      }
      let loadedProject = try await client.project(slug: projectSlug)
      guard let loadedSurvey = selectedSurvey(from: loadedProject) else {
        throw FormConciergeError.notFound
      }
      let loadedQuestions = try await client.questions(surveyId: loadedSurvey.id)
      let loadedVisibilityRules = try await client.visibilityRules(surveyId: loadedSurvey.id)
      var loadedChoices: [Int: [Choice]] = [:]
      for question in loadedQuestions
      where question.type == .singleChoice || question.type == .multipleChoice {
        loadedChoices[question.id] = try await client.choices(questionId: question.id)
      }
      project = loadedProject.project
      survey = loadedSurvey
      questions = loadedQuestions
      visibilityRules = loadedVisibilityRules
      choicesByQuestion = loadedChoices
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func selectedSurvey(from project: PublicProject) -> Survey? {
    if let surveySlug {
      return project.surveys.first { $0.slug == surveySlug }
    }
    if let surveyId {
      return project.surveys.first { $0.id == surveyId }
    }
    // Match the Flutter widget: only auto-select when exactly one survey
    // exists, so multi-survey projects require an explicit slug or id.
    return project.surveys.count == 1 ? project.surveys.first : nil
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
      if !(await client.hasAnonymousToken()) {
        let session = try await client.createAnonymousAccount()
        onAnonymousSession?(session)
      }
      let payload = FormConciergeSurveyLogic.answerPayload(
        questions: visibleQuestions,
        answers: answers
      )
      var captchaToken: String?
      if survey.captchaRequired {
        captchaToken = await captchaTokenProvider?()
        guard let token = captchaToken, !token.isEmpty else {
          errorMessage = FormContentMessages.text(activeLocale, "captchaRequired")
          return
        }
      }
      let response = try await client.submitResponse(
        surveyId: survey.id,
        answers: payload,
        deviceInfo: deviceInfo,
        metadata: metadata,
        captchaToken: captchaToken
      )
      submittedResponse = response
      onResponseSubmitted?(response)
      onSubmitted?()
      if survey.followUpEnabled {
        await startFollowUp(responseId: response.id)
      } else {
        completed = true
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func startFollowUp(responseId: Int) async {
    isGeneratingFollowUp = true
    defer { isGeneratingFollowUp = false }
    do {
      let result = try await client.generateFollowUp(responseId: responseId, locale: activeLocale)
      if result.needed, result.followUp.status == .pending, !result.followUp.items.isEmpty {
        followUp = result.followUp
        followUpAnswers = [:]
      } else {
        completed = true
      }
    } catch {
      completed = true
    }
  }

  private func submitFollowUp() async {
    guard let responseId = submittedResponse?.id, let followUp else {
      completed = true
      return
    }
    isSubmitting = true
    errorMessage = nil
    defer { isSubmitting = false }

    let payload = followUp.items.map { item in
      switch followUpAnswers[item.id] {
      case .text(let text):
        FollowUpSubmissionAnswer(
          id: item.id,
          textValue: text.trimmingCharacters(in: .whitespacesAndNewlines)
        )
      case .single(let choiceId):
        FollowUpSubmissionAnswer(id: item.id, selectedChoiceIds: [choiceId])
      case .multiple(let choiceIds):
        FollowUpSubmissionAnswer(id: item.id, selectedChoiceIds: Array(choiceIds))
      case .images(let fileKeys):
        FollowUpSubmissionAnswer(id: item.id, fileKeys: fileKeys)
      case nil:
        FollowUpSubmissionAnswer(id: item.id)
      }
    }

    do {
      let response = try await client.saveFollowUp(responseId: responseId, answers: payload)
      submittedResponse = response
      self.followUp = nil
      completed = true
      onFollowUpSubmitted?(response)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func validate() -> String? {
    FormConciergeSurveyLogic.validationError(
      questions: visibleQuestions,
      answers: answers,
      locale: activeLocale
    )
  }

  private func ensureAuthenticated() async throws {
    if await client.hasAnonymousToken() { return }
    let session = try await client.createAnonymousAccount()
    onAnonymousSession?(session)
  }

  private var visibleQuestions: [Question] {
    FormConciergeSurveyLogic.visibleQuestions(
      questions: questions,
      rules: visibilityRules,
      answers: answers
    )
  }

  private func updateAnswer(questionId: Int, value: SurveyAnswerValue) {
    var next = answers
    next[questionId] = value
    let visibleIds = Set(
      FormConciergeSurveyLogic.visibleQuestions(
        questions: questions,
        rules: visibilityRules,
        answers: next
      ).map(\.id)
    )
    answers = next.filter { visibleIds.contains($0.key) }
  }

  private var activeLocale: String {
    normalizeFormContentLocale(
      locale ?? project?.defaultLocale ?? defaultFormContentLocale
    )
  }
}

public enum SurveyAnswerValue: Equatable, Sendable {
  case text(String)
  case single(Int)
  case multiple(Set<Int>)
  case images([String])

  public var isEmpty: Bool {
    switch self {
    case .text(let text):
      text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    case .single:
      false
    case .multiple(let values):
      values.isEmpty
    case .images(let fileKeys):
      fileKeys.isEmpty
    }
  }
}

private enum FollowUpAnswerValue: Equatable, Sendable {
  case text(String)
  case single(String)
  case multiple(Set<String>)
  case images([String])
}

private struct FollowUpView: View {
  let client: FormConciergeClient
  let followUp: FollowUp
  let answers: [String: FollowUpAnswerValue]
  let locale: String
  let isSubmitting: Bool
  let errorMessage: String?
  let ensureAuthenticated: () async throws -> Void
  let processImage: ProcessSurveyImage?
  let onChange: (String, FollowUpAnswerValue) -> Void
  let onSubmit: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Text(FormContentMessages.text(locale, "followUpTitle"))
            .font(.title2.bold())
          Text(FormContentMessages.text(locale, "followUpSubtitle"))
            .foregroundStyle(.secondary)
        }

        ForEach(followUp.items) { item in
          FollowUpItemView(
            client: client,
            item: item,
            value: answers[item.id],
            locale: locale,
            ensureAuthenticated: ensureAuthenticated,
            processImage: processImage,
            onChange: { onChange(item.id, $0) }
          )
        }

        if let errorMessage {
          Text(errorMessage)
            .foregroundStyle(.red)
        }

        Button(action: onSubmit) {
          ZStack {
            Text(FormContentMessages.text(locale, "followUpContinue"))
              .opacity(isSubmitting ? 0 : 1)
            if isSubmitting {
              ProgressView(FormContentMessages.text(locale, "followUpSubmitting"))
            }
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isSubmitting)
      }
      .padding()
    }
  }
}

private struct FollowUpItemView: View {
  let client: FormConciergeClient
  let item: FollowUpItem
  let value: FollowUpAnswerValue?
  let locale: String
  let ensureAuthenticated: () async throws -> Void
  let processImage: ProcessSurveyImage?
  let onChange: (FollowUpAnswerValue) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(item.text)
        .font(.headline)

      switch item.type {
      case .textSingle:
        TextField(item.placeholder ?? "", text: textBinding)
          .textFieldStyle(.roundedBorder)
      case .textMultiLine:
        TextEditor(text: textBinding)
          .frame(minHeight: 120)
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
      case .singleChoice:
        ForEach(item.choices) { choice in
          Button {
            onChange(.single(choice.id))
          } label: {
            HStack {
              Image(systemName: singleValue == choice.id ? "circle.inset.filled" : "circle")
              Text(choice.label)
              Spacer()
            }
          }
          .buttonStyle(.plain)
        }
      case .multipleChoice:
        ForEach(item.choices) { choice in
          Toggle(
            choice.label,
            isOn: Binding(
              get: { multipleValue.contains(choice.id) },
              set: { selected in
                var next = multipleValue
                if selected {
                  next.insert(choice.id)
                } else {
                  next.remove(choice.id)
                }
                onChange(.multiple(next))
              }
            )
          )
        }
      case .imageUpload:
        ImageUploadQuestionView(
          client: client,
          maxFiles: item.maxFiles ?? 1,
          fileKeys: imageKeys,
          locale: locale,
          ensureAuthenticated: ensureAuthenticated,
          processImage: processImage,
          onChange: { onChange(.images($0)) }
        )
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

  private var singleValue: String? {
    if case .single(let choiceId) = value { return choiceId }
    return nil
  }

  private var multipleValue: Set<String> {
    if case .multiple(let choiceIds) = value { return choiceIds }
    return []
  }

  private var imageKeys: [String] {
    if case .images(let keys) = value { return keys }
    return []
  }
}

private struct QuestionView: View {
  let client: FormConciergeClient
  let question: Question
  let choices: [Choice]
  let value: SurveyAnswerValue?
  let locale: String
  let ensureAuthenticated: () async throws -> Void
  let processImage: ProcessSurveyImage?
  let onChange: (SurveyAnswerValue) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(question.text(for: locale))
        .font(.headline)
      switch question.type {
      case .textSingle:
        TextField(question.placeholder(for: locale), text: textBinding)
          .textFieldStyle(.roundedBorder)
      case .textMultiLine:
        TextEditor(text: textBinding)
          .frame(minHeight: 120)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(.quaternary)
          )
      case .singleChoice:
        Picker(question.text(for: locale), selection: singleBinding) {
          Text(FormContentMessages.text(locale, "select")).tag(-1)
          ForEach(choices) { choice in
            Text(choice.text(for: locale)).tag(choice.id)
          }
        }
        .pickerStyle(.inline)
      case .multipleChoice:
        ForEach(choices) { choice in
          let selected = multipleValue.contains(choice.id)
          let atMax =
            question.maxSelected.map { multipleValue.count >= $0 } ?? false
          Toggle(
            choice.text(for: locale),
            isOn: Binding(
              get: { selected },
              set: { enabled in
                var next = multipleValue
                if enabled {
                  if atMax && !selected { return }
                  next.insert(choice.id)
                } else {
                  next.remove(choice.id)
                }
                onChange(.multiple(next))
              }
            )
          )
          // Match Flutter: disable unselected options once maxSelected is reached.
          .disabled(atMax && !selected)
        }
      case .imageUpload:
        ImageUploadQuestionView(
          client: client,
          maxFiles: question.maxSelected ?? 3,
          fileKeys: imageKeys,
          locale: locale,
          ensureAuthenticated: ensureAuthenticated,
          processImage: processImage,
          onChange: { onChange(.images($0)) }
        )
      }
    }
  }

  private var imageKeys: [String] {
    if case .images(let keys) = value { return keys }
    return []
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

// MARK: - Image upload

private struct ImageUploadQuestionView: View {
  let client: FormConciergeClient
  let maxFiles: Int
  let fileKeys: [String]
  let locale: String
  let ensureAuthenticated: () async throws -> Void
  let processImage: ProcessSurveyImage?
  let onChange: ([String]) -> Void

  @State private var pickerItems: [PhotosPickerItem] = []
  @State private var isUploading = false
  @State private var localError: String?
  @State private var previews: [String: Data] = [:]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if !fileKeys.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(fileKeys, id: \.self) { key in
              ZStack(alignment: .topTrailing) {
                preview(for: key)
                  .frame(width: 88, height: 88)
                  .clipShape(RoundedRectangle(cornerRadius: 8))
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(.quaternary)
                  )
                Button {
                  remove(key: key)
                } label: {
                  Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(FormContentMessages.text(locale, "removePhoto"))
                .offset(x: 6, y: -6)
                .disabled(isUploading)
              }
            }
          }
          .padding(.vertical, 4)
        }
      }

      Text(
        FormContentMessages.text(locale, "maxPhotosReached")
          .replacingOccurrences(of: "{count}", with: "\(maxFiles)")
      )
      .font(.footnote)
      .foregroundStyle(.secondary)

      PhotosPicker(
        selection: $pickerItems,
        maxSelectionCount: max(maxFiles - fileKeys.count, 0),
        matching: .images,
        photoLibrary: .shared()
      ) {
        Label(
          FormContentMessages.text(
            locale,
            isUploading ? "uploadingPhotos" : "addPhotos"
          ),
          systemImage: "photo.badge.plus"
        )
      }
      .disabled(isUploading || fileKeys.count >= maxFiles)
      .onChange(of: pickerItems) { items in
        guard !items.isEmpty else { return }
        Task { await upload(items: items) }
      }

      if let localError {
        Text(localError)
          .font(.footnote)
          .foregroundStyle(.red)
      }
    }
  }

  @ViewBuilder
  private func preview(for key: String) -> some View {
    if let data = previews[key], let image = platformImage(from: data) {
      image
        .resizable()
        .scaledToFill()
    } else {
      ZStack {
        Color.secondary.opacity(0.12)
        Image(systemName: "photo")
          .foregroundStyle(.secondary)
      }
    }
  }

  private func remove(key: String) {
    var next = fileKeys
    next.removeAll { $0 == key }
    previews[key] = nil
    onChange(next)
  }

  private func upload(items: [PhotosPickerItem]) async {
    isUploading = true
    localError = nil
    defer {
      isUploading = false
      pickerItems = []
    }

    do {
      try await ensureAuthenticated()
      var keys = fileKeys
      for item in items {
        if keys.count >= maxFiles { break }
        guard let data = try await item.loadTransferable(type: Data.self), !data.isEmpty
        else { continue }
        let contentType = contentType(for: item) ?? "image/jpeg"
        let prepared = try await prepareForUpload(
          SurveyImagePayload(data: data, contentType: contentType)
        )
        guard let prepared, !prepared.data.isEmpty else { continue }
        let uploaded = try await client.uploadMedia(
          data: prepared.data,
          contentType: prepared.contentType
        )
        keys.append(uploaded.key)
        previews[uploaded.key] = prepared.data
      }
      onChange(keys)
    } catch {
      localError = FormContentMessages.text(locale, "photoUploadFailed")
    }
  }

  /// Host process hook when provided; otherwise convert unsupported types to JPEG.
  private func prepareForUpload(_ image: SurveyImagePayload) async throws -> SurveyImagePayload? {
    if let processImage {
      return try await processImage(image)
    }
    let fallback = try jpegDataIfNeeded(image.data, contentType: image.contentType)
    return SurveyImagePayload(data: fallback.data, contentType: fallback.contentType)
  }

  private func contentType(for item: PhotosPickerItem) -> String? {
    guard let type = item.supportedContentTypes.first else { return nil }
    if type.conforms(to: .png) { return "image/png" }
    if type.conforms(to: .gif) { return "image/gif" }
    if type.conforms(to: .webP) { return "image/webp" }
    if type.conforms(to: .jpeg) { return "image/jpeg" }
    return type.preferredMIMEType
  }

  /// Prefer JPEG for HEIC/unknown formats so the Worker accepts the body.
  private func jpegDataIfNeeded(_ data: Data, contentType: String) throws -> (
    data: Data, contentType: String
  ) {
    let allowed = ["image/jpeg", "image/png", "image/webp", "image/gif"]
    if allowed.contains(contentType) {
      return (data, contentType)
    }
    #if canImport(UIKit)
      if let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.85) {
        return (jpeg, "image/jpeg")
      }
    #elseif canImport(AppKit)
      if let image = NSImage(data: data),
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let jpeg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85])
      {
        return (jpeg, "image/jpeg")
      }
    #endif
    return (data, "image/jpeg")
  }

  private func platformImage(from data: Data) -> Image? {
    #if canImport(UIKit)
      guard let uiImage = UIImage(data: data) else { return nil }
      return Image(uiImage: uiImage)
    #elseif canImport(AppKit)
      guard let nsImage = NSImage(data: data) else { return nil }
      return Image(nsImage: nsImage)
    #else
      return nil
    #endif
  }
}
