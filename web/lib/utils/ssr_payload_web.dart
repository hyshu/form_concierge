import 'dart:convert';

import 'package:web/web.dart' as web;

Map<String, dynamic>? readSsrSurveyPayload({
  String? slug,
  String? domain,
}) {
  final element = web.document.getElementById('form-concierge-ssr');
  final text = element?.textContent?.trim();
  if (text == null || text.isEmpty || text == 'null') return null;

  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) return null;
    final survey = decoded['survey'];
    if (survey is! Map<String, dynamic>) return null;
    final surveySlug = survey['slug']?.toString();
    final surveyDomain = survey['customDomain']?.toString();
    if (slug != null && slug.isNotEmpty && surveySlug != slug) return null;
    if (domain != null &&
        domain.isNotEmpty &&
        surveyDomain != null &&
        surveyDomain.toLowerCase() != domain.toLowerCase()) {
      return null;
    }
    return decoded;
  } on Object {
    return null;
  }
}

String? readConfiguredApiUrl() {
  final meta = web.document.querySelector(
    'meta[name="form-concierge-api-url"]',
  );
  final content = meta?.getAttribute('content')?.trim();
  return content == null || content.isEmpty ? null : content;
}

void removeSsrRoot() {
  web.document.getElementById('form-concierge-ssr-root')?.remove();
}
