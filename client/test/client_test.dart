import 'dart:convert';

import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('request builds JSON requests with filtered query parameters', () async {
    http.Request? captured;
    final client = Client(
      'https://api.example.com/base/',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('{"ok":true}', 200);
      }),
    );
    addTearDown(client.close);

    final result = await client.request(
      'POST',
      'surveys',
      body: {'title': 'Intake'},
      query: {'projectId': '7', 'empty': ''},
      bearerToken: 'token-1',
    );

    expect(result, {'ok': true});
    expect(
      captured!.url.toString(),
      'https://api.example.com/base/surveys?projectId=7',
    );
    expect(captured!.headers['accept'], 'application/json');
    expect(captured!.headers['content-type'], 'application/json');
    expect(captured!.headers['authorization'], 'Bearer token-1');
    expect(captured!.body, jsonEncode({'title': 'Intake'}));
  });

  test(
    'rawRequest uses session bearer token and skips JSON content type',
    () async {
      http.Request? captured;
      final client = Client(
        'https://api.example.com',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response.bytes(
            utf8.encode('id,name\n1,Ada\n'),
            200,
            headers: {
              'content-type': 'text/csv; charset=utf-8',
              'content-disposition': 'attachment; filename="responses.csv"',
            },
          );
        }),
      );
      addTearDown(client.close);
      client.auth.token = 'session-token';

      final response = await client.rawRequest(
        'GET',
        '/exports',
        authenticated: true,
      );

      expect(captured!.url.toString(), 'https://api.example.com/exports');
      expect(captured!.headers['accept'], '*/*');
      expect(captured!.headers.containsKey('content-type'), isFalse);
      expect(captured!.headers['authorization'], 'Bearer session-token');
      expect(response.bodyText, 'id,name\n1,Ada\n');
      expect(response.contentType, 'text/csv; charset=utf-8');
      expect(response.filename, 'responses.csv');
    },
  );

  test('rawRequest extracts JSON API error details', () async {
    final client = Client(
      'https://api.example.com',
      httpClient: MockClient(
        (_) async => http.Response(
          '{"error":"Invalid filter","details":{"field":"limit"}}',
          400,
        ),
      ),
    );
    addTearDown(client.close);

    await expectLater(
      client.rawRequest('GET', '/exports'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 400)
            .having((error) => error.message, 'message', 'Invalid filter')
            .having(
              (error) => error.details,
              'details',
              {'field': 'limit'},
            ),
      ),
    );
  });

  test('rawRequest maps non-JSON API error bodies to ApiException', () async {
    final client = Client(
      'https://api.example.com',
      httpClient: MockClient((_) async => http.Response('not available', 503)),
    );
    addTearDown(client.close);

    await expectLater(
      client.rawRequest('GET', '/exports'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 503)
            .having(
              (error) => error.message,
              'message',
              'Request failed with status 503',
            ),
      ),
    );
  });

  test(
    'request maps API error objects without error strings to ApiException',
    () async {
      final client = Client(
        'https://api.example.com',
        httpClient: MockClient(
          (_) async => http.Response('{"message":"No"}', 400),
        ),
      );
      addTearDown(client.close);

      await expectLater(
        client.request('GET', '/config'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 400)
              .having(
                (error) => error.message,
                'message',
                'Request failed with status 400',
              ),
        ),
      );
    },
  );

  test('model decoding rejects coerced API scalar types', () {
    expect(
      () => PublicConfig.fromJson({
        'passwordResetEnabled': 'true',
        'requireEmailVerification': false,
        'aiGenerationEnabled': true,
      }),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => Survey.fromJson({
        ..._surveyJson(),
        'projectId': '7',
      }),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => AuthUserInfo.fromJson({
        'id': 123,
        'email': 'ada@example.com',
        'scopeNames': ['surveys.read'],
        'role': 'admin',
        'created': '2026-01-01T00:00:00.000Z',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('model decoding rejects missing or unknown API values', () {
    final missingStatus = Map<String, dynamic>.from(_surveyJson())
      ..remove('status');
    expect(
      () => Survey.fromJson(missingStatus),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => Survey.fromJson({
        ..._surveyJson(),
        'status': 'retired',
      }),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => SurveyResults.fromJson({
        'surveyId': 1,
        'totalResponses': 0,
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('localized text falls back when a locale is not stored', () {
    const text = LocalizedText({'ja': '質問'});

    expect(text.valueFor('ja'), '質問');
    expect(text.valueFor('en'), '質問');
  });

  test('choice count decoding accepts only integer JSON keys and values', () {
    final result = QuestionResult.fromJson({
      'questionId': 1,
      'questionText': 'Plan',
      'questionType': 'singleChoice',
      'choiceCounts': {'10': 2},
    });
    expect(result.choiceCounts, {10: 2});
    expect(result.individualAnswers, isEmpty);

    expect(
      () => QuestionResult.fromJson({
        'questionId': 1,
        'questionText': 'Plan',
        'questionType': 'singleChoice',
        'choiceCounts': {'ten': 2},
      }),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => QuestionResult.fromJson({
        'questionId': 1,
        'questionText': 'Plan',
        'questionType': 'singleChoice',
        'choiceCounts': {'10': '2'},
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('question result parses individual answers under aggregates', () {
    final result = QuestionResult.fromJson({
      'questionId': 1,
      'questionText': 'Plan',
      'questionType': 'singleChoice',
      'choiceCounts': {'10': 1},
      'individualAnswers': [
        {
          'responseId': 5,
          'submittedAt': '2026-07-10T12:00:00.000Z',
          'anonymousId': 'anon-1',
          'textValue': null,
          'selectedChoiceIds': [10],
        },
      ],
    });

    expect(result.individualAnswers, hasLength(1));
    expect(result.individualAnswers.single.responseId, 5);
    expect(result.individualAnswers.single.anonymousId, 'anon-1');
    expect(result.individualAnswers.single.selectedChoiceIds, [10]);
  });

  test('text visibility rules reject coerced expected values', () {
    final questions = [
      _question(id: 1, type: QuestionType.textSingle, orderIndex: 0),
      _question(id: 2, type: QuestionType.textSingle, orderIndex: 1),
    ];
    final rules = [
      const QuestionVisibilityRule(
        surveyId: 1,
        targetQuestionId: 2,
        sourceQuestionId: 1,
        operator: VisibilityOperator.equals,
        value: 7,
      ),
    ];

    final visible = resolveVisibleQuestions(questions, rules, {1: '7'});

    expect(visible.map((question) => question.id), [1]);
  });

  test('resolveFormContentLocale prefers browser-like tags when supported', () {
    expect(
      resolveFormContentLocale(
        preferredLocales: const ['ja-JP', 'en-US'],
        supportedLocales: const ['en', 'ja'],
        defaultLocale: 'en',
      ),
      'ja',
    );
    expect(
      resolveFormContentLocale(
        preferredLocales: const ['fr-FR'],
        supportedLocales: const ['en', 'ja'],
        defaultLocale: 'ja',
      ),
      'ja',
    );
    expect(
      resolveFormContentLocale(
        preferredLocales: const ['zh-TW', 'en'],
        supportedLocales: const ['en', 'zh-Hant'],
        defaultLocale: 'en',
      ),
      'zh-Hant',
    );
  });
}

Map<String, dynamic> _surveyJson() => {
  'id': 1,
  'projectId': 7,
  'slug': 'intake',
  'titleTranslations': {'en': 'Intake'},
  'descriptionTranslations': {'en': ''},
  'status': 'published',
  'webEnabled': true,
  'followUpEnabled': false,
  'createdByUserId': null,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-02T00:00:00.000Z',
  'startsAt': null,
  'endsAt': null,
};

Question _question({
  required int id,
  required QuestionType type,
  required int orderIndex,
}) {
  return Question(
    id: id,
    surveyId: 1,
    textTranslations: const LocalizedText({'en': 'Question'}),
    type: type,
    orderIndex: orderIndex,
    placeholderTranslations: const LocalizedText({'en': ''}),
  );
}
