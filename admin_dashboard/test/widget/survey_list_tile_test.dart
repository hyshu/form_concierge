import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/dashboard/presentation/widgets/survey_list_tile.dart';

import '../support/localized_test_app.dart';

void main() {
  group('SurveyListTile', () {
    testWidgets(
      'renders title, description, slug, custom domain, and updated date',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          _subject(
            survey: _survey(
              customDomain: 'forms.example.com',
              description: 'Short survey description',
            ),
          ),
        );

        expect(find.text('Customer feedback'), findsOneWidget);
        expect(find.text('Short survey description'), findsOneWidget);
        expect(find.text('/customer-feedback'), findsOneWidget);
        expect(find.text('forms.example.com'), findsOneWidget);
        expect(find.text('2026-06-22'), findsOneWidget);
        expect(find.text('Draft'), findsOneWidget);
      },
    );

    testWidgets('hides custom domain and empty description when absent', (
      tester,
    ) async {
      await tester.pumpWidget(_subject(survey: _survey()));

      expect(find.text('forms.example.com'), findsNothing);
      expect(find.text('Short survey description'), findsNothing);
      expect(find.text('/customer-feedback'), findsOneWidget);
    });

    testWidgets('tapping tile and action buttons dispatches callbacks', (
      tester,
    ) async {
      var tapped = false;
      var viewedResponses = false;
      var published = false;
      var closed = false;
      var reopened = false;
      var deleted = false;

      await tester.pumpWidget(
        _subject(
          survey: _survey(customDomain: 'forms.example.com'),
          onTap: () => tapped = true,
          onViewResponses: () => viewedResponses = true,
          onPublish: () => published = true,
          onClose: () => closed = true,
          onReopen: () => reopened = true,
          onDelete: () => deleted = true,
        ),
      );

      await tester.tap(find.text('Customer feedback'));
      await tester.pump();
      expect(tapped, isTrue);

      await tester.tap(find.byTooltip('Publish'));
      await tester.tap(find.byTooltip('Close'));
      await tester.tap(find.byTooltip('Reopen'));
      await tester.tap(find.byTooltip('View Responses'));
      await tester.tap(find.byTooltip('Delete'));
      await tester.pump();

      expect(published, isTrue);
      expect(closed, isTrue);
      expect(reopened, isTrue);
      expect(viewedResponses, isTrue);
      expect(deleted, isTrue);
    });
  });
}

Widget _subject({
  required Survey survey,
  VoidCallback? onTap,
  VoidCallback? onViewResponses,
  VoidCallback? onPublish,
  VoidCallback? onClose,
  VoidCallback? onReopen,
  VoidCallback? onDelete,
}) {
  return localizedTestApp(
    home: Scaffold(
      body: SurveyListTile(
        survey: survey,
        onTap: onTap ?? () {},
        onViewResponses: onViewResponses ?? () {},
        onPublish: onPublish,
        onClose: onClose,
        onReopen: onReopen,
        onDelete: onDelete,
      ),
    ),
  );
}

Survey _survey({
  String? customDomain,
  String description = '',
}) {
  final now = DateTime.utc(2026, 6, 22, 10);
  return Survey(
    id: 1,
    slug: 'customer-feedback',
    customDomain: customDomain,
    defaultLocale: defaultFormContentLocale,
    supportedLocales: formContentLocaleCodes,
    titleTranslations: LocalizedText({
      for (final locale in formContentLocaleCodes)
        locale: locale == 'en' ? 'Customer feedback' : 'Title $locale',
    }),
    descriptionTranslations: LocalizedText({
      for (final locale in formContentLocaleCodes) locale: description,
    }),
    status: SurveyStatus.draft,
    createdAt: now,
    updatedAt: now,
  );
}
