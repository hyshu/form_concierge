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
