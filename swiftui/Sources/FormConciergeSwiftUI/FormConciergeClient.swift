import Foundation

public actor FormConciergeClient {
  public let baseURL: URL
  private var anonymousToken: String?
  private let session: URLSession
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder

  public init(baseURL: URL, session: URLSession = .shared) {
    self.baseURL = baseURL
    self.session = session
    self.decoder = JSONDecoder()
    self.decoder.dateDecodingStrategy = .iso8601
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

  public func survey(slug: String) async throws -> Survey {
    let survey: Survey? = try await request("GET", "/api/surveys/\(slug)")
    guard let survey else { throw FormConciergeError.notFound }
    return survey
  }

  public func questions(surveyId: Int) async throws -> [Question] {
    try await request("GET", "/api/surveys/id/\(surveyId)/questions")
  }

  public func choices(questionId: Int) async throws -> [Choice] {
    try await request("GET", "/api/questions/\(questionId)/choices")
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

  private func request<T: Decodable>(
    _ method: String,
    _ path: String,
    body: Encodable? = nil,
    bearerToken: String? = nil
  ) async throws -> T {
    var request = URLRequest(url: URL(string: path, relativeTo: baseURL)!)
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
      let payload = try? decoder.decode(APIErrorPayload.self, from: data)
      throw FormConciergeError.api(
        status: http.statusCode,
        message: payload?.error ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
      )
    }
    return try decoder.decode(T.self, from: data)
  }
}

private struct APIErrorPayload: Decodable {
  let error: String?
}

private struct SubmitResponsePayload: Encodable {
  let answers: [Answer]
  let deviceInfo: DeviceInfo?
  let metadata: [String: FormConciergeMetadataValue]?
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
