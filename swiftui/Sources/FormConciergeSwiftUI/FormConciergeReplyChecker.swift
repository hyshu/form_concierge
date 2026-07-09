import CryptoKit
import Foundation

public struct AdminReplyCheckStatus: Sendable {
  public let latestReplyAt: Date?
  public let lastSeenReplyAt: Date?

  public var hasNewReplies: Bool {
    guard let latestReplyAt else { return false }
    guard let lastSeenReplyAt else { return true }
    return latestReplyAt > lastSeenReplyAt
  }
}

public final class FormConciergeReplyChecker {
  private let client: FormConciergeClient
  private let anonymousToken: String
  private let responseId: Int?
  private let userDefaults: UserDefaults
  private let storageKey: String
  /// Worker timestamps include fractional seconds (toISOString / SQLite %f).
  /// Default ISO8601DateFormatter truncates them on encode, so latestReplyAt
  /// would always stay "newer" than lastSeen and the badge never clears.
  private static let fractionalFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()
  private static let plainFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  public init(
    client: FormConciergeClient,
    anonymousToken: String,
    responseId: Int? = nil,
    userDefaults: UserDefaults = .standard,
    storageKey: String? = nil
  ) {
    self.client = client
    self.anonymousToken = anonymousToken
    self.responseId = responseId
    self.userDefaults = userDefaults
    self.storageKey = storageKey ?? Self.defaultStorageKey(
      anonymousToken: anonymousToken,
      responseId: responseId
    )
  }

  public static func defaultStorageKey(
    anonymousToken: String,
    responseId: Int? = nil
  ) -> String {
    let tokenHash = SHA256.hash(data: Data(anonymousToken.utf8))
      .map { String(format: "%02x", $0) }
      .joined()
    let scope = responseId.map { "response_\($0)" } ?? "all"
    return "form_concierge.reply_seen.\(scope).\(tokenHash)"
  }

  public func check(markSeen shouldMarkSeen: Bool = false) async throws -> AdminReplyCheckStatus {
    await client.setAnonymousToken(anonymousToken)
    let latestReplyAt = try await client.latestReplyAt(responseId: responseId)
    let status = AdminReplyCheckStatus(
      latestReplyAt: latestReplyAt,
      lastSeenReplyAt: lastSeenReplyAt
    )
    if shouldMarkSeen, let latestReplyAt {
      markSeen(at: latestReplyAt)
    }
    return status
  }

  public var lastSeenReplyAt: Date? {
    guard let value = userDefaults.string(forKey: storageKey) else {
      return nil
    }
    return Self.fractionalFormatter.date(from: value)
      ?? Self.plainFormatter.date(from: value)
  }

  public func markSeen(at date: Date = Date()) {
    userDefaults.set(Self.fractionalFormatter.string(from: date), forKey: storageKey)
  }

  public func markLatestSeen() async throws {
    await client.setAnonymousToken(anonymousToken)
    if let latestReplyAt = try await client.latestReplyAt(responseId: responseId) {
      markSeen(at: latestReplyAt)
    }
  }

  public func clearSeen() {
    userDefaults.removeObject(forKey: storageKey)
  }
}
