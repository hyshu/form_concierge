import 'package:flutter_test/flutter_test.dart';

/// Given-When-Then style test helper for BDD-style widget tests.
///
/// Example:
/// ```dart
/// scenarioWidget(
///   'empty title shows validation error',
///   given: (tester) async {
///     await tester.pumpWidget(buildSubject());
///   },
///   when: (tester) async {
///     await tester.tap(find.text('Submit'));
///     await tester.pumpAndSettle();
///   },
///   then: (tester) async {
///     expect(find.text('Title is required'), findsOneWidget);
///   },
/// );
/// ```
void scenarioWidget(
  String description, {
  required Future<void> Function(WidgetTester tester) given,
  required Future<void> Function(WidgetTester tester) when,
  required Future<void> Function(WidgetTester tester) then,
}) {
  testWidgets(description, (tester) async {
    await given(tester);
    await when(tester);
    await then(tester);
  });
}
