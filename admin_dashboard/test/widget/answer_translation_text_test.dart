import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_flutter/src/features/responses/presentation/widgets/answer_translation_text.dart';

import '../support/localized_test_app.dart';

void main() {
  testWidgets('keeps original and adds translated text directly below', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('ja'),
        home: const Scaffold(
          body: AnswerTranslationText(
            originalText: 'Original answer',
            translation: '翻訳された回答',
          ),
        ),
      ),
    );

    expect(find.text('Original answer'), findsOneWidget);
    expect(find.text('翻訳された回答'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Original answer')).dy,
      lessThan(tester.getTopLeft(find.text('翻訳された回答')).dy),
    );
    expect(find.textContaining('翻訳（'), findsNothing);
  });

  testWidgets('translation action uses existing sparkle button', (
    tester,
  ) async {
    var translated = false;
    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('ja'),
        home: Scaffold(
          body: AnswerTranslationText(
            originalText: 'Original answer',
            onTranslate: () => translated = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('回答を翻訳'));
    expect(translated, isTrue);
  });
}
