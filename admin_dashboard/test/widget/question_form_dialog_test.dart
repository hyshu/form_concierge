import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/widgets/question_form_dialog.dart';
import 'package:hux/hux.dart';

import '../support/localized_test_app.dart';

void main() {
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
