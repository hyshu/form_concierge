import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/core/capsules/client_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/capsules/survey_form_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/widgets/draft_questions_section.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rearch/rearch.dart';

import '../support/localized_test_app.dart';

void main() {
  testWidgets(
    'edits conditions before creating a survey and submits stable references',
    (
      tester,
    ) async {
      Map<String, dynamic>? submitted;
      final client = Client(
        'https://api.example.com',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/admin/surveys/with-questions');
          submitted = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              ...submitted!['survey'] as Map<String, dynamic>,
              'id': 1,
            }),
            201,
          );
        }),
      );
      addTearDown(client.close);
      final container = MockableContainer()
        ..mock(clientCapsule).apply((_) => client);
      addTearDown(container.dispose);
      final manager = container.read(surveyFormManagerCapsule);
      manager.addDraftQuestion(
        textTranslations: const LocalizedText({'en': 'Source question'}),
        type: QuestionType.singleChoice,
        isRequired: false,
        placeholderTranslations: const LocalizedText({'en': ''}),
        visibilityConditionMode: VisibilityConditionMode.all,
        firstChoiceTranslations: const LocalizedText({'en': 'One'}),
        secondChoiceTranslations: const LocalizedText({'en': 'Two'}),
      );

      Widget app() => localizedTestApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DraftQuestionsSection(
              formManager: manager,
              formState: manager.getState(null),
              aiGenerationEnabled: false,
              primaryLocale: 'en',
              locales: const ['en'],
            ),
          ),
        ),
      );

      await tester.pumpWidget(app());
      await tester.tap(find.text('Add Question'));
      await tester.pumpAndSettle();
      expect(
        find.text('Always visible'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField).first, 'More details?');
      final mode = find.text('Always visible');
      await tester.ensureVisible(mode);
      await tester.tap(mode);
      await tester.pumpAndSettle();
      await tester.tap(find.text('When any condition matches').last);
      await tester.pumpAndSettle();
      expect(find.text('Condition'), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
      await tester.tap(find.text('Add').last);
      await tester.pumpAndSettle();

      expect(
        manager
            .getState(null)
            .draftQuestions
            .last
            .toQuestionWithChoices()
            .visibilityConditionMode,
        VisibilityConditionMode.any,
      );

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit').last);
      await tester.pumpAndSettle();
      expect(find.text('When any condition matches'), findsOneWidget);
      expect(find.text('Condition'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Tell us more?');
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();

      final source = manager.getState(null).draftQuestions.first;
      final draft = manager.getState(null).draftQuestions.last;
      expect(draft.visibilityRules.single.sourceQuestionTempId, source.tempId);
      expect(draft.visibilityRules.single.value, source.choices.first.tempId);
      manager.addChoiceToDraftQuestion(
        source.tempId,
        const LocalizedText({'en': 'Other'}),
      );
      final created = await manager.createSurveyWithQuestions(
        projectId: 1,
        slug: 'feedback',
        titleTranslations: const LocalizedText({'en': 'Feedback'}),
        descriptionTranslations: const LocalizedText({'en': ''}),
      );

      expect(created?.id, 1);
      final question = (submitted!['questions'] as List).last;
      expect(question['visibilityConditionMode'], 'any');
      expect(question['textTranslations'], {'en': 'Tell us more?'});
      expect(question['choiceTranslations'], hasLength(2));
      expect(submitted!['visibilityRules'], [
        {
          'targetQuestionIndex': 1,
          'sourceQuestionIndex': 0,
          'operator': 'equals',
          'choiceIndex': 0,
        },
      ]);
    },
  );
}
