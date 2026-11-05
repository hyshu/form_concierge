import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/widgets/question_form_dialog.dart';
import 'package:hux/hux.dart';

import '../support/localized_test_app.dart';

void main() {
  testWidgets('first question is always visible and offers no condition mode', (
    tester,
  ) async {
    VisibilityConditionMode? savedMode;
    await tester.pumpWidget(
      localizedTestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => QuestionFormDialog.show(
                context,
                existingQuestion: _question().copyWith(
                  visibilityConditionMode: VisibilityConditionMode.any,
                ),
                locales: const ['en'],
                visibilitySourceQuestions: const [],
                onSave:
                    ({
                      required textTranslations,
                      required type,
                      required isRequired,
                      required placeholderTranslations,
                      minLength,
                      maxLength,
                      minSelected,
                      maxSelected,
                      required visibilityConditionMode,
                      required visibilityRules,
                    }) {
                      savedMode = visibilityConditionMode;
                    },
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('The first question is always visible.'), findsOneWidget);
    expect(find.text('All rules'), findsNothing);
    expect(find.text('Any rule'), findsNothing);
    expect(find.text('When any condition matches'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(savedMode, VisibilityConditionMode.all);
  });

  testWidgets(
    'condition mode reveals editable fields and requires a comparison value',
    (tester) async {
      List<QuestionVisibilityRule>? savedRules;
      await tester.pumpWidget(
        localizedTestApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => QuestionFormDialog.show(
                  context,
                  existingQuestion: _question().copyWith(id: 2, orderIndex: 1),
                  locales: const ['en'],
                  visibilitySourceQuestions: [_question()],
                  onSave:
                      ({
                        required textTranslations,
                        required type,
                        required isRequired,
                        required placeholderTranslations,
                        minLength,
                        maxLength,
                        minSelected,
                        maxSelected,
                        required visibilityConditionMode,
                        required visibilityRules,
                      }) {
                        savedRules = visibilityRules;
                      },
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Always visible'));
      await tester.tap(find.text('Always visible'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('When any condition matches').last);
      await tester.pumpAndSettle();
      expect(find.text('Condition'), findsOneWidget);
      await tester.ensureVisible(find.byType(HuxDropdown<VisibilityOperator>));
      await tester.tap(find.byType(HuxDropdown<VisibilityOperator>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('equals').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(savedRules, isNull);
      expect(find.text('Enter a value for each condition.'), findsOneWidget);
      final value = find.byWidgetPredicate(
        (widget) => widget is HuxInput && widget.label == 'Value',
      );
      await tester.enterText(
        find.descendant(of: value, matching: find.byType(TextFormField)),
        'ready',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(savedRules!.single.value, 'ready');
    },
  );

  testWidgets('shows question type as read-only after publishing', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: QuestionFormDialog(
            existingQuestion: _question(),
            locales: const ['en'],
            canChangeType: false,
            onSave:
                ({
                  required textTranslations,
                  required type,
                  required isRequired,
                  required placeholderTranslations,
                  minLength,
                  maxLength,
                  minSelected,
                  maxSelected,
                  required visibilityConditionMode,
                  required visibilityRules,
                }) {},
          ),
        ),
      ),
    );

    expect(find.text('Short Text'), findsOneWidget);
    expect(
      find.text('Question type cannot be changed after publishing.'),
      findsOneWidget,
    );
    expect(find.byType(HuxDropdown<QuestionType>), findsNothing);
  });
}

Question _question() => Question(
  id: 1,
  surveyId: 1,
  textTranslations: const LocalizedText({'en': 'Question'}),
  type: QuestionType.textSingle,
  orderIndex: 0,
  isRequired: false,
  placeholderTranslations: const LocalizedText({'en': ''}),
);
