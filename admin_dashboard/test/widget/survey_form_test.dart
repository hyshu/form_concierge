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

    scenarioWidget(
      'primary title is enough and empty secondary titles use primary text',
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
        expect(saveWasCalled, isTrue);
        for (final locale in formContentLocaleCodes) {
          expect(savedTitleTranslations!.valueFor(locale), 'Primary Survey');
        }
      },
    );

    testWidgets('submits only configured locales', (tester) async {
      await tester.pumpWidget(
        buildSubject(primaryLocale: 'ja', locales: const ['ja', 'de']),
      );
      controllers.titleTranslations['ja']!.text = '調査';
      await tester.pump();

      await _tapCreateSurvey(tester);

      expect(savedTitleTranslations!.values.keys, ['ja', 'de']);
      expect(savedTitleTranslations!.valueFor('ja'), '調査');
      expect(savedTitleTranslations!.valueFor('de'), '調査');
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

    testWidgets('hides secondary language fields behind expansion tiles', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Title (English)'), findsOneWidget);
      expect(find.text('Title (日本語)'), findsNothing);
      expect(find.text('Other languages'), findsNWidgets(2));

      await tester.tap(find.text('Other languages').first);
      await tester.pumpAndSettle();

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

Survey _survey() {
  final now = DateTime.utc(2026, 6, 22, 10);
  return Survey(
    id: 1,
    projectId: 1,
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
