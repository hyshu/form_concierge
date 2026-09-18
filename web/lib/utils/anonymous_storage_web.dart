import 'package:web/web.dart' as web;

/// Reads the respondent token associated with a local storage key.
String? readAnonymousToken(String key) => web.window.localStorage.getItem(key);

/// Stores the respondent token under the supplied local storage key.
void writeAnonymousToken(String key, String token) =>
    web.window.localStorage.setItem(key, token);

/// Removes the respondent token associated with a local storage key.
void clearAnonymousToken(String key) => web.window.localStorage.removeItem(key);
