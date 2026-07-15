#if canImport(UIKit)
  @_exported import FormConciergeSwiftUI
  import UIKit

  @MainActor
  public final class FormConciergeSurveyViewController: UIViewController {
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
    private let onDone: (() -> Void)?
    private let processImage: ProcessSurveyImage?
    private let captchaTokenProvider: (() async -> String?)?

    private var project: Project?
    private var survey: Survey?
    private var questions: [Question] = []
    private var visibilityRules: [QuestionVisibilityRule] = []
    private var choicesByQuestion: [Int: [Choice]] = [:]
    private var answers: [Int: SurveyAnswerValue] = [:]
    private var submittedResponse: SurveyResponse?
    private var followUp: FollowUp?
    private var followUpAnswers: [String: UIKitFollowUpAnswerValue] = [:]
    private var isLoading = true
    private var isSubmitting = false
    private var isGeneratingFollowUp = false
    private var isCompleted = false
    private var errorMessage: String?
    private var loadTask: Task<Void, Never>?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

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
      super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
      super.viewDidLoad()
      configureView()
      reloadSurvey()
    }

    deinit {
      loadTask?.cancel()
    }

    public func reloadSurvey() {
      loadTask?.cancel()
      loadTask = Task { [weak self] in
        await self?.load()
      }
    }

    private func configureView() {
      view.backgroundColor = .systemBackground
      scrollView.keyboardDismissMode = .interactive
      scrollView.alwaysBounceVertical = true
      scrollView.translatesAutoresizingMaskIntoConstraints = false

      contentStack.axis = .vertical
      contentStack.alignment = .fill
      contentStack.spacing = 24
      contentStack.translatesAutoresizingMaskIntoConstraints = false

      view.addSubview(scrollView)
      scrollView.addSubview(contentStack)

      NSLayoutConstraint.activate([
        scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        contentStack.topAnchor.constraint(
          equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
        contentStack.leadingAnchor.constraint(
          equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
        contentStack.trailingAnchor.constraint(
          equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
        contentStack.bottomAnchor.constraint(
          equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
      ])
    }

    private func load() async {
      isLoading = true
      errorMessage = nil
      render()
      defer {
        isLoading = false
        render()
      }

      do {
        if let anonymousToken {
          await client.setAnonymousToken(anonymousToken)
        }
        let loadedProject = try await client.project(slug: projectSlug)
        guard let loadedSurvey = selectedSurvey(from: loadedProject) else {
          throw FormConciergeError.notFound
        }
        async let loadedQuestions = client.questions(surveyId: loadedSurvey.id)
        async let loadedRules = client.visibilityRules(surveyId: loadedSurvey.id)
        let questions = try await loadedQuestions
        var choicesByQuestion: [Int: [Choice]] = [:]
        for question in questions
        where question.type == .singleChoice || question.type == .multipleChoice {
          choicesByQuestion[question.id] = try await client.choices(questionId: question.id)
        }

        project = loadedProject.project
        survey = loadedSurvey
        self.questions = questions
        visibilityRules = try await loadedRules
        self.choicesByQuestion = choicesByQuestion
      } catch is CancellationError {
        return
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
      return project.surveys.count == 1 ? project.surveys.first : nil
    }

    private func render() {
      contentStack.removeAllArrangedSubviews()

      if isLoading {
        contentStack.addArrangedSubview(
          UIKitComponentFactory.loadingView(
            text: FormContentMessages.text(activeLocale, "loadingSurvey")))
      } else if isGeneratingFollowUp {
        contentStack.addArrangedSubview(
          UIKitComponentFactory.loadingView(
            text: FormContentMessages.text(activeLocale, "followUpLoading")))
      } else if let followUp {
        renderFollowUp(followUp)
      } else if isCompleted, let survey {
        renderCompletion(survey)
      } else if let survey {
        renderSurvey(survey)
      } else {
        renderUnavailable()
      }
    }

    private func renderSurvey(_ survey: Survey) {
      let header = UIStackView()
      header.axis = .vertical
      header.alignment = .fill
      header.spacing = 8
      header.addArrangedSubview(
        UIKitComponentFactory.label(
          survey.title(for: activeLocale), textStyle: .largeTitle, weight: .bold))
      let description = survey.description(for: activeLocale)
      if !description.isEmpty {
        header.addArrangedSubview(UIKitComponentFactory.secondaryLabel(description))
      }
      contentStack.addArrangedSubview(header)

      for question in visibleQuestions {
        let questionView = UIKitQuestionView(
          client: client,
          question: question,
          choices: choicesByQuestion[question.id] ?? [],
          value: answers[question.id],
          locale: activeLocale,
          presentingViewController: self,
          ensureAuthenticated: { [weak self] in
            try await self?.ensureAuthenticated()
          },
          processImage: processImage,
          onChange: { [weak self] value, forceRender in
            self?.updateAnswer(
              questionId: question.id,
              value: value,
              forceRender: forceRender
            )
          }
        )
        contentStack.addArrangedSubview(questionView)
      }

      if let errorMessage {
        contentStack.addArrangedSubview(UIKitComponentFactory.errorLabel(errorMessage))
      }
      contentStack.addArrangedSubview(
        UIKitComponentFactory.primaryButton(
          title: FormContentMessages.text(activeLocale, "submit"),
          loadingTitle: FormContentMessages.text(activeLocale, "submitting"),
          isLoading: isSubmitting,
          action: { [weak self] in
            Task { await self?.submit() }
          }
        ))
    }

    private func renderFollowUp(_ followUp: FollowUp) {
      let header = UIStackView()
      header.axis = .vertical
      header.alignment = .fill
      header.spacing = 8
      header.addArrangedSubview(
        UIKitComponentFactory.label(
          FormContentMessages.text(activeLocale, "followUpTitle"),
          textStyle: .title2,
          weight: .bold
        ))
      header.addArrangedSubview(
        UIKitComponentFactory.secondaryLabel(
          FormContentMessages.text(activeLocale, "followUpSubtitle")))
      contentStack.addArrangedSubview(header)

      for item in followUp.items {
        contentStack.addArrangedSubview(
          UIKitFollowUpItemView(
            client: client,
            item: item,
            value: followUpAnswers[item.id],
            locale: activeLocale,
            presentingViewController: self,
            ensureAuthenticated: { [weak self] in
              try await self?.ensureAuthenticated()
            },
            processImage: processImage,
            onChange: { [weak self] value, forceRender in
              self?.followUpAnswers[item.id] = value
              if forceRender { self?.render() }
            }
          ))
      }

      if let errorMessage {
        contentStack.addArrangedSubview(UIKitComponentFactory.errorLabel(errorMessage))
      }
      contentStack.addArrangedSubview(
        UIKitComponentFactory.primaryButton(
          title: FormContentMessages.text(activeLocale, "followUpContinue"),
          loadingTitle: FormContentMessages.text(activeLocale, "followUpSubmitting"),
          isLoading: isSubmitting,
          action: { [weak self] in
            Task { await self?.submitFollowUp() }
          }
        ))
    }

    private func renderCompletion(_ survey: Survey) {
      let completion = UIStackView()
      completion.axis = .vertical
      completion.alignment = .center
      completion.spacing = 16
      completion.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 48, leading: 8, bottom: 24, trailing: 8)
      completion.isLayoutMarginsRelativeArrangement = true

      let imageView = UIImageView(
        image: UIImage(systemName: "checkmark.circle.fill")?.withConfiguration(
          UIImage.SymbolConfiguration(pointSize: 48)))
      imageView.tintColor = .systemGreen
      imageView.setContentHuggingPriority(.required, for: .horizontal)
      completion.addArrangedSubview(imageView)
      completion.addArrangedSubview(
        UIKitComponentFactory.label(
          FormContentMessages.text(activeLocale, "thankYou"),
          textStyle: .headline,
          weight: .semibold,
          alignment: .center
        ))
      completion.addArrangedSubview(
        UIKitComponentFactory.secondaryLabel(
          FormContentMessages.submittedWithTitle(
            activeLocale,
            title: survey.title(for: activeLocale)
          ),
          alignment: .center
        ))
      if let onDone {
        completion.addArrangedSubview(
          UIKitComponentFactory.primaryButton(
            title: FormContentMessages.text(activeLocale, "done"),
            action: onDone
          ))
      }
      contentStack.addArrangedSubview(completion)
    }

    private func renderUnavailable() {
      let unavailable = UIStackView()
      unavailable.axis = .vertical
      unavailable.alignment = .center
      unavailable.spacing = 12
      unavailable.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 48, leading: 8, bottom: 24, trailing: 8)
      unavailable.isLayoutMarginsRelativeArrangement = true

      let imageView = UIImageView(
        image: UIImage(systemName: "exclamationmark.triangle")?.withConfiguration(
          UIImage.SymbolConfiguration(pointSize: 42)))
      imageView.tintColor = .secondaryLabel
      unavailable.addArrangedSubview(imageView)
      unavailable.addArrangedSubview(
        UIKitComponentFactory.label(
          FormContentMessages.text(activeLocale, "surveyUnavailable"),
          textStyle: .headline,
          weight: .semibold,
          alignment: .center
        ))
      unavailable.addArrangedSubview(
        UIKitComponentFactory.secondaryLabel(
          errorMessage ?? FormContentMessages.text(activeLocale, "tryAgainLater"),
          alignment: .center
        ))
      contentStack.addArrangedSubview(unavailable)
    }

    private func updateAnswer(
      questionId: Int,
      value: SurveyAnswerValue,
      forceRender: Bool
    ) {
      let previousVisibleIds = visibleQuestions.map(\.id)
      var next = answers
      next[questionId] = value
      let nextVisibleQuestions = FormConciergeSurveyLogic.visibleQuestions(
        questions: questions,
        rules: visibilityRules,
        answers: next
      )
      let visibleIds = Set(nextVisibleQuestions.map(\.id))
      answers = next.filter { visibleIds.contains($0.key) }
      errorMessage = nil
      if forceRender || previousVisibleIds != nextVisibleQuestions.map(\.id) {
        render()
      }
    }

    private func submit() async {
      guard let survey else { return }
      if let validationError = FormConciergeSurveyLogic.validationError(
        questions: visibleQuestions,
        answers: answers,
        locale: activeLocale
      ) {
        errorMessage = validationError
        render()
        return
      }

      isSubmitting = true
      errorMessage = nil
      render()
      defer {
        isSubmitting = false
        render()
      }

      do {
        try await ensureAuthenticated()
        var captchaToken: String?
        if survey.captchaRequired {
          captchaToken = await captchaTokenProvider?()
          guard let captchaToken, !captchaToken.isEmpty else {
            errorMessage = FormContentMessages.text(activeLocale, "captchaRequired")
            return
          }
        }
        let response = try await client.submitResponse(
          surveyId: survey.id,
          answers: FormConciergeSurveyLogic.answerPayload(
            questions: visibleQuestions,
            answers: answers
          ),
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
          isCompleted = true
        }
      } catch {
        errorMessage = error.localizedDescription
      }
    }

    private func startFollowUp(responseId: Int) async {
      isGeneratingFollowUp = true
      render()
      defer {
        isGeneratingFollowUp = false
        render()
      }

      do {
        let result = try await client.generateFollowUp(
          responseId: responseId,
          locale: activeLocale
        )
        if result.needed, result.followUp.status == .pending, !result.followUp.items.isEmpty {
          followUp = result.followUp
          followUpAnswers = [:]
        } else {
          isCompleted = true
        }
      } catch {
        isCompleted = true
      }
    }

    private func submitFollowUp() async {
      guard let responseId = submittedResponse?.id, let followUp else {
        isCompleted = true
        render()
        return
      }

      isSubmitting = true
      errorMessage = nil
      render()
      defer {
        isSubmitting = false
        render()
      }

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
        isCompleted = true
        onFollowUpSubmitted?(response)
      } catch {
        errorMessage = error.localizedDescription
      }
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

    private var activeLocale: String {
      normalizeFormContentLocale(
        locale ?? project?.defaultLocale ?? defaultFormContentLocale
      )
    }
  }
#endif
