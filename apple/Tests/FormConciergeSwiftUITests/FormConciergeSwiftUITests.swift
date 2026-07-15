import Foundation
import XCTest

@testable import FormConciergeSwiftUI

final class FormConciergeSwiftUITests: XCTestCase {
  func testNormalizeFormContentLocaleHandlesCommonRegionTags() {
    XCTAssertEqual(normalizeFormContentLocale("ja_JP"), "ja")
    XCTAssertEqual(normalizeFormContentLocale("zh_CN"), "zh-Hans")
    XCTAssertEqual(normalizeFormContentLocale("zh_TW"), "zh-Hant")
    XCTAssertEqual(normalizeFormContentLocale("ko_KR"), "ko")
    XCTAssertEqual(normalizeFormContentLocale("de_DE"), "de")
    XCTAssertEqual(normalizeFormContentLocale("es_ES"), "es")
    XCTAssertEqual(normalizeFormContentLocale("fr_FR"), "fr")
    XCTAssertEqual(normalizeFormContentLocale("it_IT"), "it")
    XCTAssertEqual(normalizeFormContentLocale("th_TH"), "th")
    XCTAssertEqual(normalizeFormContentLocale("tr_TR"), "tr")
  }

  func testVisibilityRuleValueAccessorsRejectCoercion() {
    XCTAssertEqual(VisibilityRuleValue.int(7).intValue, 7)
    XCTAssertNil(VisibilityRuleValue.string("7").intValue)
    XCTAssertNil(VisibilityRuleValue.double(7).intValue)

    XCTAssertEqual(VisibilityRuleValue.string("ready").stringValue, "ready")
    XCTAssertNil(VisibilityRuleValue.int(7).stringValue)
    XCTAssertNil(VisibilityRuleValue.bool(true).stringValue)
    XCTAssertNil(VisibilityRuleValue.null.stringValue)
  }

  func testAdminReplyCheckStatusDetectsNewReplies() {
    let latest = Date(timeIntervalSince1970: 100)

    XCTAssertFalse(AdminReplyCheckStatus(latestReplyAt: nil, lastSeenReplyAt: nil).hasNewReplies)
    XCTAssertTrue(AdminReplyCheckStatus(latestReplyAt: latest, lastSeenReplyAt: nil).hasNewReplies)
    XCTAssertTrue(
      AdminReplyCheckStatus(
        latestReplyAt: latest,
        lastSeenReplyAt: latest.addingTimeInterval(-1)
      ).hasNewReplies
    )
    XCTAssertFalse(
      AdminReplyCheckStatus(latestReplyAt: latest, lastSeenReplyAt: latest).hasNewReplies)
    XCTAssertFalse(
      AdminReplyCheckStatus(
        latestReplyAt: latest,
        lastSeenReplyAt: latest.addingTimeInterval(1)
      ).hasNewReplies
    )
  }

  func testLatestReplyAtUsesBearerTokenAndResponseQuery() async throws {
    let client = makeClient { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/anonymous/replies/latest")
      XCTAssertEqual(request.url?.query, "responseId=42")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer anon-token")
      return self.jsonResponse(["latestReplyAt": "2026-06-22T10:15:30Z"])
    }

    await client.setAnonymousToken("anon-token")
    let latestReplyAt = try await client.latestReplyAt(responseId: 42)

    XCTAssertEqual(latestReplyAt, ISO8601DateFormatter().date(from: "2026-06-22T10:15:30Z"))
  }

  func testDecodesFractionalISO8601DatesFromWorker() async throws {
    let client = makeClient { request in
      XCTAssertEqual(request.url?.path, "/api/anonymous/replies/latest")
      return self.jsonResponse(["latestReplyAt": "2026-06-22T10:15:30.123Z"])
    }

    await client.setAnonymousToken("anon-token")
    let latestReplyAt = try await client.latestReplyAt()

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    XCTAssertEqual(latestReplyAt, formatter.date(from: "2026-06-22T10:15:30.123Z"))
  }

