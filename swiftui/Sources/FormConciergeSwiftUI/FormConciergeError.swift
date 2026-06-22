import Foundation

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
