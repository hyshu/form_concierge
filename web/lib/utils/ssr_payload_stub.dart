/// Returns null because browser storage or page state is unavailable on this platform.
Map<String, dynamic>? readSsrSurveyPayload({String? slug, String? domain}) =>
    null;

/// Returns null because browser storage or page state is unavailable on this platform.
String? readConfiguredApiUrl() => null;

/// Does nothing on platforms without the required browser APIs.
void removeSsrRoot() {}
