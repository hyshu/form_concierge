import Foundation

/// The input format used to collect a question's answer.
public enum QuestionType: String, Codable, Sendable {
  /// A question that accepts one selected choice.
  case singleChoice
  /// A question that accepts several selected choices.
  case multipleChoice
  /// A question that accepts a single line of text.
  case textSingle
  /// A question that accepts multiple lines of text.
  case textMultiLine
  /// A question that accepts uploaded images.
  case imageUpload
}

/// The publication state of a survey.
public enum SurveyStatus: String, Codable, Sendable {
  /// A survey that has not been published.
  case draft
  /// A published survey, subject to its availability schedule.
  case published
  /// A survey that no longer accepts responses.
  case closed
  /// A survey retained for reference after active use.
  case archived
}

/// How multiple rules combine to control question visibility.
public enum VisibilityConditionMode: String, Codable, Sendable {
  /// Shows the question only when every rule matches.
  case all
  /// Shows the question when at least one rule matches.
  case any
}

/// The comparison applied to a source question's answer.
public enum VisibilityOperator: String, Codable, Sendable {
  /// Matches equal text or a selected choice.
  case equals
  /// Matches different text or an unselected choice when an answer exists.
  case notEquals
  /// Matches text containing a substring or a selected choice.
  case contains
  /// Matches an answer that excludes the text or choice.
  case notContains
  /// Matches a nonempty answer.
  case isAnswered
  /// Matches a missing or empty answer.
  case isNotAnswered
}

/// Locale codes supported by the built-in survey translations.
public let formContentLocaleCodes = [
  "en", "ja", "zh-Hans", "zh-Hant", "ko", "de", "es", "fr", "it", "th", "tr",
]
/// The fallback locale used when a translation is unavailable.
public let defaultFormContentLocale = "en"

/// Human-readable language names indexed by supported locale code.
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

/// Normalizes locale separators and supported language aliases while preserving unrecognized
/// locale codes.
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

/// Text translations indexed by locale code.
public struct LocalizedText: Codable, Equatable, Sendable {
  /// Translations indexed by locale code.
  public let values: [String: String]

  /// Creates LocalizedText with the supplied configuration.
  public init(_ values: [String: String]) {
    self.values = values
  }

  /// Decodes this value from the supplied decoder.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    values = try container.decode([String: String].self)
  }

  /// Encodes this value using the supplied encoder.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(values)
  }

  /// Returns a translation for the locale, falling back to English, the first value, then an
  /// empty string.
  public func value(for locale: String) -> String {
    values[normalizeFormContentLocale(locale)]
      ?? values[defaultFormContentLocale]
      ?? values.values.first
      ?? ""
  }
}

/// A group of surveys with shared locale and domain settings.
public struct Project: Codable, Identifiable, Sendable {
  /// The identifier of this project.
  public let id: Int
  /// The URL-friendly name used to look up this resource.
  public let slug: String
  /// The custom host name assigned to the project, if any.
  public let customDomain: String?
  /// The locale used when the respondent's preferred language is unavailable.
  public let defaultLocale: String
  /// The locale codes enabled for this project.
  public let supportedLocales: [String]
  /// The name displayed for the project.
  public let name: String
  /// When this record was created.
  public let createdAt: Date
  /// When this record was last updated.
  public let updatedAt: Date
}

/// A public project and the surveys available to respondents.
public struct PublicProject: Codable, Sendable {
  /// The project that contains the survey.
  public let project: Project
  /// The surveys included in the project result.
  public let surveys: [Survey]
}

/// Public feature flags and CAPTCHA configuration for clients.
public struct PublicConfig: Codable, Sendable {
  /// Whether the server advertises password reset support.
  public let passwordResetEnabled: Bool
  /// Whether administrator email verification is required.
  public let requireEmailVerification: Bool
  /// Whether AI-assisted content generation is available.
  public let aiGenerationEnabled: Bool
  /// The public Turnstile site key, or nil when CAPTCHA is not configured.
  public let turnstileSiteKey: String?
}

