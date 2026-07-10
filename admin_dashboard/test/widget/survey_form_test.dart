import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/capsules/survey_form_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/widgets/survey_form.dart';

import '../support/given_when_then.dart';
import '../support/localized_test_app.dart';

void main() {
  group('SurveyForm validation', () {
    late SurveyFormControllers controllers;
    late bool saveWasCalled;
    late LocalizedText? savedTitleTranslations;

    setUp(() {
      controllers = _controllers();
      saveWasCalled = false;
      savedTitleTranslations = null;
    });

    tearDown(() {
      controllers.dispose();
    });

    Widget buildSubject({
      bool isSaving = false,
      String? error,
      String primaryLocale = defaultFormContentLocale,
      Iterable<String> locales = formContentLocaleCodes,
    }) {
      return localizedTestApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SurveyForm(
              controllers: controllers,
              isSaving: isSaving,
              error: error,
              primaryLocale: primaryLocale,
              locales: locales,
              onSave:
                  ({
                    required String slug,
                    required LocalizedText titleTranslations,
                    required LocalizedText descriptionTranslations,
                  }) async {
                    saveWasCalled = true;
                    savedTitleTranslations = titleTranslations;
                  },
            ),
          ),
        ),
      );
    }

    scenarioWidget(
      'empty title shows validation error',
      given: (tester) async {
        await tester.pumpWidget(buildSubject());
      },
      when: (tester) async {
        await _tapCreateSurvey(tester);
      },
      then: (tester) async {
        expect(find.text('Title is required'), findsWidgets);
        expect(saveWasCalled, isFalse);
      },
    );

    scenarioWidget(
      'valid form calls onSave with translations',
      given: (tester) async {
        await tester.pumpWidget(buildSubject());
        _fillTitles(controllers, 'My Survey');
        await tester.pump();
      },
      when: (tester) async {
        await _tapCreateSurvey(tester);
      },
      then: (tester) async {
        expect(saveWasCalled, isTrue);
        expect(savedTitleTranslations!.valueFor('en'), 'My Survey');
      },
    );

    testWidgets('keeps generated slug in sync while title is still automatic', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      final titleField = _fieldFor(
        controllers.titleTranslations[defaultFormContentLocale]!,
      );
      await tester.enterText(titleField, 'C');
      await tester.pump();
      expect(controllers.slug.text, 'c');

      await tester.enterText(titleField, 'Customer Feedback');
      await tester.pump();
      expect(controllers.slug.text, 'customer-feedback');
    });

    testWidgets('does not overwrite manually edited slug', (tester) async {
      await tester.pumpWidget(buildSubject());

      final titleField = _fieldFor(
        controllers.titleTranslations[defaultFormContentLocale]!,
      );
      await tester.enterText(titleField, 'Customer');
      await tester.pump();
      expect(controllers.slug.text, 'customer');

      await tester.enterText(_fieldFor(controllers.slug), 'custom-slug');
      await tester.pump();
      await tester.enterText(titleField, 'Customer Feedback');
      await tester.pump();

      expect(controllers.slug.text, 'custom-slug');
    });

    scenarioWidget(
      'empty secondary titles block save',
      given: (tester) async {
        await tester.pumpWidget(buildSubject());
        controllers.titleTranslations[defaultFormContentLocale]!.text =
            'Primary Survey';
        await tester.pump();
      },
      when: (tester) async {
        await _tapCreateSurvey(tester);
      },
      then: (tester) async {
        expect(saveWasCalled, isFalse);
        expect(find.text('Title is required'), findsWidgets);
      },
    );

    testWidgets('submits only configured locales', (tester) async {
      await tester.pumpWidget(
        buildSubject(primaryLocale: 'ja', locales: const ['ja', 'de']),
      );
      controllers.titleTranslations['ja']!.text = '調査';
      controllers.titleTranslations['de']!.text = 'Umfrage';
      await tester.pump();

      await _tapCreateSurvey(tester);

      expect(savedTitleTranslations!.values.keys, ['ja', 'de']);
      expect(savedTitleTranslations!.valueFor('ja'), '調査');
      expect(savedTitleTranslations!.valueFor('de'), 'Umfrage');
    });
  });

  group('SurveyForm states', () {
    late SurveyFormControllers controllers;

    setUp(() {
      controllers = _controllers();
    });

    tearDown(() {
      controllers.dispose();
    });

    Widget buildSubject({bool isSaving = false, String? error}) {
      return localizedTestApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SurveyForm(
              controllers: controllers,
              isSaving: isSaving,
              error: error,
              primaryLocale: defaultFormContentLocale,
              onSave:
                  ({
                    required String slug,
                    required LocalizedText titleTranslations,
                    required LocalizedText descriptionTranslations,
                  }) async {},
            ),
          ),
        ),
      );
    }

    testWidgets('shows loading indicator when isSaving is true', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(isSaving: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Create Survey'), findsNothing);
    });

    testWidgets('disables fields when isSaving is true', (tester) async {
      await tester.pumpWidget(buildSubject(isSaving: true));

      final titleField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(titleField.enabled, isFalse);
    });

    testWidgets('displays error message when error is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(error: 'Failed to create survey: duplicate title'),
      );

      expect(
        find.text('Failed to create survey: duplicate title'),
        findsOneWidget,
      );
    });

    testWidgets('shows Create Survey button when not saving', (tester) async {
      await tester.pumpWidget(buildSubject(isSaving: false));

      expect(find.text('Create Survey'), findsOneWidget);
    });

    testWidgets('shows primary title and description with other languages', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Localized titles'), findsNothing);
      expect(find.text('Localized descriptions'), findsNothing);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Other languages'), findsWidgets);
      expect(find.text('Title (日本語)'), findsOneWidget);
    });
  });

  group('SurveyFormControllers', () {
    late SurveyFormControllers controllers;

    setUp(() {
      controllers = _controllers();
    });

    tearDown(() {
      controllers.dispose();
    });

    test('populateFrom fills titles and descriptions', () {
      controllers.populateFrom(_survey());

      expect(controllers.slug.text, 'title-en');
      for (final locale in formContentLocaleCodes) {
        expect(controllers.titleTranslations[locale]!.text, 'Title $locale');
        expect(
          controllers.descriptionTranslations[locale]!.text,
          'Description $locale',
        );
      }
    });

    test('titleValue and descriptionValue trim every locale', () {
      for (final locale in formContentLocaleCodes) {
        controllers.titleTranslations[locale]!.text = ' Title $locale ';
        controllers.descriptionTranslations[locale]!.text =
            ' Description $locale ';
      }

      final titles = controllers.titleValue();
      final descriptions = controllers.descriptionValue();

      for (final locale in formContentLocaleCodes) {
        expect(titles.valueFor(locale), 'Title $locale');
        expect(descriptions.valueFor(locale), 'Description $locale');
      }
    });
  });
}

