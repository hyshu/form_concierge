import Foundation

#if canImport(UIKit)
  import UIKit
#endif
#if canImport(AppKit)
  import AppKit
#endif

public enum QuestionType: String, Codable, Sendable {
  case singleChoice
  case multipleChoice
  case textSingle
  case textMultiLine
}

public enum SurveyStatus: String, Codable, Sendable {
  case draft
  case published
  case closed
  case archived
}

public struct Survey: Codable, Identifiable, Sendable {
  public let id: Int
  public let slug: String
  public let title: String
  public let description: String?
  public let status: SurveyStatus
  public let createdAt: Date
  public let updatedAt: Date
}

public struct Question: Codable, Identifiable, Sendable {
  public let id: Int
  public let surveyId: Int
  public let text: String
  public let type: QuestionType
  public let orderIndex: Int
  public let isRequired: Bool
  public let placeholder: String?
  public let minLength: Int?
  public let maxLength: Int?
}

public struct Choice: Codable, Identifiable, Sendable {
  public let id: Int
  public let questionId: Int
  public let text: String
  public let orderIndex: Int
  public let value: String?
}

public struct Answer: Codable, Sendable {
  public let surveyResponseId: Int
  public let questionId: Int
  public let textValue: String?
  public let selectedChoiceIds: [Int]?

  public init(questionId: Int, textValue: String? = nil, selectedChoiceIds: [Int]? = nil) {
    self.surveyResponseId = 0
    self.questionId = questionId
    self.textValue = textValue
    self.selectedChoiceIds = selectedChoiceIds
  }
}

public struct SurveyResponse: Codable, Identifiable, Sendable {
  public let id: Int
  public let surveyId: Int
  public let anonymousId: String?
  public let anonymousAccountId: String?
  public let submittedAt: Date
  public let deviceInfo: DeviceInfo?
  public let metadata: [String: FormConciergeMetadataValue]?
}

public enum FormConciergeMetadataValue: Codable, Sendable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case object([String: FormConciergeMetadataValue])
  case array([FormConciergeMetadataValue])
  case null

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(Double.self) {
      self = .number(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode([FormConciergeMetadataValue].self) {
      self = .array(value)
    } else {
      self = .object(try container.decode([String: FormConciergeMetadataValue].self))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let value):
      try container.encode(value)
    case .number(let value):
      try container.encode(value)
    case .bool(let value):
      try container.encode(value)
    case .object(let value):
      try container.encode(value)
    case .array(let value):
      try container.encode(value)
    case .null:
      try container.encodeNil()
    }
  }
}

extension FormConciergeMetadataValue: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}

extension FormConciergeMetadataValue: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self = .number(Double(value))
  }
}

extension FormConciergeMetadataValue: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) {
    self = .number(value)
  }
}

extension FormConciergeMetadataValue: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

extension FormConciergeMetadataValue: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: FormConciergeMetadataValue...) {
    self = .array(elements)
  }
}

extension FormConciergeMetadataValue: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (String, FormConciergeMetadataValue)...) {
    self = .object(Dictionary(uniqueKeysWithValues: elements))
  }
}

public struct DeviceInfo: Codable, Sendable {
  public let deviceId: String?
  public let label: String?
  public let platform: String?
  public let os: String?
  public let osVersion: String?
  public let browser: String?
  public let browserVersion: String?
  public let appVersion: String?
  public let appBuild: String?
  public let model: String?
  public let manufacturer: String?
  public let locale: String?
  public let timezone: String?
  public let screenWidth: Int?
  public let screenHeight: Int?
  public let devicePixelRatio: Double?
  public let userAgent: String?

  public init(
    deviceId: String? = nil,
    label: String? = nil,
    platform: String? = nil,
    os: String? = nil,
    osVersion: String? = nil,
    browser: String? = nil,
    browserVersion: String? = nil,
    appVersion: String? = nil,
    appBuild: String? = nil,
    model: String? = nil,
    manufacturer: String? = nil,
    locale: String? = nil,
    timezone: String? = nil,
    screenWidth: Int? = nil,
    screenHeight: Int? = nil,
    devicePixelRatio: Double? = nil,
    userAgent: String? = nil
  ) {
    self.deviceId = deviceId
    self.label = label
    self.platform = platform
    self.os = os
    self.osVersion = osVersion
    self.browser = browser
    self.browserVersion = browserVersion
    self.appVersion = appVersion
    self.appBuild = appBuild
    self.model = model
    self.manufacturer = manufacturer
    self.locale = locale
    self.timezone = timezone
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    self.devicePixelRatio = devicePixelRatio
    self.userAgent = userAgent
  }

  public static var current: DeviceInfo {
    var label: String?
    var platform = "swiftui"
    var os: String?
    var osVersion = ProcessInfo.processInfo.operatingSystemVersionString
    var screenWidth: Int?
    var screenHeight: Int?
    var scale: Double?

    #if canImport(UIKit)
      let device = UIDevice.current
      label = device.model
      platform = "ios"
      os = device.systemName
      osVersion = device.systemVersion
      let size = UIScreen.main.bounds.size
      screenWidth = Int(size.width.rounded())
      screenHeight = Int(size.height.rounded())
      scale = UIScreen.main.scale
    #elseif canImport(AppKit)
      label = Host.current().localizedName
      platform = "macos"
      os = "macOS"
      if let frame = NSScreen.main?.frame {
        screenWidth = Int(frame.width.rounded())
        screenHeight = Int(frame.height.rounded())
      }
      scale = NSScreen.main.map { Double($0.backingScaleFactor) }
    #endif

    return DeviceInfo(
      label: label,
      platform: platform,
      os: os,
      osVersion: osVersion,
      locale: Locale.current.identifier,
      timezone: TimeZone.current.identifier,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      devicePixelRatio: scale
    )
  }
}

public struct AnonymousAccount: Codable, Identifiable, Sendable {
  public let id: String
  public let displayName: String?
  public let createdAt: Date
  public let lastSeenAt: Date
}

public struct AnonymousSession: Codable, Sendable {
  public let account: AnonymousAccount
  public let token: String
}

public struct AdminReply: Codable, Identifiable, Sendable {
  public let id: Int
  public let surveyResponseId: Int
  public let anonymousAccountId: String
  public let adminId: String?
  public let body: String
  public let createdAt: Date
  public let readAt: Date?
}

public enum FormConciergeError: Error, LocalizedError, Sendable {
  case notFound
  case invalidResponse
  case api(status: Int, message: String)

  public var errorDescription: String? {
    switch self {
    case .notFound:
      "Survey not found."
    case .invalidResponse:
      "Invalid server response."
    case .api(_, let message):
      message
    }
  }
}

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