/// A form's localized content, availability, and submission settings.
public struct Survey: Codable, Identifiable, Sendable {
  /// The identifier of this survey.
  public let id: Int
  /// The identifier of the project containing the survey.
  public let projectId: Int
  /// The URL-friendly name used to look up this resource.
  public let slug: String
  /// Survey titles indexed by locale code.
  public let titleTranslations: LocalizedText
  /// Survey descriptions indexed by locale code.
  public let descriptionTranslations: LocalizedText
  /// The current publication state of the survey.
  public let status: SurveyStatus
  /// Whether the survey is available through its public web page.
  public let webEnabled: Bool
  /// Whether submissions may receive an adaptive follow-up interview.
  public let followUpEnabled: Bool
  private let captchaConfigurationEnabled: Bool
  /// The configured CAPTCHA preference. Use captchaRequired for submission behavior.
  @available(*, deprecated, message: "Use captchaRequired for submission behavior.")
  public var captchaEnabled: Bool { captchaConfigurationEnabled }
  /// Whether a CAPTCHA token is required when submitting this survey.
  public let captchaRequired: Bool
  /// When the survey begins accepting responses, if scheduled.
  public let startsAt: Date?
  /// When the survey stops accepting responses, if scheduled.
  public let endsAt: Date?
  /// When this record was created.
  public let createdAt: Date
  /// When this record was last updated.
  public let updatedAt: Date

  private enum CodingKeys: String, CodingKey {
    case id, projectId, slug, titleTranslations, descriptionTranslations, status
    case webEnabled, followUpEnabled, captchaEnabled, captchaRequired
    case startsAt, endsAt, createdAt, updatedAt
  }

  /// Decodes this value from the supplied decoder.
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

  /// Encodes this value using the supplied encoder.
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

  /// Returns the survey title for the requested locale with translation fallback.
  public func title(for locale: String) -> String {
    titleTranslations.value(for: locale)
  }

  /// Returns the survey description for the requested locale with translation fallback.
  public func description(for locale: String) -> String {
    descriptionTranslations.value(for: locale)
  }
}

/// A survey question with input constraints and visibility settings.
public struct Question: Codable, Identifiable, Sendable {
  /// The identifier of this question.
  public let id: Int
  /// The identifier of the associated survey.
  public let surveyId: Int
  /// Display text indexed by locale code.
  public let textTranslations: LocalizedText
  /// The input format used to collect the answer.
  public let type: QuestionType
  /// The position of this item in its ordered question or choice list.
  public let orderIndex: Int
  /// Whether the respondent must answer this question.
  public let isRequired: Bool
  /// Input hints indexed by locale code.
  public let placeholderTranslations: LocalizedText
  /// The minimum accepted text length, or nil when no minimum is set.
  public let minLength: Int?
  /// The maximum accepted text length, or nil when no maximum is set.
  public let maxLength: Int?
  /// The minimum number of choices or uploaded files required, if set.
  public let minSelected: Int?
  /// The maximum number of choices or uploaded files allowed, if set.
  public let maxSelected: Int?
  /// Whether all visibility rules or any one rule must match.
  public let visibilityConditionMode: VisibilityConditionMode

  /// Returns display text for the requested locale with translation fallback.
  public func text(for locale: String) -> String {
    textTranslations.value(for: locale)
  }

  /// Returns the input hint for the requested locale with translation fallback.
  public func placeholder(for locale: String) -> String {
    placeholderTranslations.value(for: locale)
  }
}

/// A condition on another answer that controls question visibility.
public struct QuestionVisibilityRule: Codable, Identifiable, Sendable {
  /// The identifier of this question visibility rule.
  public let id: Int
  /// The identifier of the associated survey.
  public let surveyId: Int
  /// The identifier of the question whose visibility is controlled.
  public let targetQuestionId: Int
  /// The identifier of the question whose answer is tested.
  public let sourceQuestionId: Int
  /// The comparison applied to the source answer.
  public let `operator`: VisibilityOperator
  /// The text or choice identifier to compare with the source answer.
  public let value: VisibilityRuleValue?
  /// When this record was created.
  public let createdAt: Date?
  /// When this record was last updated.
  public let updatedAt: Date?
}

