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

/// Host-provided persistence for last-seen reply timestamps.
///
/// The package never writes to disk by itself — the host app owns
/// `UserDefaults`, Keychain, or any other backend (same as Flutter widget).
public struct FormConciergeReplySeenStore: @unchecked Sendable {
  private let _read: (String) -> String?
  private let _write: (String, String) -> Void
  private let _remove: (String) -> Void

  public init(
    read: @escaping (String) -> String?,
    write: @escaping (String, String) -> Void,
    remove: @escaping (String) -> Void
  ) {
    self._read = read
    self._write = write
    self._remove = remove
  }

  public func read(_ key: String) -> String? { _read(key) }
  public func write(_ key: String, _ value: String) { _write(key, value) }
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

public final class FormConciergeReplyChecker {
  private let client: FormConciergeClient
  private let anonymousToken: String
  private let responseId: Int?
  private let store: FormConciergeReplySeenStore
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
    store: FormConciergeReplySeenStore,
    responseId: Int? = nil,
    storageKey: String? = nil
  ) {
    self.client = client
    self.anonymousToken = anonymousToken
    self.store = store
    self.responseId = responseId
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
    guard let value = store.read(storageKey) else {
      return nil
    }
    return Self.fractionalFormatter.date(from: value)
      ?? Self.plainFormatter.date(from: value)
  }

  public func markSeen(at date: Date = Date()) {
    store.write(storageKey, Self.fractionalFormatter.string(from: date))
  }

  public func markLatestSeen() async throws {
    await client.setAnonymousToken(anonymousToken)
    if let latestReplyAt = try await client.latestReplyAt(responseId: responseId) {
      markSeen(at: latestReplyAt)
    }
  }

  public func clearSeen() {
    store.remove(storageKey)
  }
}
