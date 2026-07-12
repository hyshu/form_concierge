import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mobile_full/main.dart';
import 'package:form_concierge/form_concierge.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('loads response replies and marks latest reply seen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final requests = <http.Request>[];
    final client = Client(
      'https://api.example.com',
      httpClient: MockClient((request) async {
        requests.add(request);
        expect(request.headers['authorization'], 'Bearer anon-token');
        return switch (request.url.path) {
          '/api/anonymous/replies' => _json([
            {
              'id': 7,
              'surveyResponseId': 42,
              'anonymousAccountId': 'anon-1',
              'body': 'Thanks for contacting us.',
              'adminId': 'admin-1',
              'createdAt': '2026-07-12T01:02:03.000Z',
              'readAt': null,
            },
          ]),
          '/api/anonymous/replies/latest' => _json({
            'latestReplyAt': '2026-07-12T01:02:03.000Z',
          }),
          _ => http.Response('Unexpected ${request.url}', 404),
        };
      }),
    );
    addTearDown(client.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [ExampleStringsDelegate()],
        home: RepliesScreen(
          client: client,
          prefs: prefs,
          anonymousToken: 'anon-token',
          responseId: 42,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Replies'), findsOneWidget);
    expect(find.text('Thanks for contacting us.'), findsOneWidget);
    expect(
      requests.map((request) => request.url.queryParameters['responseId']),
      everyElement('42'),
    );

    final seenKey = FormConciergeReplyChecker.defaultStorageKey(
      baseUri: client.baseUri,
      anonymousToken: 'anon-token',
      responseId: 42,
    );
    expect(prefs.getString(seenKey), '2026-07-12T01:02:03.000Z');
  });
}

http.Response _json(Object body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}
