import Foundation

public enum QuestionType: String, Codable, Sendable {
  case singleChoice
  case multipleChoice
  case textSingle
  case textMultiLine
  case imageUpload
}

public enum SurveyStatus: String, Codable, Sendable {
  case draft
  case published
  case closed
  case archived
}

public enum VisibilityConditionMode: String, Codable, Sendable {
  case all
  case any
}

public enum VisibilityOperator: String, Codable, Sendable {
  case equals
  case notEquals
  case contains
  case notContains
  case isAnswered
  case isNotAnswered
}

public let formContentLocaleCodes = [
  "en", "ja", "zh-Hans", "zh-Hant", "ko", "de", "es", "fr", "it", "th", "tr",
]
public let defaultFormContentLocale = "en"

public let formContentLocaleLabels = [
  "en": "English",
  "ja": "日本語",
  "zh-Hans": "简体中文",
  "zh-Hant": "繁體中文",
  "ko": "한국어",
  "de": "Deutsch",
  "es": "Español",
  "fr": "Français",
  "it": "Italiano",
  "th": "ไทย",
  "tr": "Türkçe",
]

public func normalizeFormContentLocale(_ locale: String) -> String {
  let normalized = locale.replacingOccurrences(of: "_", with: "-")
  if formContentLocaleCodes.contains(normalized) { return normalized }

  let lower = normalized.lowercased()
  if lower == "zh-hans" || lower == "zh-cn" || lower == "zh-sg" {
    return "zh-Hans"
  }
  if lower == "zh-hant" || lower == "zh-tw" || lower == "zh-hk" || lower == "zh-mo" {
    return "zh-Hant"
  }

  let language = lower.split(separator: "-").first.map(String.init) ?? lower
  if formContentLocaleCodes.contains(language) { return language }
  return normalized
}

public struct LocalizedText: Codable, Equatable, Sendable {
  public let values: [String: String]

  public init(_ values: [String: String]) {
    self.values = values
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    values = try container.decode([String: String].self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(values)
  }

  public func value(for locale: String) -> String {
    values[normalizeFormContentLocale(locale)]
      ?? values[defaultFormContentLocale]
      ?? values.values.first
      ?? ""
  }
}

public struct Project: Codable, Identifiable, Sendable {
  public let id: Int
  public let slug: String
  public let customDomain: String?
  public let defaultLocale: String
  public let supportedLocales: [String]
  public let name: String
  public let createdAt: Date
  public let updatedAt: Date
}

public struct PublicProject: Codable, Sendable {
  public let project: Project
  public let surveys: [Survey]
}

public struct PublicConfig: Codable, Sendable {
  public let passwordResetEnabled: Bool
  public let requireEmailVerification: Bool
  public let aiGenerationEnabled: Bool
  public let turnstileSiteKey: String?
}

public struct Survey: Codable, Identifiable, Sendable {
  public let id: Int
  public let projectId: Int
  public let slug: String
  public let titleTranslations: LocalizedText
  public let descriptionTranslations: LocalizedText
  public let status: SurveyStatus
  public let webEnabled: Bool
  public let followUpEnabled: Bool
  private let captchaConfigurationEnabled: Bool
  @available(*, deprecated, message: "Use captchaRequired for submission behavior.")
  public var captchaEnabled: Bool { captchaConfigurationEnabled }
  public let captchaRequired: Bool
  public let startsAt: Date?
  public let endsAt: Date?
  public let createdAt: Date
  public let updatedAt: Date

