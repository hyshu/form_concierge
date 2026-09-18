import CryptoKit
import Foundation

/// The latest server reply time compared with locally stored seen state.
public struct AdminReplyCheckStatus: Sendable {
  /// The time of the latest administrator reply, if one exists.
  public let latestReplyAt: Date?
  /// The latest reply time previously marked as seen, if available.
  public let lastSeenReplyAt: Date?

  /// Whether the latest reply is newer than the stored seen time, or no seen time exists yet.
  public var hasNewReplies: Bool {
    guard let latestReplyAt else { return false }
    guard let lastSeenReplyAt else { return true }
    return latestReplyAt > lastSeenReplyAt
  }
}

/// Host-provided persistence for last-seen reply timestamps.
///
/// The host app owns persistence through
/// `UserDefaults`, Keychain, or any other backend (same as Flutter widget).
public struct FormConciergeReplySeenStore: @unchecked Sendable {
  private let _read: (String) -> String?
  private let _write: (String, String) -> Void
  private let _remove: (String) -> Void

  /// Creates FormConciergeReplySeenStore with the supplied configuration.
  public init(
    read: @escaping (String) -> String?,
    write: @escaping (String, String) -> Void,
    remove: @escaping (String) -> Void
  ) {
    self._read = read
    self._write = write
    self._remove = remove
  }

  /// Reads a stored value for the supplied persistence key.
  public func read(_ key: String) -> String? { _read(key) }
  /// Stores a value under the supplied persistence key.
  public func write(_ key: String, _ value: String) { _write(key, value) }
  /// Removes the value associated with the supplied persistence key.
  public func remove(_ key: String) { _remove(key) }

  /// Optional host convenience. The host must still pass this store explicitly.
  public static func userDefaults(_ defaults: UserDefaults) -> FormConciergeReplySeenStore {
    FormConciergeReplySeenStore(
      read: { defaults.string(forKey: $0) },
      write: { defaults.set($1, forKey: $0) },
      remove: { defaults.removeObject(forKey: $0) }
    )
  }

  /// In-memory store (tests / non-persistent hosts).
  public static func memory() -> FormConciergeReplySeenStore {
    let lock = NSLock()
    var values: [String: String] = [:]
    return FormConciergeReplySeenStore(
      read: { key in
        lock.lock()
        defer { lock.unlock() }
        return values[key]
      },
      write: { key, value in
        lock.lock()
        defer { lock.unlock() }
        values[key] = value
      },
      remove: { key in
        lock.lock()
        defer { lock.unlock() }
        values.removeValue(forKey: key)
      }
    )
  }
}

/// Checks for new administrator replies using host-provided seen state.
public final class FormConciergeReplyChecker {
  private let client: FormConciergeClient
  private let anonymousToken: String
  private let responseId: Int?
  private let store: FormConciergeReplySeenStore
  private let storageKey: String
  /// Preserve Worker timestamp fractional seconds so latestReplyAt does not
  /// remain newer than lastSeen and keep the badge from clearing.
  private static func parseISO8601(_ value: String) -> Date? {
    let fractionalFormatter = ISO8601DateFormatter()
    fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractionalFormatter.date(from: value) {
      return date
    }
    return ISO8601DateFormatter().date(from: value)
  }

  private static func formatISO8601(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
  }

  /// Creates FormConciergeReplyChecker with the supplied configuration.
  public init(
    client: FormConciergeClient,
    anonymousToken: String,
    store: FormConciergeReplySeenStore,
    responseId: Int? = nil,
    storageKey: String? = nil
  ) {
    self.client = client
    self.anonymousToken = anonymousToken
    self.store = store
    self.responseId = responseId
    self.storageKey =
      storageKey
      ?? Self.defaultStorageKey(
        anonymousToken: anonymousToken,
        responseId: responseId
      )
  }

  /// Builds a persistence key from a hash of the anonymous token and the response scope.
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

  /// Compares the latest reply time with local seen state and optionally marks it seen. Sets
  /// the client's anonymous token before requesting replies.
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

  /// The latest reply time previously marked as seen, if available.
  public var lastSeenReplyAt: Date? {
    guard let value = store.read(storageKey) else {
      return nil
    }
    return Self.parseISO8601(value)
  }

  /// Records the supplied timestamp as the latest reply time seen by the respondent.
  public func markSeen(at date: Date = Date()) {
    store.write(storageKey, Self.formatISO8601(date))
  }

  /// Fetches the latest reply time and marks it seen if a reply exists.
  public func markLatestSeen() async throws {
    await client.setAnonymousToken(anonymousToken)
    if let latestReplyAt = try await client.latestReplyAt(responseId: responseId) {
      markSeen(at: latestReplyAt)
    }
  }

  /// Removes the stored seen time for this reply scope.
  public func clearSeen() {
    store.remove(storageKey)
  }
}
