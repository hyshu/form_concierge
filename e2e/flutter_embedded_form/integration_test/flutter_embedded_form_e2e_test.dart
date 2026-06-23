import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_embedded_form/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('embedded in-app form submits a response', (tester) async {
    app.main();

    await _pumpUntil(tester, find.text('Open Survey'));
    await tester.tap(find.text('Open Survey'));

    await _pumpUntil(tester, find.text('Customer feedback'));
    await _pumpUntil(tester, find.text('Your name'));
    await tester.enterText(find.byType(TextField).first, 'In-app respondent');
    await tester.tap(find.text('Submit'));

    await _pumpUntil(tester, find.text('Survey submitted!'));
    expect(find.text('Survey submitted!'), findsWidgets);
  });
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for ${finder.toString()}');
}
