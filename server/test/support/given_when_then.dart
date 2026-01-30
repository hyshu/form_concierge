import 'package:test/test.dart';

/// Given-When-Then style test helper for BDD-style unit tests.
///
/// Example:
/// ```dart
/// scenario(
///   'published survey without date restrictions accepts responses',
///   given: () {
///     status = SurveyStatus.published;
///     startsAt = null;
///   },
///   when: () {
///     result = SurveyRules.isAcceptingResponses(...);
///   },
///   then: () {
///     expect(result, isTrue);
///   },
/// );
/// ```
void scenario(
  String description, {
  required void Function() given,
  required void Function() when,
  required void Function() then,
}) {
  test(description, () {
    given();
    when();
    then();
  });
}

/// Async version of [scenario] for tests that require async setup or assertions.
void scenarioAsync(
  String description, {
  required Future<void> Function() given,
  required Future<void> Function() when,
  required Future<void> Function() then,
}) {
  test(description, () async {
    await given();
    await when();
    await then();
  });
}