  private enum CodingKeys: String, CodingKey {
    case id, projectId, slug, titleTranslations, descriptionTranslations, status
    case webEnabled, followUpEnabled, captchaEnabled, captchaRequired
    case startsAt, endsAt, createdAt, updatedAt
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    projectId = try container.decode(Int.self, forKey: .projectId)
    slug = try container.decode(String.self, forKey: .slug)
    titleTranslations = try container.decode(LocalizedText.self, forKey: .titleTranslations)
    descriptionTranslations = try container.decode(
      LocalizedText.self, forKey: .descriptionTranslations)
    status = try container.decode(SurveyStatus.self, forKey: .status)
    webEnabled = try container.decode(Bool.self, forKey: .webEnabled)
    // Tolerate older workers that do not send these fields yet.
    followUpEnabled = try container.decodeIfPresent(Bool.self, forKey: .followUpEnabled) ?? false
    let captchaEnabled = try container.decodeIfPresent(Bool.self, forKey: .captchaEnabled) ?? true
    captchaConfigurationEnabled = captchaEnabled
    // TODO(form-concierge-1.0.0): Remove the captchaEnabled fallback.
    captchaRequired =
      try container.decodeIfPresent(Bool.self, forKey: .captchaRequired) ?? captchaEnabled
    startsAt = try container.decodeIfPresent(Date.self, forKey: .startsAt)
    endsAt = try container.decodeIfPresent(Date.self, forKey: .endsAt)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(projectId, forKey: .projectId)
    try container.encode(slug, forKey: .slug)
    try container.encode(titleTranslations, forKey: .titleTranslations)
    try container.encode(descriptionTranslations, forKey: .descriptionTranslations)
    try container.encode(status, forKey: .status)
    try container.encode(webEnabled, forKey: .webEnabled)
    try container.encode(followUpEnabled, forKey: .followUpEnabled)
    try container.encode(captchaConfigurationEnabled, forKey: .captchaEnabled)
    try container.encode(captchaRequired, forKey: .captchaRequired)
    try container.encodeIfPresent(startsAt, forKey: .startsAt)
    try container.encodeIfPresent(endsAt, forKey: .endsAt)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(updatedAt, forKey: .updatedAt)
  }

  public func title(for locale: String) -> String {
    titleTranslations.value(for: locale)
  }

  public func description(for locale: String) -> String {
    descriptionTranslations.value(for: locale)
  }
}

public struct Question: Codable, Identifiable, Sendable {
  public let id: Int
  public let surveyId: Int
  public let textTranslations: LocalizedText
  public let type: QuestionType
  public let orderIndex: Int
  public let isRequired: Bool
  public let placeholderTranslations: LocalizedText
  public let minLength: Int?
  public let maxLength: Int?
  public let minSelected: Int?
  public let maxSelected: Int?
  public let visibilityConditionMode: VisibilityConditionMode

  public func text(for locale: String) -> String {
    textTranslations.value(for: locale)
  }

  public func placeholder(for locale: String) -> String {
    placeholderTranslations.value(for: locale)
  }
}

public struct QuestionVisibilityRule: Codable, Identifiable, Sendable {
  public let id: Int
  public let surveyId: Int
  public let targetQuestionId: Int
  public let sourceQuestionId: Int
  public let `operator`: VisibilityOperator
  public let value: VisibilityRuleValue?
  public let createdAt: Date?
  public let updatedAt: Date?
}

public enum VisibilityRuleValue: Codable, Equatable, Sendable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case null

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Int.self) {
      self = .int(value)
    } else if let value = try? container.decode(Double.self) {
      self = .double(value)
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else {
      self = .string(try container.decode(String.self))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let value):
      try container.encode(value)
    case .int(let value):
      try container.encode(value)
    case .double(let value):
      try container.encode(value)
    case .bool(let value):
      try container.encode(value)
    case .null:
      try container.encodeNil()
    }
  }

  var intValue: Int? {
    switch self {
    case .int(let value):
      value
    case .string, .double, .bool, .null:
      nil
    }
  }

  var stringValue: String? {
    switch self {
    case .string(let value):
      value
    case .int, .double, .bool, .null:
      nil
    }
  }
}

public struct Choice: Codable, Identifiable, Sendable {
  public let id: Int
  public let questionId: Int
  public let textTranslations: LocalizedText
  public let orderIndex: Int
  public let value: String?

  public func text(for locale: String) -> String {
    textTranslations.value(for: locale)
  }
}

public struct Answer: Codable, Sendable {
  public let surveyResponseId: Int
  public let questionId: Int
  public let textValue: String?
  public let selectedChoiceIds: [Int]?
  public let fileKeys: [String]?

