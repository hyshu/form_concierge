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
    late String? savedSlug;

    setUp(() {
      controllers = _controllers();
      saveWasCalled = false;
      savedTitleTranslations = null;
      savedSlug = null;
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
              onSave:
                  ({
                    required String defaultLocale,
                    required String slug,
                    required LocalizedText titleTranslations,
                    required LocalizedText descriptionTranslations,
                  }) async {
                    saveWasCalled = true;
                    savedTitleTranslations = titleTranslations;
                    savedSlug = slug;
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
        controllers.slug.text = 'valid-slug';
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
      'empty slug shows validation error',
      given: (tester) async {
        await tester.pumpWidget(buildSubject());
        _fillTitles(controllers, 'My Survey');
      },
      when: (tester) async {
        await _tapCreateSurvey(tester);
      },
      then: (tester) async {
        expect(find.text('Slug is required'), findsOneWidget);
        expect(saveWasCalled, isFalse);
      },
    );

    scenarioWidget(
      'slug with uppercase letters shows validation error',
      given: (tester) async {
        await tester.pumpWidget(buildSubject());
        _fillTitles(controllers, 'My Survey');
        controllers.slug.text = 'Invalid-Slug';
      },
      when: (tester) async {
        await _tapCreateSurvey(tester);
      },
      then: (tester) async {
        expect(
          find.text('Only lowercase letters, numbers, and hyphens allowed'),
          findsOneWidget,
        );
        expect(saveWasCalled, isFalse);
      },
    );

    scenarioWidget(
      'slug with special characters shows validation error',
      given: (tester) async {
        await tester.pumpWidget(buildSubject());
        _fillTitles(controllers, 'My Survey');
        controllers.slug.text = 'invalid_slug!';
      },
      when: (tester) async {
        await _tapCreateSurvey(tester);
      },
      then: (tester) async {
        expect(
          find.text('Only lowercase letters, numbers, and hyphens allowed'),
          findsOneWidget,
        );
        expect(saveWasCalled, isFalse);
      },
    );

    scenarioWidget(
      'valid form calls onSave with correct values',
      given: (tester) async {
        await tester.pumpWidget(buildSubject());
        _fillTitles(controllers, 'My Survey');
        controllers.slug.text = 'my-survey';
        await tester.pump();
      },
      when: (tester) async {
        await _tapCreateSurvey(tester);
      },
      then: (tester) async {
        expect(saveWasCalled, isTrue);
        expect(savedTitleTranslations!.valueFor('en'), 'My Survey');
        expect(savedSlug, 'my-survey');
      },
    );

    scenarioWidget(
      'slug with numbers and hyphens is valid',
      given: (tester) async {
        await tester.pumpWidget(buildSubject());
        _fillTitles(controllers, 'Survey 2024');
        controllers.slug.text = 'survey-2024-v1';
        await tester.pump();
      },
      when: (tester) async {
        await _tapCreateSurvey(tester);
      },
      then: (tester) async {
        expect(saveWasCalled, isTrue);
        expect(savedSlug, 'survey-2024-v1');
      },
    );
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
              onSave:
                  ({
                    required String defaultLocale,
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
        buildSubject(error: 'A survey with this slug already exists'),
      );

      expect(
        find.text('A survey with this slug already exists'),
        findsOneWidget,
      );
    });

    testWidgets('shows Create Survey button when not saving', (tester) async {
      await tester.pumpWidget(buildSubject(isSaving: false));

      expect(find.text('Create Survey'), findsOneWidget);
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
