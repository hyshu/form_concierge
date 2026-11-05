import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/widgets/question_list.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/widgets/visibility_rule_editor.dart';
import 'package:hux/hux.dart';

import '../support/localized_test_app.dart';

void main() {
  testWidgets('opens conditions after saving any rule in the question dialog', (
    tester,
  ) async {
    var question = _question(2, VisibilityConditionMode.all);
    Widget app() => localizedTestApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: QuestionList(
            surveyId: 1,
            questions: [_question(1, VisibilityConditionMode.all), question],
            choicesByQuestion: const {},
            visibilityRules: const [],
            locales: const ['en'],
            isLoading: false,
            enabled: true,
            onAddQuestion:
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
                }) {},
            onEditQuestion:
                (
                  edited, {
                  required textTranslations,
                  required type,
                  required isRequired,
                  required placeholderTranslations,
                  minLength,
                  maxLength,
                  minSelected,
                  maxSelected,
                  required visibilityConditionMode,
                }) {
                  question = edited.copyWith(
                    visibilityConditionMode: visibilityConditionMode,
                  );
                },
            onDeleteQuestion: (_) {},
            onAddChoice: (_, _) {},
            onUpdateChoice: (_, _) {},
            onDeleteChoice: (_) {},
            onSaveVisibility:
                ({required question, required mode, required rules}) async {},
          ),
        ),
      ),
    );

    await tester.pumpWidget(app());
    expect(find.text('Add rule'), findsNothing);
    await tester.tap(find.byTooltip('Edit question').last);
    await tester.pumpAndSettle();
    final mode = find.byType(HuxDropdown<VisibilityConditionMode>);
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Any rule').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(question.visibilityConditionMode, VisibilityConditionMode.any);
    await tester.ensureVisible(find.text('Add rule'));
    await tester.tap(find.text('Add rule'));
    await tester.pumpAndSettle();
    expect(find.text('Condition'), findsOneWidget);
  });

  testWidgets(
    'opens any-rule conditions and saves a rule for an earlier question',
    (
      tester,
    ) async {
      VisibilityConditionMode? savedMode;
      List<QuestionVisibilityRule>? savedRules;

      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VisibilityRuleEditor(
                surveyId: 1,
                targetQuestion: _question(2, VisibilityConditionMode.any),
                primaryLocale: 'en',
                sourceQuestions: [_question(1, VisibilityConditionMode.all)],
                choicesByQuestion: const {},
                rules: const [],
                enabled: true,
                onSave: ({required mode, required rules}) async {
                  savedMode = mode;
                  savedRules = rules;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add rule'));
      await tester.pumpAndSettle();
      expect(find.text('Question'), findsOneWidget);
      expect(find.text('Condition'), findsOneWidget);

      await tester.tap(find.byType(HuxDropdown<VisibilityOperator>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('equals').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Unsatisfied');
      await tester.ensureVisible(find.text('Save rules'));
      await tester.tap(find.text('Save rules'));
      await tester.pumpAndSettle();

      expect(savedMode, VisibilityConditionMode.any);
      expect(savedRules, hasLength(1));
      expect(savedRules!.single.sourceQuestionId, 1);
      expect(savedRules!.single.targetQuestionId, 2);
      expect(savedRules!.single.operator, VisibilityOperator.equals);
      expect(savedRules!.single.value, 'Unsatisfied');
    },
  );

  testWidgets('explains why the first question cannot have conditions', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: VisibilityRuleEditor(
            surveyId: 1,
            targetQuestion: _question(1, VisibilityConditionMode.any),
            primaryLocale: 'en',
            sourceQuestions: const [],
            choicesByQuestion: const {},
            rules: const [],
            enabled: true,
            onSave: ({required mode, required rules}) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Add an earlier question before creating rules.'),
      findsOneWidget,
    );
    expect(find.text('Add rule'), findsNothing);
  });
}

Question _question(int id, VisibilityConditionMode mode) => Question(
  id: id,
  surveyId: 1,
  textTranslations: LocalizedText({'en': 'Question $id'}),
  type: QuestionType.textSingle,
  orderIndex: id - 1,
  isRequired: false,
  placeholderTranslations: const LocalizedText({'en': ''}),
  visibilityConditionMode: mode,
);
