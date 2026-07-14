import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/responses/presentation/capsules/answer_translation_capsule.dart';
import 'package:form_concierge_flutter/src/features/responses/presentation/widgets/question_result_card.dart';

import '../support/localized_test_app.dart';

void main() {
  testWidgets('aggregated result reads translation from shared answer key', (
    tester,
  ) async {
    final client = Client('https://api.example.com');
    addTearDown(client.close);
    final key = mainAnswerTranslationKey(
      responseId: 7,
      questionId: 11,
      targetLocale: 'ja',
    );
    final bindings = AnswerTranslationBindings(
      enabled: true,
      targetLocale: 'ja',
      state: AnswerTranslationState(
        translations: {key: '共有された翻訳'},
      ),
      translate: ({required key, required sourceText, sourceLocale}) async =>
          true,
    );

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('ja'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: QuestionResultCard(
              client: client,
              result: QuestionResult(
                questionId: 11,
                questionText: 'Comment',
                questionType: QuestionType.textMultiLine,
                textResponses: const ['좋아요'],
                individualAnswers: [
                  IndividualAnswer(
                    responseId: 7,
                    submittedAt: DateTime.utc(2026, 7, 14, 9, 30),
                    responseLocale: 'ko',
                    textValue: '좋아요',
                  ),
                ],
              ),
              choices: const [],
              totalResponses: 1,
              answerTranslations: bindings,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('좋아요'));
    await tester.pumpAndSettle();

    expect(find.text('共有された翻訳'), findsOneWidget);
  });
}
