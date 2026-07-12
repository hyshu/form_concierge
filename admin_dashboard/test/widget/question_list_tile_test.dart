import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/widgets/question_list_tile.dart';
import 'package:hux/hux.dart';

import '../support/localized_test_app.dart';

void main() {
  testWidgets('shows disabled edit and delete actions when editing is locked', (
    tester,
  ) async {
    var edited = false;
    var deleted = false;

    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: QuestionListTile(
            question: _question(),
            choices: const [],
            visibilityRules: const [],
            visibilityRuleEditor: const SizedBox.shrink(),
            enabled: false,
            onEdit: () => edited = true,
            onDelete: () => deleted = true,
            onAddChoice: (_) {},
            onUpdateChoice: (_, _) {},
            onDeleteChoice: (_) {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Edit question'), findsOneWidget);
    expect(find.byTooltip('Delete question'), findsOneWidget);

    final editButtonFinder = find.descendant(
      of: find.byTooltip('Edit question'),
      matching: find.byType(HuxButton),
    );
    final editButton = tester.widget<HuxButton>(editButtonFinder);
    expect(
      editButton.textColor,
      HuxTokens.textDisabled(tester.element(editButtonFinder)),
    );
    final mouseRegion = tester.widget<MouseRegion>(
      find
          .ancestor(
            of: find.byTooltip('Edit question'),
            matching: find.byType(MouseRegion),
          )
          .first,
    );
    expect(mouseRegion.cursor, SystemMouseCursors.forbidden);

    await tester.tap(find.byTooltip('Edit question'));
    await tester.tap(find.byTooltip('Delete question'));
    await tester.pump();

    expect(edited, isFalse);
    expect(deleted, isFalse);
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