  func testCreateAnonymousAccountStoresTokenAndSendsDisplayName() async throws {
    let client = makeClient { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/anonymous/accounts")
      let body = try XCTUnwrap(self.jsonBody(request))
      XCTAssertEqual(body["displayName"] as? String, "Respondent")
      return self.jsonResponse([
        "account": self.anonymousAccountJson(),
        "token": "created-token",
      ])
    }

    let session = try await client.createAnonymousAccount(displayName: "Respondent")
    let hasToken = await client.hasAnonymousToken()

    XCTAssertEqual(session.token, "created-token")
    XCTAssertTrue(hasToken)
  }

  func testProjectByDomainEncodesHostQuery() async throws {
    let client = makeClient { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/projects/domain")
      XCTAssertEqual(request.url?.query, "host=forms.example.com")
      return self.jsonResponse(self.projectJson())
    }

    let project = try await client.project(domain: "forms.example.com")

    XCTAssertEqual(project.project.slug, "customer-feedback")
    XCTAssertEqual(project.project.customDomain, "forms.example.com")
    XCTAssertEqual(project.surveys.first?.projectId, 1)
  }

  func testPublicConfigLoadsTurnstileSiteKey() async throws {
    let client = makeClient { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/config")
      return self.jsonResponse([
        "passwordResetEnabled": false,
        "requireEmailVerification": false,
        "aiGenerationEnabled": true,
        "turnstileSiteKey": "site-key",
      ])
    }

    let config = try await client.publicConfig()

    XCTAssertTrue(config.aiGenerationEnabled)
    XCTAssertEqual(config.turnstileSiteKey, "site-key")
  }

  func testCaptchaRequiredOverridesPersistedCaptchaSetting() async throws {
    var payload = projectJson()
    var survey = surveyJson()
    survey["captchaEnabled"] = true
    survey["captchaRequired"] = false
    payload["surveys"] = [survey]
    let client = makeClient { _ in self.jsonResponse(payload) }

    let project = try await client.project(slug: "customer-feedback")

    XCTAssertFalse(try XCTUnwrap(project.surveys.first).captchaRequired)
  }

  func testRepliesUsesBearerTokenAndResponseQuery() async throws {
    let client = makeClient { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/anonymous/replies")
      XCTAssertEqual(request.url?.query, "responseId=77")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer anon-token")
      return self.jsonResponse([
        [
          "id": 1,
          "surveyResponseId": 77,
          "anonymousAccountId": "anon-1",
          "adminId": "admin-1",
          "body": "Thanks",
          "createdAt": "2026-06-22T10:15:30Z",
          "readAt": NSNull(),
        ]
      ])
    }

    await client.setAnonymousToken("anon-token")
    let replies = try await client.replies(responseId: 77)

    XCTAssertEqual(replies.count, 1)
    XCTAssertEqual(replies.first?.body, "Thanks")
  }

  func testLatestReplyAtDecodesNoReply() async throws {
    let client = makeClient { _ in
      self.jsonResponse(["latestReplyAt": nil])
    }

    await client.setAnonymousToken("anon-token")
    let latestReplyAt = try await client.latestReplyAt()

    XCTAssertNil(latestReplyAt)
  }

  func testSubmitResponseCreatesAnonymousSessionWhenMissingAndPostsWithCreatedToken() async throws {
    var paths: [String] = []
    let client = makeClient { request in
      paths.append("\(request.httpMethod ?? "") \(request.url?.path ?? "")")
      if request.url?.path == "/api/anonymous/accounts" {
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        return self.jsonResponse([
          "account": self.anonymousAccountJson(),
          "token": "created-token",
        ])
      }

      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/surveys/id/1/responses")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer created-token")
      let body = try XCTUnwrap(self.jsonBody(request))
      let answers = try XCTUnwrap(body["answers"] as? [[String: Any]])
      XCTAssertEqual(answers.first?["questionId"] as? Int, 10)
      XCTAssertEqual(answers.first?["textValue"] as? String, "Hello")
      let metadata = try XCTUnwrap(body["metadata"] as? [String: Any])
      XCTAssertEqual(metadata["plan"] as? String, "pro")
      return self.jsonResponse(self.responseJson())
    }

