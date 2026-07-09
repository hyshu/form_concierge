import Foundation

public actor FormConciergeClient {
  public let baseURL: URL
  private var anonymousToken: String?
  private let session: URLSession
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder

  private static let fractionalISO8601: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let plainISO8601: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  public init(baseURL: URL, session: URLSession = .shared) {
    self.baseURL = baseURL
    self.session = session
    self.decoder = JSONDecoder()
    // Worker emits fractional seconds (toISOString / SQLite %f). Foundation's
    // .iso8601 strategy rejects those strings, so decode with a fractional-aware
    // formatter and fall back to whole-second ISO-8601.
    self.decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let value = try container.decode(String.self)
      if let date = Self.fractionalISO8601.date(from: value)
        ?? Self.plainISO8601.date(from: value)
      {
        return date
      }
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid ISO-8601 date: \(value)"
      )
    }
    self.encoder = JSONEncoder()
    self.encoder.dateEncodingStrategy = .iso8601
  }

  public func setAnonymousToken(_ token: String?) {
    anonymousToken = token
  }

  public func hasAnonymousToken() -> Bool {
    anonymousToken != nil
  }

  @discardableResult
  public func createAnonymousAccount(displayName: String? = nil) async throws -> AnonymousSession {
    let created: AnonymousSession = try await request(
      "POST",
      "/api/anonymous/accounts",
      body: ["displayName": displayName]
    )
    anonymousToken = created.token
    return created
  }

  public func project(slug: String) async throws -> PublicProject {
    let encoded = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? slug
    do {
      return try await request("GET", "/api/projects/\(encoded)")
    } catch FormConciergeError.api(let status, _) where status == 404 {
      throw FormConciergeError.notFound
    }
  }

  public func project(domain: String) async throws -> PublicProject {
    let encodedDomain =
      domain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? domain
    let project: PublicProject? = try await request(
      "GET", "/api/projects/domain?host=\(encodedDomain)")
    guard let project else { throw FormConciergeError.notFound }
    return project
  }

  public func questions(surveyId: Int) async throws -> [Question] {
    try await request("GET", "/api/surveys/id/\(surveyId)/questions")
  }

  public func choices(questionId: Int) async throws -> [Choice] {
    try await request("GET", "/api/questions/\(questionId)/choices")
  }

  public func visibilityRules(surveyId: Int) async throws -> [QuestionVisibilityRule] {
    try await request("GET", "/api/surveys/id/\(surveyId)/visibility-rules")
  }

  public func submitResponse(
    surveyId: Int,
    answers: [Answer],
    deviceInfo: DeviceInfo? = nil,
    metadata: [String: FormConciergeMetadataValue]? = nil
  ) async throws -> SurveyResponse {
    if anonymousToken == nil {
      _ = try await createAnonymousAccount()
    }
    return try await request(
      "POST",
      "/api/surveys/id/\(surveyId)/responses",
      body: SubmitResponsePayload(
        answers: answers,
        deviceInfo: deviceInfo ?? .current,
        metadata: metadata
      ),
      bearerToken: anonymousToken
    )
  }

  public func replies(responseId: Int? = nil) async throws -> [AdminReply] {
    var path = "/api/anonymous/replies"
    if let responseId {
      path += "?responseId=\(responseId)"
    }
    return try await request("GET", path, bearerToken: anonymousToken)
  }

  public func latestReplyAt(responseId: Int? = nil) async throws -> Date? {
    var path = "/api/anonymous/replies/latest"
    if let responseId {
      path += "?responseId=\(responseId)"
    }
    let payload: LatestReplyPayload = try await request("GET", path, bearerToken: anonymousToken)
    return payload.latestReplyAt
  }

  private func request<T: Decodable>(
    _ method: String,
    _ path: String,
    body: Encodable? = nil,
    bearerToken: String? = nil
  ) async throws -> T {
    var request = URLRequest(url: try resolveURL(path))
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    if let bearerToken {
      request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
    }
    if let body {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try encoder.encode(AnyEncodable(body))
    }

    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw FormConciergeError.invalidResponse
    }
    if !(200..<300).contains(http.statusCode) {
      // Proxy HTML 502s and other non-JSON bodies must not become DecodingError
      // (which drops status/message). Match the Dart client's ApiException fallback.
      if let payload = try? decoder.decode(APIErrorPayload.self, from: data),
         !payload.error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        throw FormConciergeError.api(
          status: http.statusCode,
          message: payload.error
        )
      }
      throw FormConciergeError.api(
        status: http.statusCode,
        message: "Request failed with status \(http.statusCode)"
      )
    }
    return try decoder.decode(T.self, from: data)
  }

  /// Join path onto baseURL without dropping a base path prefix.
  /// `URL(string:relativeTo:)` treats a leading `/` as host-absolute and would
  /// discard e.g. `https://host/prefix` when path is `/api/...`.
  private func resolveURL(_ path: String) throws -> URL {
    var base = baseURL.absoluteString
    if base.hasSuffix("/") {
      base = String(base.dropLast())
    }
    let suffix = path.hasPrefix("/") ? path : "/\(path)"
    guard let url = URL(string: base + suffix) else {
      throw FormConciergeError.invalidResponse
    }
    return url
  }
}

private struct APIErrorPayload: Decodable {
  let error: String
}

private struct SubmitResponsePayload: Encodable {
  let answers: [Answer]
  let deviceInfo: DeviceInfo?
  let metadata: [String: FormConciergeMetadataValue]?
}

private struct LatestReplyPayload: Decodable {
  let latestReplyAt: Date?
}

private struct AnyEncodable: Encodable {
  private let encodeBody: (Encoder) throws -> Void

  init(_ wrapped: Encodable) {
    self.encodeBody = wrapped.encode
  }

  func encode(to encoder: Encoder) throws {
    try encodeBody(encoder)
  }
}
