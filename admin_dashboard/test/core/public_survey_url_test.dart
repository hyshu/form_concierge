import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/core/utils/public_survey_url.dart';

void main() {
  group('publicSurveyUrl', () {
    final now = DateTime.utc(2026, 7, 10);

    Survey survey() => Survey(
      id: 1,
      projectId: 1,
      slug: 'customer-feedback',
      titleTranslations: LocalizedText.filled('Feedback'),
      descriptionTranslations: LocalizedText.filled(''),
      status: SurveyStatus.published,
      webEnabled: true,
      createdAt: now,
      updatedAt: now,
    );

    Project project({String? customDomain}) => Project(
      id: 1,
      slug: 'demo-project',
      customDomain: customDomain,
      name: 'Demo',
      createdAt: now,
      updatedAt: now,
    );

    test('uses API host path with project and survey slugs', () {
      expect(
        publicSurveyUrl(
          apiBaseUri: Uri.parse('https://form-concierge-api.zoome.workers.dev'),
          project: project(),
          survey: survey(),
        ),
        'https://form-concierge-api.zoome.workers.dev/demo-project/customer-feedback',
      );
    });

    test('preserves base path segments on the API host', () {
      expect(
        publicSurveyUrl(
          apiBaseUri: Uri.parse('https://example.com/api/'),
          project: project(),
          survey: survey(),
        ),
        'https://example.com/api/demo-project/customer-feedback',
      );
    });

    test('prefers project custom domain when set', () {
      expect(
        publicSurveyUrl(
          apiBaseUri: Uri.parse('https://form-concierge-api.zoome.workers.dev'),
          project: project(customDomain: 'forms.sns.dotpx.com'),
          survey: survey(),
        ),
        'https://forms.sns.dotpx.com/customer-feedback',
      );
    });
  });
}