    let response = try await client.submitResponse(
      surveyId: 1,
      answers: [Answer(questionId: 10, textValue: "Hello")],
      deviceInfo: DeviceInfo(label: "iPhone", platform: "ios"),
      metadata: ["plan": "pro"]
    )
    let hasToken = await client.hasAnonymousToken()

    XCTAssertEqual(
      paths,
      [
        "POST /api/anonymous/accounts",
        "POST /api/surveys/id/1/responses",
      ])
    XCTAssertEqual(response.id, 99)
    XCTAssertTrue(hasToken)
  }

  func testUploadMediaPostsRawBytesWithAnonymousBearer() async throws {
    let imageBytes = Data([0xff, 0xd8, 0xff, 0xd9])
    var paths: [String] = []
    let client = makeClient { request in
      paths.append("\(request.httpMethod ?? "") \(request.url?.path ?? "")")
      if request.url?.path == "/api/anonymous/accounts" {
        return self.jsonResponse([
          "account": self.anonymousAccountJson(),
          "token": "media-token",
        ])
      }
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/media")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer media-token")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "image/jpeg")
      // URLProtocol may surface body via stream rather than httpBody.
      XCTAssertEqual(self.requestBodyData(request), imageBytes)
      return self.jsonResponse([
        "key": "uploads/anon-1/photo.jpg",
        "contentType": "image/jpeg",
        "size": imageBytes.count,
      ])
    }

    let uploaded = try await client.uploadMedia(data: imageBytes, contentType: "image/jpeg")
    XCTAssertEqual(uploaded.key, "uploads/anon-1/photo.jpg")
    XCTAssertEqual(uploaded.size, imageBytes.count)
    XCTAssertEqual(
      paths,
      [
        "POST /api/anonymous/accounts",
        "POST /api/media",
      ])
  }

  func testGenerateFollowUpPostsLocaleAndDecodesItems() async throws {
    let client = makeClient { request in
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(request.url?.path, "/api/responses/99/follow-up/generate")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer anon-token")
      XCTAssertEqual(try XCTUnwrap(self.jsonBody(request))["locale"] as? String, "ja")
      return self.jsonResponse([
        "needed": true,
        "followUp": self.followUpJson(status: "pending"),
        "error": nil,
      ])
    }
    await client.setAnonymousToken("anon-token")

    let result = try await client.generateFollowUp(responseId: 99, locale: "ja")

    XCTAssertTrue(result.needed)
    XCTAssertEqual(result.followUp.status, .pending)
    XCTAssertEqual(result.followUp.items.first?.text, "もう少し詳しく教えてください")
  }

  func testSaveFollowUpEncodesAnswersAndDecodesCompletedResponse() async throws {
    let client = makeClient { request in
      XCTAssertEqual(request.httpMethod, "PUT")
      XCTAssertEqual(request.url?.path, "/api/responses/99/follow-up")
      XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer anon-token")
      let body = try XCTUnwrap(self.jsonBody(request))
      let answers = try XCTUnwrap(body["answers"] as? [[String: Any]])
      XCTAssertEqual(answers.first?["id"] as? String, "detail")
      XCTAssertEqual(answers.first?["textValue"] as? String, "詳しい内容")
      var response = self.responseJson()
      response["followUp"] = self.followUpJson(status: "completed")
      return self.jsonResponse(response)
    }
    await client.setAnonymousToken("anon-token")

    let response = try await client.saveFollowUp(
      responseId: 99,
      answers: [FollowUpSubmissionAnswer(id: "detail", textValue: "詳しい内容")]
    )

    XCTAssertEqual(response.followUp?.status, .completed)
    XCTAssertEqual(response.replyCount, 0)
  }

  func testSubmitResponseEncodesImageFileKeys() async throws {
    let client = makeClient { request in
      if request.url?.path == "/api/anonymous/accounts" {
        return self.jsonResponse([
          "account": self.anonymousAccountJson(),
          "token": "created-token",
        ])
      }
      let body = try XCTUnwrap(self.jsonBody(request))
      let answers = try XCTUnwrap(body["answers"] as? [[String: Any]])
      XCTAssertEqual(answers.first?["questionId"] as? Int, 11)
      XCTAssertEqual(answers.first?["fileKeys"] as? [String], ["uploads/anon-1/a.jpg"])
      XCTAssertNil(answers.first?["textValue"] as? String)
      return self.jsonResponse(self.responseJson())
    }

    _ = try await client.submitResponse(
      surveyId: 1,
      answers: [Answer(questionId: 11, fileKeys: ["uploads/anon-1/a.jpg"])]
    )
  }

  func testApiErrorsUseServerMessage() async throws {
    let client = makeClient { _ in
      let data = try! JSONSerialization.data(withJSONObject: ["error": "Forbidden"])
      let response = HTTPURLResponse(
        url: URL(string: "https://api.example.com/api/anonymous/replies/latest")!,
        statusCode: 403,
        httpVersion: nil,
        headerFields: ["content-type": "application/json"]
      )!
      return (response, data)
    }

    await client.setAnonymousToken("anon-token")

    do {
      _ = try await client.latestReplyAt()
      XCTFail("Expected API error")
    } catch FormConciergeError.api(let status, let message) {
      XCTAssertEqual(status, 403)
      XCTAssertEqual(message, "Forbidden")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testApiErrorsFallBackWhenBodyLacksServerErrorMessage() async throws {
    let client = makeClient { _ in
      let data = try! JSONSerialization.data(withJSONObject: ["message": "Forbidden"])
      let response = HTTPURLResponse(
        url: URL(string: "https://api.example.com/api/anonymous/replies/latest")!,
        statusCode: 403,
        httpVersion: nil,
        headerFields: ["content-type": "application/json"]
      )!
      return (response, data)
    }

    await client.setAnonymousToken("anon-token")

    do {
      _ = try await client.latestReplyAt()
      XCTFail("Expected API error")
    } catch FormConciergeError.api(let status, let message) {
      XCTAssertEqual(status, 403)
      XCTAssertEqual(message, "Request failed with status 403")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testApiErrorsFallBackOnNonJSONErrorBodies() async throws {
    let client = makeClient { _ in
      let data = Data("<html>Bad Gateway</html>".utf8)
      let response = HTTPURLResponse(
        url: URL(string: "https://api.example.com/api/anonymous/replies/latest")!,
        statusCode: 502,
        httpVersion: nil,
        headerFields: ["content-type": "text/html"]
      )!
      return (response, data)
    }

    await client.setAnonymousToken("anon-token")

    do {
      _ = try await client.latestReplyAt()
      XCTFail("Expected API error")
    } catch FormConciergeError.api(let status, let message) {
      XCTAssertEqual(status, 502)
      XCTAssertEqual(message, "Request failed with status 502")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testReplyCheckerPersistsAndClearsSeenTimestamp() async throws {
    let latest = "2026-06-22T10:15:30.500Z"
    let client = makeClient { _ in
      self.jsonResponse(["latestReplyAt": latest])
    }
    let checker = FormConciergeReplyChecker(
      client: client,
      anonymousToken: "anon-token",
      store: .memory(),
      responseId: 9
    )

    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let expected = fractional.date(from: latest)

    let first = try await checker.check()
    XCTAssertTrue(first.hasNewReplies)
    XCTAssertNil(checker.lastSeenReplyAt)

    let marked = try await checker.check(markSeen: true)
    XCTAssertTrue(marked.hasNewReplies)
    XCTAssertEqual(checker.lastSeenReplyAt, expected)

    let afterMark = try await checker.check()
    XCTAssertFalse(afterMark.hasNewReplies)

    checker.clearSeen()
    XCTAssertNil(checker.lastSeenReplyAt)
  }

  func testReplyCheckerCanUseHostUserDefaultsStore() async throws {
    let latest = "2026-06-22T10:15:30.500Z"
    let defaults = makeDefaults()
    let client = makeClient { _ in
      self.jsonResponse(["latestReplyAt": latest])
    }
    let checker = FormConciergeReplyChecker(
      client: client,
      anonymousToken: "anon-token",
      store: .userDefaults(defaults),
      responseId: 3
    )

    _ = try await checker.check(markSeen: true)
    XCTAssertNotNil(checker.lastSeenReplyAt)
    let key = FormConciergeReplyChecker.defaultStorageKey(
      anonymousToken: "anon-token",
      responseId: 3
    )
    XCTAssertNotNil(defaults.string(forKey: key))
  }

  func testReplyCheckerStorageKeyDoesNotExposeRawToken() {
    let key = FormConciergeReplyChecker.defaultStorageKey(
      anonymousToken: "secret-token",
      responseId: 12
    )

    XCTAssertTrue(key.contains("response_12"))
    XCTAssertFalse(key.contains("secret-token"))
  }

  func testSurveyLogicSharesVisibilityBehaviorAcrossAppleUIs() {
    let source = makeQuestion(id: 1, type: .singleChoice)
    let target = makeQuestion(id: 2, type: .textSingle)
    let rule = QuestionVisibilityRule(
      id: 10,
      surveyId: 1,
      targetQuestionId: 2,
      sourceQuestionId: 1,
      operator: .equals,
      value: .int(7),
      createdAt: nil,
      updatedAt: nil
    )

    XCTAssertEqual(
      FormConciergeSurveyLogic.visibleQuestions(
        questions: [source, target],
        rules: [rule],
        answers: [:]
      ).map(\.id),
      [1]
    )
    XCTAssertEqual(
      FormConciergeSurveyLogic.visibleQuestions(
        questions: [source, target],
        rules: [rule],
        answers: [1: .single(7)]
      ).map(\.id),
      [1, 2]
    )
  }

  func testSurveyLogicSharesValidationAndPayloadAcrossAppleUIs() {
    let question = makeQuestion(
      id: 1,
      type: .textSingle,
      isRequired: true,
      minLength: 3
    )

    XCTAssertNotNil(
      FormConciergeSurveyLogic.validationError(
        questions: [question],
        answers: [1: .text("ab")],
        locale: "en"
      ))
    let payload = FormConciergeSurveyLogic.answerPayload(
      questions: [question],
      answers: [1: .text("  hello  ")]
    )
    XCTAssertEqual(payload.count, 1)
    XCTAssertEqual(payload.first?.textValue, "hello")
  }

  func testSurveyLogicValidatesSingleChoiceMinimumSelection() {
    let question = makeQuestion(
      id: 1,
      type: .singleChoice,
      minSelected: 1
    )

    XCTAssertNotNil(
      FormConciergeSurveyLogic.validationError(
        questions: [question],
        answers: [:],
        locale: "en"
      ))
    XCTAssertNil(
      FormConciergeSurveyLogic.validationError(
        questions: [question],
        answers: [1: .single(10)],
        locale: "en"
      ))
  }

  private func makeClient(
    handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
  ) -> FormConciergeClient {
    MockURLProtocol.handler = handler
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)
    return FormConciergeClient(
      baseURL: URL(string: "https://api.example.com")!,
      session: session
    )
  }

  private func makeQuestion(
    id: Int,
    type: QuestionType,
    isRequired: Bool = false,
    minLength: Int? = nil,
    minSelected: Int? = nil
  ) -> Question {
    Question(
      id: id,
      surveyId: 1,
      textTranslations: LocalizedText(["en": "Question \(id)"]),
      type: type,
      orderIndex: id,
      isRequired: isRequired,
      placeholderTranslations: LocalizedText(["en": ""]),
      minLength: minLength,
      maxLength: nil,
      minSelected: minSelected,
      maxSelected: nil,
      visibilityConditionMode: .all
    )
  }

  private func makeDefaults() -> UserDefaults {
    let suiteName = "FormConciergeSwiftUITests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }

  private func jsonResponse(_ body: [String: Any?]) -> (HTTPURLResponse, Data) {
    let data = try! JSONSerialization.data(
      withJSONObject: body.mapValues { $0 ?? NSNull() }
    )
    let response = HTTPURLResponse(
      url: URL(string: "https://api.example.com/api/anonymous/replies/latest")!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: ["content-type": "application/json"]
    )!
    return (response, data)
  }

  private func jsonResponse(_ body: [[String: Any?]]) -> (HTTPURLResponse, Data) {
    let normalized = body.map { row in
      row.mapValues { $0 ?? NSNull() }
    }
    let data = try! JSONSerialization.data(withJSONObject: normalized)
    let response = HTTPURLResponse(
      url: URL(string: "https://api.example.com")!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: ["content-type": "application/json"]
    )!
    return (response, data)
  }

  private func requestBodyData(_ request: URLRequest) -> Data? {
    if let httpBody = request.httpBody {
      return httpBody
    }
    guard let stream = request.httpBodyStream else { return nil }
    stream.open()
    defer { stream.close() }
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 1024)
    while stream.hasBytesAvailable {
      let read = stream.read(&buffer, maxLength: buffer.count)
      if read <= 0 { break }
      data.append(buffer, count: read)
    }
    return data
  }

  private func jsonBody(_ request: URLRequest) throws -> [String: Any]? {
    guard let body = requestBodyData(request) else { return nil }
    return try JSONSerialization.jsonObject(with: body) as? [String: Any]
  }

  private func anonymousAccountJson() -> [String: Any?] {
    [
      "id": "anon-1",
      "displayName": "Respondent",
      "createdAt": "2026-06-22T10:00:00Z",
      "lastSeenAt": "2026-06-22T10:00:00Z",
    ]
  }

  private func surveyJson() -> [String: Any?] {
    [
      "id": 1,
      "projectId": 1,
      "slug": "customer-feedback",
      "titleTranslations": ["en": "Customer feedback", "ja": "顧客フィードバック"],
      "descriptionTranslations": ["en": "Tell us", "ja": "ご意見をお聞かせください"],
      "status": "published",
      "webEnabled": true,
      "createdAt": "2026-06-22T10:00:00Z",
      "updatedAt": "2026-06-22T10:00:00Z",
    ]
  }

  private func projectJson() -> [String: Any?] {
    [
      "project": [
        "id": 1,
        "slug": "customer-feedback",
        "customDomain": "forms.example.com",
        "defaultLocale": "en",
        "supportedLocales": ["en", "ja"],
        "name": "Customer feedback",
        "createdAt": "2026-06-22T10:00:00Z",
        "updatedAt": "2026-06-22T10:00:00Z",
      ],
      "surveys": [surveyJson()],
    ]
  }

  private func responseJson() -> [String: Any?] {
    [
      "id": 99,
      "surveyId": 1,
      "anonymousId": "anon-1",
      "anonymousAccountId": "anon-1",
      "submittedAt": "2026-06-22T10:02:00Z",
      "deviceInfo": NSNull(),
      "metadata": NSNull(),
    ]
  }

  private func followUpJson(status: String) -> [String: Any?] {
    [
      "version": 1,
      "status": status,
      "generatedAt": "2026-06-22T10:03:00Z",
      "completedAt": status == "completed" ? "2026-06-22T10:04:00Z" : nil,
      "locale": "ja",
      "items": [
        [
          "id": "detail",
          "type": "textMultiLine",
          "text": "もう少し詳しく教えてください",
          "required": false,
          "placeholder": "詳細",
          "maxFiles": nil,
          "choices": [],
          "answer": status == "completed"
            ? ["textValue": "詳しい内容", "selectedChoiceIds": [], "fileKeys": []]
            : nil,
        ]
      ],
    ]
  }
}

final class MockURLProtocol: URLProtocol {
  static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let handler = Self.handler else {
      XCTFail("MockURLProtocol.handler is not set")
      return
    }

    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
