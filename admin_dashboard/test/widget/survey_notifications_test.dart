import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/core/capsules/client_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/capsules/survey_form_capsule.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/widgets/survey_form.dart';
import 'package:hux/hux.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rearch/rearch.dart';

import '../support/localized_test_app.dart';

void main() {
  for (final previousEmail in [null, 'previous@example.com']) {
    testWidgets('new survey notifications use previous email $previousEmail', (
      tester,
    ) async {
      final container = CapsuleContainer();
      addTearDown(container.dispose);
      final controllers = container.read(surveyFormControllersCapsule);
      final key = GlobalKey<SurveyFormWidgetState>();
      bool? savedEnabled;
      String? savedEmail;

      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SurveyForm(
                key: key,
                controllers: controllers,
                isSaving: false,
                primaryLocale: 'en',
                locales: const ['en'],
                initialNotificationRecipientEmail: previousEmail,
                onSave:
                    ({
                      required slug,
                      required titleTranslations,
                      required descriptionTranslations,
                      required followUpEnabled,
                      required followUpPrompt,
                      required captchaEnabled,
                      required notificationsEnabled,
                      required notificationRecipientEmail,
                    }) async {
                      savedEnabled = notificationsEnabled;
                      savedEmail = notificationRecipientEmail;
                    },
              ),
            ),
          ),
        ),
      );

      final toggle = find.widgetWithText(SwitchListTile, 'Notifications');
      expect(
        tester.widget<SwitchListTile>(toggle).value,
        previousEmail != null,
      );
      final input = tester.widget<HuxInput>(
        find.byWidgetPredicate(
          (widget) => widget is HuxInput && widget.label == 'Recipient Email',
        ),
      );
      expect(input.controller!.text, previousEmail ?? '');
      controllers.titleTranslations['en']!.text = 'Feedback';
      expect(await key.currentState!.submit(), isTrue);
      expect(savedEnabled, previousEmail != null);
      expect(savedEmail, previousEmail);

      // Switching notification state must keep the entered address available.
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(toggle).value,
        previousEmail == null,
      );
      if (previousEmail == null) {
        expect(await key.currentState!.submit(), isFalse);
        await tester.pump();
        expect(find.text('Email is required'), findsOneWidget);
        input.controller!.text = 'invalid';
        expect(await key.currentState!.submit(), isFalse);
        await tester.pump();
        expect(find.text('Enter a valid email address'), findsOneWidget);
        input.controller!.text = 'new@example.com';
      }
      expect(await key.currentState!.submit(), isTrue);
      expect(savedEnabled, previousEmail == null);
      expect(savedEmail, previousEmail ?? 'new@example.com');
    });
  }

  test(
    'survey creation loads the suggested address and saves chosen notifications',
    () async {
      Map<String, dynamic>? submitted;
      final now = DateTime.utc(2026);
      final project = Project(
        id: 1,
        slug: 'demo',
        name: 'Demo',
        supportedLocales: const ['en'],
        defaultLocale: 'en',
        createdAt: now,
        updatedAt: now,
      );
      final client = Client(
        'https://api.example.com',
        httpClient: MockClient((request) async {
          if (request.method == 'GET') {
            expect(request.url.path, '/api/admin/projects/1');
            return http.Response(
              jsonEncode({
                'project': project.toJson(),
                'surveys': [],
                'notificationRecipientEmail': 'previous@example.com',
              }),
              200,
            );
          }
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
      await manager.loadProject(1);
      expect(
        manager.getState(null).notificationRecipientEmail,
        'previous@example.com',
      );

      final created = await manager.createSurveyWithQuestions(
        projectId: 1,
        slug: 'feedback',
        titleTranslations: const LocalizedText({'en': 'Feedback'}),
        descriptionTranslations: const LocalizedText({'en': ''}),
        notificationsEnabled: false,
        notificationRecipientEmail: 'override@example.com',
      );
      expect(created?.id, 1);
      expect(submitted!['notifications'], {
        'enabled': false,
        'recipientEmail': 'override@example.com',
      });
    },
  );
}
