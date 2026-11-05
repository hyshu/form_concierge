import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/core/capsules/client_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/capsules/survey_form_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/widgets/draft_questions_section.dart';
import 'package:hux/hux.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rearch/rearch.dart';

import '../support/localized_test_app.dart';

void main() {
  testWidgets('keeps any-rule selection through draft editing and submission', (
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
      find.text(
        'Add conditions from Visibility rules → Add rule below this question. For a new survey, create it first. With no rules, this question is always visible.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField).first, 'More details?');
    final mode = find.byType(HuxDropdown<VisibilityConditionMode>);
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Any rule').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(
      manager
          .getState(null)
          .draftQuestions
          .single
          .toQuestionWithChoices()
          .visibilityConditionMode,
      VisibilityConditionMode.any,
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<HuxDropdown<VisibilityConditionMode>>(mode).value,
      VisibilityConditionMode.any,
    );
    await tester.enterText(find.byType(TextFormField).first, 'Tell us more?');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    final draft = manager.getState(null).draftQuestions.single;
    manager.addChoiceToDraftQuestion(
      draft.tempId,
      const LocalizedText({'en': 'Other'}),
    );
    final created = await manager.createSurveyWithQuestions(
      projectId: 1,
      slug: 'feedback',
      titleTranslations: const LocalizedText({'en': 'Feedback'}),
      descriptionTranslations: const LocalizedText({'en': ''}),
    );

    expect(created?.id, 1);
    final question = (submitted!['questions'] as List).single;
    expect(question['visibilityConditionMode'], 'any');
    expect(question['textTranslations'], {'en': 'Tell us more?'});
    expect(question['choiceTranslations'], hasLength(3));
  });
}
