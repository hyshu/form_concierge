import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/surveys/presentation/widgets/localized_text_field_group.dart';

import '../support/localized_test_app.dart';

void main() {
  group('LocalizedTextFieldGroup', () {
    testWidgets('hides other languages section for a single locale', (
      tester,
    ) async {
      await tester.pumpWidget(_subject(locales: const ['en']));

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Other languages'), findsNothing);
      expect(find.text('Name (日本語)'), findsNothing);
    });

    testWidgets('shows primary locale and collapses secondary languages', (
      tester,
    ) async {
      await tester.pumpWidget(_subject(locales: const ['en', 'ja']));

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Other languages'), findsOneWidget);
      // Secondary fields stay mounted for validation but start collapsed.
      expect(find.text('Name (日本語)'), findsOneWidget);

      await tester.tap(find.text('Other languages'));
      await tester.pumpAndSettle();
      expect(find.text('Name (日本語)'), findsOneWidget);
    });

    testWidgets('validates collapsed required secondary locales', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _subject(
          locales: const ['en', 'ja'],
          formKey: formKey,
          requiredMessage: 'Name is required',
        ),
      );

      // Fill only the primary language.
      await tester.enterText(find.byType(TextFormField).first, 'Primary');
      await tester.pump();

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Name is required'), findsWidgets);
    });
  });
}

Widget _subject({
  required List<String> locales,
  GlobalKey<FormState>? formKey,
  String? requiredMessage,
}) {
  final controllers = {
    for (final locale in formContentLocaleCodes)
      locale: TextEditingController(),
  };
  return localizedTestApp(
    locale: const Locale('en'),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: LocalizedTextFieldGroup(
            controllers: controllers,
            primaryLocale: 'en',
            locales: locales,
            labelText: 'Name',
            requiredMessage: requiredMessage,
          ),
        ),
      ),
    ),
  );
}
