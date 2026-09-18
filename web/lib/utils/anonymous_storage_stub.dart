/// Returns null because browser storage or page state is unavailable on this platform.
String? readAnonymousToken(String key) => null;

/// Does nothing on platforms without the required browser APIs.
void writeAnonymousToken(String key, String token) {}

/// Does nothing on platforms without the required browser APIs.
void clearAnonymousToken(String key) {}
