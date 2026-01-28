import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/capsules/survey_form_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/widgets/survey_form.dart';

import '../support/given_when_then.dart';

void main() {
  group('SurveyForm validation', () {
    late SurveyFormControllers controllers;
    late bool saveWasCalled;
    late String? savedTitle;
    late String? savedSlug;

    setUp(() {
      controllers = SurveyFormControllers(
        title: TextEditingController(),
        slug: TextEditingController(),
        description: TextEditingController(),
      );
      saveWasCalled = false;
      savedTitle = null;
      savedSlug = null;
    });

    tearDown(() {
      controllers.dispose();
    });

    Widget buildSubject({bool isSaving = false, String? error}) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SurveyForm(
              controllers: controllers,
              isSaving: isSaving,
              error: error,
              onSave:
                  ({
                    required String title,
                    required String slug,
                    String? description,
                    required AuthRequirement authRequirement,
                  }) async {
                    saveWasCalled = true;
                    savedTitle = title;
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
        await tester.tap(find.text('Create Survey'));
        await tester.pumpAndSettle();
      },
      then: (tester) async {
        expect(find.text('Title is required'), findsOneWidget);
        expect(saveWasCalled, isFalse);
      },
    );

    scenarioWidget(
      'empty slug shows validation error',
      given: (tester) async {
        await tester.pumpWidget(buildSubject());
        controllers.title.text = 'My Survey';
      },
      when: (tester) async {
        await tester.tap(find.text('Create Survey'));
        await tester.pumpAndSettle();
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
        controllers.title.text = 'My Survey';
        controllers.slug.text = 'Invalid-Slug';
      },
      when: (tester) async {
        await tester.tap(find.text('Create Survey'));
        await tester.pumpAndSettle();
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
        controllers.title.text = 'My Survey';
        controllers.slug.text = 'invalid_slug!';
      },
      when: (tester) async {
        await tester.tap(find.text('Create Survey'));
        await tester.pumpAndSettle();
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
        await tester.enterText(find.byType(TextFormField).at(0), 'My Survey');
        await tester.enterText(find.byType(TextFormField).at(1), 'my-survey');
        await tester.pump();
      },
      when: (tester) async {
        await tester.tap(find.text('Create Survey'));
        await tester.pumpAndSettle();
      },
      then: (tester) async {
        expect(saveWasCalled, isTrue);
        expect(savedTitle, 'My Survey');
        expect(savedSlug, 'my-survey');
      },
    );

    scenarioWidget(
      'slug with numbers and hyphens is valid',
      given: (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.enterText(find.byType(TextFormField).at(0), 'Survey 2024');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'survey-2024-v1',
        );
        await tester.pump();
      },
      when: (tester) async {
        await tester.tap(find.text('Create Survey'));
        await tester.pumpAndSettle();
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
      controllers = SurveyFormControllers(
        title: TextEditingController(),
        slug: TextEditingController(),
        description: TextEditingController(),
      );
    });

    tearDown(() {
      controllers.dispose();
    });

    Widget buildSubject({bool isSaving = false, String? error}) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SurveyForm(
              controllers: controllers,
              isSaving: isSaving,
              error: error,
              onSave:
                  ({
                    required String title,
                    required String slug,
                    String? description,
                    required AuthRequirement authRequirement,
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
