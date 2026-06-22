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

      expect(find.text('Name (English)'), findsOneWidget);
      expect(find.text('Other languages'), findsNothing);
      expect(find.text('Name (日本語)'), findsNothing);
      expect(find.byType(ExpansionTile), findsNothing);
    });

    testWidgets('shows two locales inline without expansion tile', (
      tester,
    ) async {
      await tester.pumpWidget(_subject(locales: const ['en', 'ja']));

      expect(find.text('Name (English)'), findsOneWidget);
      expect(find.text('Name (日本語)'), findsOneWidget);
      expect(find.text('Other languages'), findsNothing);
      expect(find.byType(ExpansionTile), findsNothing);
    });
  });
}

Widget _subject({required List<String> locales}) {
  final controllers = {
    for (final locale in formContentLocaleCodes)
      locale: TextEditingController(),
  };
  return localizedTestApp(
    locale: const Locale('en'),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: LocalizedTextFieldGroup(
          controllers: controllers,
          primaryLocale: 'en',
          locales: locales,
          labelText: 'Name',
        ),
      ),
    ),
  );
}
