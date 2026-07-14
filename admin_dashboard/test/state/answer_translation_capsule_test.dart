import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_flutter/src/features/responses/presentation/capsules/answer_translation_capsule.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('answer locale prefers metadata, then device info', () {
    expect(
      answerSourceLocale(metadataLocale: 'ko', deviceLocale: 'ja'),
      'ko',
    );
    expect(
      answerSourceLocale(metadataLocale: null, deviceLocale: 'ja-JP'),
      'ja',
    );
    expect(
      answerSourceLocale(metadataLocale: 7, deviceLocale: 'zh_TW'),
      'zh-Hant',
    );
    expect(
      answerSourceLocale(metadataLocale: 'not a locale!', deviceLocale: null),
      isNull,
    );
  });

  test('answer target follows supported browser locale', () {
    expect(answerTargetLocale(const Locale('ko', 'KR')), 'ko');
    expect(
      answerTargetLocale(
        const Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
      ),
      'zh-Hant',
    );
    expect(answerTargetLocale(const Locale('pt', 'BR')), 'en');
  });

  test(
    'manager caches translations and uses auto only without source locale',
    () async {
      final payloads = <Map<String, dynamic>>[];
      final client = Client(
        'https://api.example.com',
        httpClient: MockClient((request) async {
          payloads.add(jsonDecode(request.body) as Map<String, dynamic>);
          final target = (payloads.last['targetLocales'] as List).single;
          return http.Response(
            jsonEncode({
              'translations': {target: 'Translated ${payloads.length}'},
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);
      var state = const AnswerTranslationState();
      final manager = AnswerTranslationManager(
        getState: (_) => state,
        setState: (_, next) => state = next,
        client: client,
      );
      final explicitKey = mainAnswerTranslationKey(
        responseId: 7,
        questionId: 11,
        targetLocale: 'ja',
      );

      expect(
        await manager.translate(
          surveyId: 1,
          key: explicitKey,
          sourceText: '좋아요',
          sourceLocale: 'ko',
        ),
        isTrue,
      );
      expect(payloads.single['sourceLocale'], 'ko');
      expect(payloads.single['fieldKind'], 'response');
      expect(state.translations[explicitKey], 'Translated 1');

      await manager.translate(
        surveyId: 1,
        key: explicitKey,
        sourceText: '좋아요',
        sourceLocale: 'ko',
      );
      expect(payloads, hasLength(1));

      final autoKey = mainAnswerTranslationKey(
        responseId: 8,
        questionId: 11,
        targetLocale: 'ja',
      );
      await manager.translate(
        surveyId: 1,
        key: autoKey,
        sourceText: 'Great',
      );
      expect(payloads.last['sourceLocale'], 'auto');
      expect(state.translations[autoKey], 'Translated 2');
    },
  );
}