/// The text or choice identifier compared with a source answer.
public enum VisibilityRuleValue: Codable, Equatable, Sendable {
  /// A text value used in a visibility comparison.
  case string(String)
  /// An integer value used to identify a choice.
  case int(Int)
  /// A numeric value decoded from the visibility rule payload.
  case double(Double)
  /// A Boolean value decoded from the visibility rule payload.
  case bool(Bool)
  /// An explicit nil comparison value.
  case null

  /// Decodes this value from the supplied decoder.
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

  /// Encodes this value using the supplied encoder.
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

/// A localized answer option belonging to a choice question.
public struct Choice: Codable, Identifiable, Sendable {
  /// The identifier of this choice.
  public let id: Int
  /// The identifier of the associated question.
  public let questionId: Int
  /// Display text indexed by locale code.
  public let textTranslations: LocalizedText
  /// The position of this item in its ordered question or choice list.
  public let orderIndex: Int
  /// An optional application-defined value for this choice.
  public let value: String?

  /// Returns display text for the requested locale with translation fallback.
  public func text(for locale: String) -> String {
    textTranslations.value(for: locale)
  }
}

/// A submitted answer to one survey question.
public struct Answer: Codable, Sendable {
  /// The identifier of the associated survey response.
  public let surveyResponseId: Int
  /// The identifier of the associated question.
  public let questionId: Int
  /// The submitted text for a text question, when present.
  public let textValue: String?
  /// The identifiers of the selected answer choices.
  public let selectedChoiceIds: [Int]?
  /// Storage keys for the uploaded files attached to the answer.
  public let fileKeys: [String]?

  /// Creates Answer with the supplied configuration.
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

/// The storage key and metadata of an uploaded file.
public struct MediaUpload: Codable, Sendable {
  /// The storage key used to retrieve the uploaded file.
  public let key: String
  /// The MIME type of the content.
  public let contentType: String
  /// The size of the uploaded file in bytes.
  public let size: Int
}

/// The progress of an adaptive follow-up interview.
public enum FollowUpStatus: String, Codable, Sendable {
  /// No follow-up interview is required.
  case skipped
  /// The follow-up interview is waiting for answers.
  case pending
  /// The follow-up answers have been saved.
  case completed
}

/// A selectable option in a follow-up question.
public struct FollowUpChoice: Codable, Identifiable, Sendable {
  /// The identifier of this follow up choice.
  public let id: String
  /// A human-readable label.
  public let label: String
}

/// An answer to an adaptive follow-up question.
public struct FollowUpAnswer: Codable, Sendable {
  /// The submitted text for a text question, when present.
  public let textValue: String?
  /// The identifiers of the selected answer choices.
  public let selectedChoiceIds: [String]
  /// Storage keys for the uploaded files attached to the answer.
  public let fileKeys: [String]

  /// Creates FollowUpAnswer with the supplied configuration.
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

/// An answer payload for one adaptive follow-up item.
public struct FollowUpSubmissionAnswer: Codable, Sendable {
  /// The identifier of this follow up submission answer.
  public let id: String
  /// The submitted text for a text question, when present.
  public let textValue: String?
  /// The identifiers of the selected answer choices.
  public let selectedChoiceIds: [String]
  /// Storage keys for the uploaded files attached to the answer.
  public let fileKeys: [String]

