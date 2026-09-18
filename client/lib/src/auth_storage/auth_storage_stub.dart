/// In-memory fallback for platforms without persistent web storage.
///
/// Sessions survive only for the lifetime of the process. Hosts that need
/// persistence across launches should supply and store tokens themselves
/// (e.g. via the widget package's anonymousToken/onAnonymousSession).
final Map<String, String> _sessions = {};

/// Reads the serialized administrator session for the given storage key.
Future<String?> readAuthSession(String key) async => _sessions[key];

/// Stores the serialized administrator session under the given key.
Future<void> writeAuthSession(String key, String value) async {
  _sessions[key] = value;
}

/// Removes the stored administrator session for the given key.
Future<void> clearAuthSession(String key) async {
  _sessions.remove(key);
}