SurveyFormControllers _controllers() => SurveyFormControllers(
  slug: TextEditingController(),
  titleTranslations: {
    for (final locale in formContentLocaleCodes)
      locale: TextEditingController(),
  },
  descriptionTranslations: {
    for (final locale in formContentLocaleCodes)
      locale: TextEditingController(),
  },
);

void _fillTitles(SurveyFormControllers controllers, String value) {
  for (final controller in controllers.titleTranslations.values) {
    controller.text = value;
  }
}

Future<void> _tapCreateSurvey(WidgetTester tester) async {
  final button = find.text('Create Survey');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Finder _fieldFor(TextEditingController controller) {
  return find.byWidgetPredicate(
    (widget) => widget is TextFormField && widget.controller == controller,
  );
}

Survey _survey() {
  final now = DateTime.utc(2026, 6, 22, 10);
  return Survey(
    id: 1,
    projectId: 1,
    slug: 'title-en',
    titleTranslations: LocalizedText({
      for (final locale in formContentLocaleCodes) locale: 'Title $locale',
    }),
    descriptionTranslations: LocalizedText({
      for (final locale in formContentLocaleCodes)
        locale: 'Description $locale',
    }),
    status: SurveyStatus.draft,
    createdAt: now,
    updatedAt: now,
  );
}
