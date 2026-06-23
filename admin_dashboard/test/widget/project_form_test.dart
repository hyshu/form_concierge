import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/dashboard/presentation/widgets/project_form.dart';

import '../support/localized_test_app.dart';

void main() {
  group('ProjectForm', () {
    testWidgets('submits selected localized languages and project name', (
      tester,
    ) async {
      Project? savedProject;

      await tester.pumpWidget(
        localizedTestApp(
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectForm(
                isSaving: false,
                onSave: (project) async {
                  savedProject = project;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select languages'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('project-locale-ja')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Customer Feedback',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'feedback');
      await tester.ensureVisible(find.text('Create Project'));
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      expect(savedProject, isNotNull);
      expect(savedProject!.supportedLocales, ['en', 'ja']);
      expect(savedProject!.defaultLocale, 'en');
      expect(savedProject!.name, 'Customer Feedback');
    });

    testWidgets('uses admin locale as initial project language', (
      tester,
    ) async {
      Project? savedProject;

      await tester.pumpWidget(
        localizedTestApp(
          locale: const Locale('ja', 'JP'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectForm(
                isSaving: false,
                onSave: (project) async {
                  savedProject = project;
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        '顧客フィードバック',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'feedback');
      await tester.ensureVisible(find.text('プロジェクトを作成'));
      await tester.tap(find.text('プロジェクトを作成'));
      await tester.pumpAndSettle();

      expect(savedProject, isNotNull);
      expect(savedProject!.supportedLocales, ['ja']);
      expect(savedProject!.defaultLocale, 'ja');
      expect(savedProject!.name, '顧客フィードバック');
    });

    testWidgets('fills slug from English project name when slug is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedTestApp(
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectForm(
                isSaving: false,
                onSave: (_) async {},
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Customer Feedback',
      );
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      final slugField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      expect(slugField.controller!.text, 'customer-feedback');
    });
  });
}
