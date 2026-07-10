import 'package:form_concierge_client/form_concierge_client.dart';

/// Builds the public HTML URL for a survey.
///
/// Prefers the project's custom domain when set; otherwise uses the Worker API
/// host (`/{projectSlug}/{surveySlug}`).
String publicSurveyUrl({
  required Uri apiBaseUri,
  required Project project,
  required Survey survey,
}) {
  final customDomain = project.customDomain?.trim();
  if (customDomain != null && customDomain.isNotEmpty) {
    return Uri(
      scheme: 'https',
      host: customDomain,
      pathSegments: [survey.slug],
    ).toString();
  }

  final baseSegments = apiBaseUri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  return apiBaseUri
      .replace(
        pathSegments: [...baseSegments, project.slug, survey.slug],
        query: null,
        fragment: null,
      )
      .toString();
}
