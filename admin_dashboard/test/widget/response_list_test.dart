import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/responses/presentation/capsules/answer_translation_capsule.dart';
import 'package:form_concierge_flutter/src/features/responses/presentation/widgets/response_list.dart';

import '../support/localized_test_app.dart';

void main() {
  testWidgets('shows replied badge and every reply below answers', (
    tester,
  ) async {
    final client = Client('https://api.example.com');
    addTearDown(client.close);
    var expandedResponseId = 0;
    final translationKey = mainAnswerTranslationKey(
      responseId: 7,
      questionId: 11,
      targetLocale: 'ja',
    );
    final translationBindings = AnswerTranslationBindings(
      enabled: true,
      targetLocale: 'ja',
      state: AnswerTranslationState(
        translations: {translationKey: 'Shared translation'},
      ),
      translate: ({required key, required sourceText, sourceLocale}) async =>
          true,
    );

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('ja'),
        home: Scaffold(
          body: ResponseList(
            client: client,
            responses: [
              SurveyResponse(
                id: 7,
                surveyId: 1,
                submittedAt: DateTime.utc(2026, 7, 14, 9, 30),
                metadata: const {'locale': 'ko'},
                replyCount: 2,
              ),
            ],
            totalCount: 1,
            currentPage: 0,
            totalPages: 1,
            isLoading: false,
            canManageResponses: true,
            questions: const [
              Question(
                id: 11,
                surveyId: 1,
                textTranslations: LocalizedText({'en': 'Comment'}),
                type: QuestionType.textMultiLine,
                orderIndex: 0,
                placeholderTranslations: LocalizedText({'en': ''}),
              ),
            ],
            answersByResponseId: const {
              7: [
                Answer(
                  id: 21,
                  surveyResponseId: 7,
                  questionId: 11,
                  textValue: 'Original answer',
                ),
              ],
            },
            repliesByResponseId: {
              7: [
                AdminReply(
                  id: 32,
                  surveyResponseId: 7,
                  anonymousAccountId: 'account-1',
                  body: 'Second reply',
                  createdAt: DateTime.utc(2026, 7, 14, 11),
                ),
                AdminReply(
                  id: 31,
                  surveyResponseId: 7,
                  anonymousAccountId: 'account-1',
                  body: 'First reply',
                  createdAt: DateTime.utc(2026, 7, 14, 10),
                ),
              ],
            },
            answerTranslations: translationBindings,
            onPageChange: (_) {},
            onDelete: (_) {},
            onReply: (_) {},
            onExpandAnswers: (responseId) => expandedResponseId = responseId,
          ),
        ),
      ),
    );

    expect(find.text('返信済み'), findsOneWidget);

    await tester.tap(find.text('2026-07-14 09:30'));
    await tester.pumpAndSettle();

    expect(expandedResponseId, 7);
    expect(find.text('Original answer'), findsOneWidget);
    expect(find.text('Shared translation'), findsOneWidget);
    expect(find.text('First reply'), findsOneWidget);
    expect(find.text('Second reply'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Original answer')).dy,
      lessThan(tester.getTopLeft(find.text('First reply')).dy),
    );
    expect(
      tester.getTopLeft(find.text('First reply')).dy,
      lessThan(tester.getTopLeft(find.text('Second reply')).dy),
    );
  });
}
