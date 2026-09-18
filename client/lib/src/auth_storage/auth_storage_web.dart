import 'package:web/web.dart' as web;

/// Reads the serialized administrator session for the given storage key.
Future<String?> readAuthSession(String key) async =>
    web.window.localStorage.getItem(key);

/// Stores the serialized administrator session under the given key.
Future<void> writeAuthSession(String key, String value) async =>
    web.window.localStorage.setItem(key, value);

/// Removes the stored administrator session for the given key.
Future<void> clearAuthSession(String key) async =>
    web.window.localStorage.removeItem(key);
