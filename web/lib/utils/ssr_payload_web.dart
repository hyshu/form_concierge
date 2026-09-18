import 'dart:convert';

import 'package:web/web.dart' as web;

/// Reads matching server-rendered survey data from the page, or null if none is
/// available.
Map<String, dynamic>? readSsrSurveyPayload({String? slug, String? domain}) {
  final element = web.document.getElementById('form-concierge-ssr');
  final text = element?.textContent?.trim();
  if (text == null || text.isEmpty || text == 'null') return null;

  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) return null;
    final project = decoded['project'];
    if (project is! Map<String, dynamic>) return null;
    final projectSlug = project['slug'];
    final projectDomain = project['customDomain'];
    if (projectSlug is! String) return null;
    if (projectDomain != null && projectDomain is! String) return null;
    if (slug != null && slug.isNotEmpty && projectSlug != slug) return null;
    if (domain != null &&
        domain.isNotEmpty &&
        projectDomain != null &&
        projectDomain.toLowerCase() != domain.toLowerCase()) {
      return null;
    }
    return decoded;
  } on Object {
    return null;
  }
}

/// Returns the API URL embedded in the page configuration, when available.
String? readConfiguredApiUrl() {
  final meta = web.document.querySelector(
    'meta[name="form-concierge-api-url"]',
  );
  final content = meta?.getAttribute('content')?.trim();
  return content == null || content.isEmpty ? null : content;
}

/// Removes the server-rendered form after the interactive client is ready.
void removeSsrRoot() =>
    web.document.getElementById('form-concierge-ssr-root')?.remove();
