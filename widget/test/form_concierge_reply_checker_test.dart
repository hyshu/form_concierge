import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_survey_widget/form_concierge_survey_widget.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const latestIso = '2026-06-22T10:15:30.000Z';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FormConciergeReplyCheckResult', () {
    test('hasNewReplies is false when latest reply is absent', () {
      const result = FormConciergeReplyCheckResult(
        latestReplyAt: null,
        lastSeenReplyAt: null,
      );

      expect(result.hasNewReplies, isFalse);
    });

    test('hasNewReplies is true when no local seen timestamp exists', () {
      final result = FormConciergeReplyCheckResult(
        latestReplyAt: DateTime.parse(latestIso),
        lastSeenReplyAt: null,
      );

      expect(result.hasNewReplies, isTrue);
    });

    test(
      'hasNewReplies compares latest server timestamp with local seen timestamp',
      () {
        final latest = DateTime.parse(latestIso);

        expect(
          FormConciergeReplyCheckResult(
            latestReplyAt: latest,
            lastSeenReplyAt: latest.subtract(const Duration(seconds: 1)),
          ).hasNewReplies,
          isTrue,
        );
        expect(
          FormConciergeReplyCheckResult(
            latestReplyAt: latest,
            lastSeenReplyAt: latest,
          ).hasNewReplies,
          isFalse,
        );
        expect(
          FormConciergeReplyCheckResult(
            latestReplyAt: latest,
            lastSeenReplyAt: latest.add(const Duration(seconds: 1)),
          ).hasNewReplies,
          isFalse,
        );
      },
    );
  });

  group('FormConciergeReplyChecker', () {
    test(
      'defaultStorageKey scopes by base URI, response ID, and hashed token',
      () {
        final key = FormConciergeReplyChecker.defaultStorageKey(
          baseUri: Uri.parse('https://api.example.com'),
          anonymousToken: 'secret-token',
          responseId: 42,
        );

        expect(key, startsWith('form_concierge.reply_seen.'));
        expect(key, contains('https://api.example.com'));
        expect(key, contains('response_42'));
        expect(key, isNot(contains('secret-token')));
      },
    );

    test('check fetches latest reply timestamp with bearer token', () async {
      final requests = <http.Request>[];
      final checker = FormConciergeReplyChecker(
        client: _client((request) {
          requests.add(request);
          expect(request.method, 'GET');
          expect(request.url.path, '/api/anonymous/replies/latest');
          expect(request.url.queryParameters, {'responseId': '7'});
          expect(request.headers['authorization'], 'Bearer token-1');
          return _json({'latestReplyAt': latestIso});
        }),
        anonymousToken: 'token-1',
        responseId: 7,
      );

      final result = await checker.check();

      expect(requests, hasLength(1));
      expect(result.latestReplyAt, DateTime.parse(latestIso));
      expect(result.lastSeenReplyAt, isNull);
      expect(result.hasNewReplies, isTrue);
      expect(await checker.readLastSeenReplyAt(), isNull);
    });

    test('check(markSeen: true) stores latest timestamp locally', () async {
      final checker = FormConciergeReplyChecker(
        client: _client((request) => _json({'latestReplyAt': latestIso})),
        anonymousToken: 'token-2',
      );

      final result = await checker.check(markSeen: true);

      expect(result.hasNewReplies, isTrue);
      expect(await checker.readLastSeenReplyAt(), DateTime.parse(latestIso));
    });

    test('markLatestSeen and clearSeen update local timestamp only', () async {
      final checker = FormConciergeReplyChecker(
        client: _client((request) => _json({'latestReplyAt': latestIso})),
        anonymousToken: 'token-3',
      );

      await checker.markLatestSeen();
      expect(await checker.readLastSeenReplyAt(), DateTime.parse(latestIso));

      await checker.clearSeen();
      expect(await checker.readLastSeenReplyAt(), isNull);
    });

    test('check handles no server replies', () async {
      final checker = FormConciergeReplyChecker(
        client: _client((request) => _json({'latestReplyAt': null})),
        anonymousToken: 'token-4',
      );

      final result = await checker.check(markSeen: true);

      expect(result.latestReplyAt, isNull);
      expect(result.hasNewReplies, isFalse);
      expect(await checker.readLastSeenReplyAt(), isNull);
    });
  });
}

Client _client(http.Response Function(http.Request request) handler) {
  return Client(
    'https://api.example.com',
    httpClient: MockClient((request) async => handler(request)),
  );
}

http.Response _json(Object? body) {
  return http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}
