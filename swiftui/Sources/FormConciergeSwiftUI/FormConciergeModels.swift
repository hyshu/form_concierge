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
  public let minSelected: Int?
  public let maxSelected: Int?
  public let visibilityConditionMode: VisibilityConditionMode
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