  /// Creates FollowUpSubmissionAnswer with the supplied configuration.
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

/// A follow-up question with its choices and any saved answer.
public struct FollowUpItem: Codable, Identifiable, Sendable {
  /// The identifier of this follow up item.
  public let id: String
  /// The input format used to collect the answer.
  public let type: QuestionType
  /// The question text shown to the respondent.
  public let text: String
  /// Whether the respondent must answer this question.
  public let required: Bool
  /// Hint text displayed when the text input is empty.
  public let placeholder: String?
  /// The maximum number of files allowed for this question.
  public let maxFiles: Int?
  /// The choices available for this question.
  public let choices: [FollowUpChoice]
  /// The saved answer, if the follow-up question has been answered.
  public let answer: FollowUpAnswer?
}

/// An adaptive interview generated from a submitted survey response.
public struct FollowUp: Codable, Sendable {
  /// The version associated with this record.
  public let version: Int
  /// The current progress of the follow-up interview.
  public let status: FollowUpStatus
  /// When the follow-up interview was generated.
  public let generatedAt: Date
  /// When the follow-up interview was completed, if applicable.
  public let completedAt: Date?
  /// The locale used to display the form content.
  public let locale: String
  /// The questions in the follow-up interview.
  public let items: [FollowUpItem]
}

/// The outcome of requesting an adaptive follow-up interview.
public struct FollowUpGenerateResult: Codable, Sendable {
  /// Whether the generated follow-up requires additional answers.
  public let needed: Bool
  /// The adaptive follow-up interview associated with the response.
  public let followUp: FollowUp
  /// The error message, when the operation could not complete.
  public let error: String?
}

/// Image payload for host-side processing before upload.
public struct SurveyImagePayload: Sendable {
  /// The image contents as raw bytes.
  public let data: Data
  /// The MIME type of the content.
  public let contentType: String

  /// Creates SurveyImagePayload with the supplied configuration.
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

/// A recorded survey submission and its associated metadata.
public struct SurveyResponse: Codable, Identifiable, Sendable {
  /// The identifier of this survey response.
  public let id: Int
  /// The identifier of the associated survey.
  public let surveyId: Int
  /// An optional respondent identifier supplied by the host application.
  public let anonymousId: String?
  /// The anonymous account that owns the response or reply.
  public let anonymousAccountId: String?
  /// When the survey response was submitted.
  public let submittedAt: Date
  /// Optional device details attached to the submission.
  public let deviceInfo: DeviceInfo?
  /// Application-provided metadata attached to the submission.
  public let metadata: [String: FormConciergeMetadataValue]?
  /// The adaptive follow-up interview associated with the response.
  public let followUp: FollowUp?
  /// The number of administrator replies attached to the response.
  public let replyCount: Int

  private enum CodingKeys: String, CodingKey {
    case id, surveyId, anonymousId, anonymousAccountId, submittedAt
    case deviceInfo, metadata, followUp, replyCount
  }

  /// Decodes this value from the supplied decoder.
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

/// An anonymous respondent identity used to own submissions and receive replies.
public struct AnonymousAccount: Codable, Identifiable, Sendable {
  /// The identifier of this anonymous account.
  public let id: String
  /// The optional display name attached to the anonymous account.
  public let displayName: String?
  /// When this record was created.
  public let createdAt: Date
  /// When the anonymous account was last active.
  public let lastSeenAt: Date
}

/// An anonymous account and the bearer token used to access it.
public struct AnonymousSession: Codable, Sendable {
  /// The anonymous account associated with the current session, if known.
  public let account: AnonymousAccount
  /// The bearer token used to authenticate requests.
  public let token: String
}

/// An administrator's message to the owner of a survey response.
public struct AdminReply: Codable, Identifiable, Sendable {
  /// The identifier of this admin reply.
  public let id: Int
  /// The identifier of the associated survey response.
  public let surveyResponseId: Int
  /// The anonymous account that owns the response or reply.
  public let anonymousAccountId: String
  /// The identifier of the administrator who wrote the reply, if available.
  public let adminId: String?
  /// The reply text sent to the respondent.
  public let body: String
  /// When this record was created.
  public let createdAt: Date
  /// When the reply was marked as read, if available.
  public let readAt: Date?
}
