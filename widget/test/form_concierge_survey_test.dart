import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge/form_concierge.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('loads survey, creates anonymous session, and submits response', (
    tester,
  ) async {
    final requests = <http.Request>[];
    AnonymousSession? anonymousSession;
    SurveyResponse? submittedResponse;

    final client = _client((request) {
      requests.add(request);
      return switch ((request.method, request.url.path)) {
        ('GET', '/api/projects/customer-feedback') => _json(_projectJson()),
        ('GET', '/api/surveys/id/1/questions') => _json([]),
        ('GET', '/api/surveys/id/1/visibility-rules') => _json([]),
        ('POST', '/api/anonymous/accounts') => _json(_anonymousSessionJson()),
        ('POST', '/api/surveys/id/1/responses') => () {
          expect(request.headers['authorization'], 'Bearer anon-token');
          return _json(_responseJson());
        }(),
        _ => http.Response('Unexpected ${request.method} ${request.url}', 404),
      };
    });

    await tester.pumpWidget(
      MaterialApp(
        home: FormConciergeSurvey(
          client: client,
          projectSlug: 'customer-feedback',
          onAnonymousSession: (session) => anonymousSession = session,
          onResponseSubmitted: (response, _) => submittedResponse = response,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer feedback'), findsOneWidget);
    expect(find.text('Tell us what you think'), findsOneWidget);
    // Anonymous account is created lazily on submit, not on load.
    expect(anonymousSession, isNull);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(anonymousSession?.token, 'anon-token');
    expect(submittedResponse?.id, 99);
    expect(find.text('Thank you!'), findsOneWidget);
    expect(
      find.text('Your response to "Customer feedback" has been submitted.'),
      findsOneWidget,
    );
    expect(
      requests.map((request) => '${request.method} ${request.url.path}'),
      containsAllInOrder([
        'GET /api/projects/customer-feedback',
        'GET /api/surveys/id/1/questions',
        'GET /api/surveys/id/1/visibility-rules',
        'POST /api/anonymous/accounts',
        'POST /api/surveys/id/1/responses',
      ]),
    );
  });

  testWidgets('selects survey by slug when provided', (tester) async {
    final paths = <String>[];
    final client = _client((request) {
      paths.add('${request.method} ${request.url.path}');
      return switch ((request.method, request.url.path)) {
        ('GET', '/api/projects/customer-feedback') => _json(
          _projectJson(
            surveys: [
              _surveyJson(),
              _surveyJson(id: 2, slug: 'nps'),
            ],
          ),
        ),
        ('GET', '/api/surveys/id/2/questions') => _json([]),
        ('GET', '/api/surveys/id/2/visibility-rules') => _json([]),
        ('POST', '/api/anonymous/accounts') => _json(_anonymousSessionJson()),
        _ => http.Response('Unexpected ${request.method} ${request.url}', 404),
      };
    });

    await tester.pumpWidget(
      MaterialApp(
        home: FormConciergeSurvey(
          client: client,
          projectSlug: 'customer-feedback',
          surveySlug: 'nps',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(paths, contains('GET /api/surveys/id/2/questions'));
    expect(find.text('Customer feedback'), findsOneWidget);
  });

  testWidgets('keeps follow-up open until completion Done action', (
    tester,
  ) async {
    SurveyResponse? mainResponse;
    SurveyResponse? followUpResponse;
    var done = false;
    final client = _client((request) {
      return switch ((request.method, request.url.path)) {
        ('GET', '/api/projects/customer-feedback') => _json(
          _projectJson(surveys: [_surveyJson(followUpEnabled: true)]),
        ),
        ('GET', '/api/surveys/id/1/questions') => _json([]),
        ('GET', '/api/surveys/id/1/visibility-rules') => _json([]),
        ('POST', '/api/anonymous/accounts') => _json(_anonymousSessionJson()),
        ('POST', '/api/surveys/id/1/responses') => _json(_responseJson()),
        ('POST', '/api/responses/99/follow-up/generate') => _json({
          'needed': true,
          'followUp': {
            'version': 1,
            'status': 'pending',
            'generatedAt': '2026-06-22T10:02:00.000Z',
            'completedAt': null,
            'locale': 'en',
            'items': [
              {
                'id': 'detail',
                'type': 'textSingle',
                'text': 'Could you add one detail?',
                'required': false,
                'placeholder': null,
                'maxFiles': null,
                'choices': [],
                'answer': null,
              },
            ],
          },
          'error': null,
        }),
        ('PUT', '/api/responses/99/follow-up') => _json(_responseJson()),
        _ => http.Response('Unexpected ${request.method} ${request.url}', 404),
      };
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormConciergeSurvey(
            client: client,
            projectSlug: 'customer-feedback',
            onResponseSubmitted: (response, _) => mainResponse = response,
            onFollowUpSubmitted: (response) => followUpResponse = response,
            onDone: () => done = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(mainResponse?.id, 99);
    expect(done, isFalse);
    expect(find.text('A few more questions'), findsOneWidget);
    expect(find.text('Could you add one detail?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'More context');
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(followUpResponse?.id, 99);
    expect(find.text('Thank you!'), findsOneWidget);
    expect(done, isFalse);

    await tester.tap(find.text('Done'));
    expect(done, isTrue);
  });

  testWidgets('supplies CAPTCHA token for CAPTCHA-enabled surveys', (
    tester,
  ) async {
    String? submittedCaptchaToken;
    final client = _client((request) {
      return switch ((request.method, request.url.path)) {
        ('GET', '/api/projects/customer-feedback') => _json(
          _projectJson(surveys: [_surveyJson(captchaEnabled: true)]),
        ),
        ('GET', '/api/surveys/id/1/questions') => _json([]),
        ('GET', '/api/surveys/id/1/visibility-rules') => _json([]),
        ('POST', '/api/anonymous/accounts') => _json(_anonymousSessionJson()),
        ('POST', '/api/surveys/id/1/responses') => () {
          submittedCaptchaToken =
              (jsonDecode(request.body) as Map<String, dynamic>)['captchaToken']
                  as String?;
          return _json(_responseJson());
        }(),
        _ => http.Response('Unexpected ${request.method} ${request.url}', 404),
      };
    });

    await tester.pumpWidget(
      MaterialApp(
        home: FormConciergeSurvey(
          client: client,
          projectSlug: 'customer-feedback',
          captchaTokenProvider: () async => 'captcha-token',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(submittedCaptchaToken, 'captcha-token');
    expect(find.text('Thank you!'), findsOneWidget);
  });

  testWidgets(
    'uses provided anonymous token instead of creating a new session',
    (tester) async {
      final paths = <String>[];
      final client = _client((request) {
        paths.add('${request.method} ${request.url.path}');
        return switch ((request.method, request.url.path)) {
          ('GET', '/api/projects/customer-feedback') => _json(_projectJson()),
          ('GET', '/api/surveys/id/1/questions') => _json([]),
          ('GET', '/api/surveys/id/1/visibility-rules') => _json([]),
          _ => http.Response(
            'Unexpected ${request.method} ${request.url}',
            404,
          ),
        };
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FormConciergeSurvey(
            client: client,
            projectSlug: 'customer-feedback',
            anonymousToken: 'existing-token',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(client.anonymous.token, 'existing-token');
      expect(paths, isNot(contains('POST /api/anonymous/accounts')));
      expect(find.text('Customer feedback'), findsOneWidget);
    },
  );

  testWidgets('shows localized not-found error when survey is unavailable', (
    tester,
  ) async {
    final client = _client(
      (request) => http.Response(
        jsonEncode({'error': 'Project not found'}),
        404,
        headers: {'content-type': 'application/json'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FormConciergeSurvey(client: client, projectSlug: 'missing'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Survey not found or not available'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
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

Map<String, Object?> _projectJson({List<Map<String, Object?>>? surveys}) => {
  'project': {
    'id': 1,
    'slug': 'customer-feedback',
    'customDomain': null,
    'defaultLocale': 'en',
    'supportedLocales': ['en'],
    'name': 'Customer feedback',
    'createdAt': '2026-06-22T10:00:00.000Z',
    'updatedAt': '2026-06-22T10:00:00.000Z',
  },
  'surveys': surveys ?? [_surveyJson()],
};

Map<String, Object?> _surveyJson({
  int id = 1,
  String slug = 'customer-feedback',
  bool followUpEnabled = false,
  bool captchaEnabled = false,
}) => {
  'id': id,
  'projectId': 1,
  'slug': slug,
  'titleTranslations': {'en': 'Customer feedback'},
  'descriptionTranslations': {'en': 'Tell us what you think'},
  'status': 'published',
  'webEnabled': true,
  'followUpEnabled': followUpEnabled,
  'captchaEnabled': captchaEnabled,
  'createdAt': '2026-06-22T10:00:00.000Z',
  'updatedAt': '2026-06-22T10:00:00.000Z',
  'startsAt': null,
  'endsAt': null,
};

Map<String, Object?> _anonymousSessionJson() => {
  'account': {
    'id': 'anon-1',
    'displayName': null,
    'createdAt': '2026-06-22T10:00:00.000Z',
    'lastSeenAt': '2026-06-22T10:00:00.000Z',
  },
  'token': 'anon-token',
};

Map<String, Object?> _responseJson() => {
  'id': 99,
  'surveyId': 1,
  'userId': null,
  'anonymousId': 'anon-1',
  'anonymousAccountId': 'anon-1',
  'submittedAt': '2026-06-22T10:01:00.000Z',
  'deviceInfo': null,
  'metadata': null,
};
