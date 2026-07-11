/// In-memory fallback for platforms without persistent web storage.
///
/// Sessions survive for the lifetime of the process only; hosts that need
/// persistence across launches should supply and store tokens themselves
/// (e.g. via the widget package's anonymousToken/onAnonymousSession).
final Map<String, String> _sessions = {};

Future<String?> readAuthSession(String key) async => _sessions[key];

Future<void> writeAuthSession(String key, String value) async {
  _sessions[key] = value;
}

Future<void> clearAuthSession(String key) async {
  _sessions.remove(key);
}