  public init(
    questionId: Int,
    textValue: String? = nil,
    selectedChoiceIds: [Int]? = nil,
    fileKeys: [String]? = nil
  ) {
    self.surveyResponseId = 0
    self.questionId = questionId
    self.textValue = textValue
    self.selectedChoiceIds = selectedChoiceIds
    self.fileKeys = fileKeys
  }
}

public struct MediaUpload: Codable, Sendable {
  public let key: String
  public let contentType: String
  public let size: Int
}

public enum FollowUpStatus: String, Codable, Sendable {
  case skipped
  case pending
  case completed
}

public struct FollowUpChoice: Codable, Identifiable, Sendable {
  public let id: String
  public let label: String
}

public struct FollowUpAnswer: Codable, Sendable {
  public let textValue: String?
  public let selectedChoiceIds: [String]
  public let fileKeys: [String]

  public init(
    textValue: String? = nil,
    selectedChoiceIds: [String] = [],
    fileKeys: [String] = []
  ) {
    self.textValue = textValue
    self.selectedChoiceIds = selectedChoiceIds
    self.fileKeys = fileKeys
  }
}

public struct FollowUpSubmissionAnswer: Codable, Sendable {
  public let id: String
  public let textValue: String?
  public let selectedChoiceIds: [String]
  public let fileKeys: [String]

  public init(
    id: String,
    textValue: String? = nil,
    selectedChoiceIds: [String] = [],
    fileKeys: [String] = []
  ) {
    self.id = id
    self.textValue = textValue
    self.selectedChoiceIds = selectedChoiceIds
    self.fileKeys = fileKeys
  }
}

public struct FollowUpItem: Codable, Identifiable, Sendable {
  public let id: String
  public let type: QuestionType
  public let text: String
  public let required: Bool
  public let placeholder: String?
  public let maxFiles: Int?
  public let choices: [FollowUpChoice]
  public let answer: FollowUpAnswer?
}

public struct FollowUp: Codable, Sendable {
  public let version: Int
  public let status: FollowUpStatus
  public let generatedAt: Date
  public let completedAt: Date?
  public let locale: String
  public let items: [FollowUpItem]
}

public struct FollowUpGenerateResult: Codable, Sendable {
  public let needed: Bool
  public let followUp: FollowUp
  public let error: String?
}

/// Image payload for host-side processing before upload.
public struct SurveyImagePayload: Sendable {
  public let data: Data
  public let contentType: String

  public init(data: Data, contentType: String) {
    self.data = data
    self.contentType = contentType
  }
}

/// Host transform applied after pick and before upload.
///
/// Return the (possibly compressed/resized) image to upload, or `nil` to skip
/// that image without failing the whole batch.
public typealias ProcessSurveyImage =
  (SurveyImagePayload) async throws -> SurveyImagePayload?

public struct SurveyResponse: Codable, Identifiable, Sendable {
  public let id: Int
  public let surveyId: Int
  public let anonymousId: String?
  public let anonymousAccountId: String?
  public let submittedAt: Date
  public let deviceInfo: DeviceInfo?
  public let metadata: [String: FormConciergeMetadataValue]?
  public let followUp: FollowUp?
  public let replyCount: Int

  private enum CodingKeys: String, CodingKey {
    case id, surveyId, anonymousId, anonymousAccountId, submittedAt
    case deviceInfo, metadata, followUp, replyCount
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    surveyId = try container.decode(Int.self, forKey: .surveyId)
    anonymousId = try container.decodeIfPresent(String.self, forKey: .anonymousId)
    anonymousAccountId = try container.decodeIfPresent(String.self, forKey: .anonymousAccountId)
    submittedAt = try container.decode(Date.self, forKey: .submittedAt)
    deviceInfo = try container.decodeIfPresent(DeviceInfo.self, forKey: .deviceInfo)
    metadata = try container.decodeIfPresent(
      [String: FormConciergeMetadataValue].self, forKey: .metadata)
    followUp = try container.decodeIfPresent(FollowUp.self, forKey: .followUp)
    replyCount = try container.decodeIfPresent(Int.self, forKey: .replyCount) ?? 0
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
