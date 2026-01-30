import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/dashboard/presentation/widgets/survey_status_chip.dart';

void main() {
  group('SurveyStatusChip', () {
    Widget buildSubject(SurveyStatus status) {
      return MaterialApp(
        home: Scaffold(
          body: SurveyStatusChip(status: status),
        ),
      );
    }

    testWidgets('displays "Draft" for draft status', (tester) async {
      await tester.pumpWidget(buildSubject(SurveyStatus.draft));
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('displays "Published" for published status', (tester) async {
      await tester.pumpWidget(buildSubject(SurveyStatus.published));
      expect(find.text('Published'), findsOneWidget);
    });

    testWidgets('displays "Closed" for closed status', (tester) async {
      await tester.pumpWidget(buildSubject(SurveyStatus.closed));
      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('displays "Archived" for archived status', (tester) async {
      await tester.pumpWidget(buildSubject(SurveyStatus.archived));
      expect(find.text('Archived'), findsOneWidget);
    });

    testWidgets('all statuses render without errors', (tester) async {
      for (final status in SurveyStatus.values) {
        await tester.pumpWidget(buildSubject(status));
        expect(find.byType(SurveyStatusChip), findsOneWidget);
      }
    });
  });
}
