import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mobile_simple/main.dart';

void main() {
  testWidgets('renders simple mobile example home', (tester) async {
    await tester.pumpWidget(const FlutterMobileSimpleApp());

    expect(find.text('Flutter Mobile Simple'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Open form'), findsOneWidget);
  });
}
