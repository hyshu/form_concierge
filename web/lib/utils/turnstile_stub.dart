/// Does nothing on platforms without the required browser APIs.
Future<void> mountTurnstile({
  required String containerId,
  required String siteKey,
}) async {}

/// Returns null because browser storage or page state is unavailable on this platform.
String? getTurnstileResponse() => null;

/// Does nothing on platforms without the required browser APIs.
void resetTurnstile() {}

/// Does nothing on platforms without the required browser APIs.
void unmountTurnstile() {}
