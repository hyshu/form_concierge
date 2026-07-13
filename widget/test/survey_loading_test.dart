import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge/src/widgets/survey_loading.dart';

void main() {
  testWidgets('uses the default top spacing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SurveyLoading())),
    );

    final indicator = tester.getTopLeft(find.byType(CircularProgressIndicator));
    expect(indicator.dy, 48);
    expect(
      tester.getCenter(find.byType(CircularProgressIndicator)).dx,
      tester.getSize(find.byType(Scaffold)).width / 2,
    );
  });

  testWidgets('lets the builder replace the entire loading layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SurveyLoading(
            builder: (context) => const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Text('Custom loading'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Custom loading'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.getTopLeft(find.text('Custom loading')).dy, 80);
  });
}
