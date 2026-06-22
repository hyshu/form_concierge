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

  func testReplyCheckerPersistsAndClearsSeenTimestamp() async throws {
    let latest = "2026-06-22T10:15:30Z"
    let defaults = makeDefaults()
    let client = makeClient { _ in
      self.jsonResponse(["latestReplyAt": latest])
    }
    let checker = FormConciergeReplyChecker(
      client: client,
      anonymousToken: "anon-token",
      responseId: 9,
      userDefaults: defaults
    )

    let first = try await checker.check()
    XCTAssertTrue(first.hasNewReplies)
    XCTAssertNil(checker.lastSeenReplyAt)

    let marked = try await checker.check(markSeen: true)
    XCTAssertTrue(marked.hasNewReplies)
    XCTAssertEqual(checker.lastSeenReplyAt, ISO8601DateFormatter().date(from: latest))

    let afterMark = try await checker.check()
    XCTAssertFalse(afterMark.hasNewReplies)

    checker.clearSeen()
    XCTAssertNil(checker.lastSeenReplyAt)
  }

  func testReplyCheckerStorageKeyDoesNotExposeRawToken() {
    let key = FormConciergeReplyChecker.defaultStorageKey(
      anonymousToken: "secret-token",
      responseId: 12
    )

    XCTAssertTrue(key.contains("response_12"))
    XCTAssertFalse(key.contains("secret-token"))
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

  private func jsonBody(_ request: URLRequest) throws -> [String: Any]? {
    let body: Data?
    if let httpBody = request.httpBody {
      body = httpBody
    } else if let stream = request.httpBodyStream {
      stream.open()
      defer { stream.close() }
      var data = Data()
      var buffer = [UInt8](repeating: 0, count: 1024)
      while stream.hasBytesAvailable {
        let read = stream.read(&buffer, maxLength: buffer.count)
        if read <= 0 { break }
        data.append(buffer, count: read)
      }
      body = data
    } else {
      body = nil
    }
    guard let body else { return nil }
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
        "nameTranslations": ["en": "Customer feedback", "ja": "顧客フィードバック"],
        "descriptionTranslations": ["en": "", "ja": ""],
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
