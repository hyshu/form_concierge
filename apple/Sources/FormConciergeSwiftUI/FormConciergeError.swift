import Foundation

/// An error encountered while loading or submitting a survey.
public enum FormConciergeError: Error, LocalizedError, Sendable {
  /// The requested survey or project could not be found.
  case notFound
  /// The server returned a response that could not be interpreted as HTTP.
  case invalidResponse
  /// An unsuccessful API response with its HTTP status and message.
  case api(status: Int, message: String)

  /// A human-readable description of the failure.
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
