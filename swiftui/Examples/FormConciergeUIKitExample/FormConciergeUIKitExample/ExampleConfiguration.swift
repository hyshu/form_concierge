import Foundation

enum ExampleConfiguration {
  private static let environment = ProcessInfo.processInfo.environment

  static let apiURL = URL(
    string: environment["FORM_CONCIERGE_API_URL"] ?? "http://localhost:8787"
  )!
  static let projectSlug = environment["FORM_CONCIERGE_PROJECT_SLUG"] ?? "example-project"
  static let surveySlug = environment["FORM_CONCIERGE_SURVEY_SLUG"] ?? "example-survey"
  static let surveyId = environment["FORM_CONCIERGE_SURVEY_ID"].flatMap(Int.init)
  static let turnstileBaseURL = URL(
    string: environment["FORM_CONCIERGE_TURNSTILE_BASE_URL"]
      ?? "http://localhost:8787"
  )!
}
