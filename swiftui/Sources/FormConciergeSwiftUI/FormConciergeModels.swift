import Foundation

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

public let formContentLocaleCodes = ["en", "ja", "zh-Hans", "zh-Hant", "ko", "de"]
public let defaultFormContentLocale = "en"

public let formContentLocaleLabels = [
  "en": "English",
  "ja": "日本語",
  "zh-Hans": "简体中文",
  "zh-Hant": "繁體中文",
  "ko": "한국어",
  "de": "Deutsch"
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
    values[normalizeFormContentLocale(locale)]!
  }
}

public struct Survey: Codable, Identifiable, Sendable {
  public let id: Int
  public let slug: String
  public let defaultLocale: String
  public let supportedLocales: [String]
  public let titleTranslations: LocalizedText
  public let descriptionTranslations: LocalizedText
  public let status: SurveyStatus
  public let createdAt: Date
  public let updatedAt: Date

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
    case .double(let value):
      Int(value)
    case .string(let value):
      Int(value)
    case .bool, .null:
      nil
    }
  }

  var stringValue: String {
    switch self {
    case .string(let value):
      value
    case .int(let value):
      "\(value)"
    case .double(let value):
      "\(value)"
    case .bool(let value):
      "\(value)"
    case .null:
      ""
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
