import 'package:flutter/widgets.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';

typedef AnswerTranslationKey = ({
  int responseId,
  String itemId,
  String targetLocale,
});

AnswerTranslationKey mainAnswerTranslationKey({
  required int responseId,
  required int questionId,
  required String targetLocale,
}) => (
  responseId: responseId,
  itemId: 'question:$questionId',
  targetLocale: targetLocale,
);

AnswerTranslationKey followUpAnswerTranslationKey({
  required int responseId,
  required String itemId,
  required String targetLocale,
}) => (
  responseId: responseId,
  itemId: 'follow-up:$itemId',
  targetLocale: targetLocale,
);

String answerTargetLocale(Locale locale) => locale.toLanguageTag();

String? answerSourceLocale({
  Object? metadataLocale,
  String? deviceLocale,
}) {
  for (final candidate in [metadataLocale, deviceLocale]) {
    if (candidate is! String || candidate.trim().isEmpty) continue;
    final value = candidate.trim();
    if (RegExp(
      r'^[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*$',
    ).hasMatch(value)) {
      return value;
    }
  }
  return null;
}

class AnswerTranslationState {
  final Map<AnswerTranslationKey, String> translations;
  final Set<AnswerTranslationKey> loadingKeys;
  final Map<AnswerTranslationKey, String> errors;

  const AnswerTranslationState({
    this.translations = const {},
    this.loadingKeys = const {},
    this.errors = const {},
  });

  AnswerTranslationState copyWith({
    Map<AnswerTranslationKey, String>? translations,
    Set<AnswerTranslationKey>? loadingKeys,
    Map<AnswerTranslationKey, String>? errors,
  }) => AnswerTranslationState(
    translations: translations ?? this.translations,
    loadingKeys: loadingKeys ?? this.loadingKeys,
    errors: errors ?? this.errors,
  );
}

typedef TranslateAnswerCallback =
    Future<bool> Function({
      required AnswerTranslationKey key,
      required String sourceText,
      String? sourceLocale,
    });

class AnswerTranslationBindings {
  final bool enabled;
  final String targetLocale;
  final AnswerTranslationState state;
  final TranslateAnswerCallback translate;

  const AnswerTranslationBindings({
    required this.enabled,
    required this.targetLocale,
    required this.state,
    required this.translate,
  });

  bool canTranslate(String? sourceLocale) =>
      enabled && sourceLocale != targetLocale;
}

KeyedStateAccessors<int, AnswerTranslationState> answerTranslationStateCapsule(
  CapsuleHandle use,
) => createKeyedState(use, () => const AnswerTranslationState());

AnswerTranslationManager answerTranslationManagerCapsule(CapsuleHandle use) {
  final (getState, setState) = use(answerTranslationStateCapsule);
  final client = use(clientCapsule);
  return AnswerTranslationManager(
    getState: getState,
    setState: setState,
    client: client,
  );
}

class AnswerTranslationManager {
  final AnswerTranslationState Function(int surveyId) getState;
  final void Function(int surveyId, AnswerTranslationState state) setState;
  final Client client;

  AnswerTranslationManager({
    required this.getState,
    required this.setState,
    required this.client,
  });

  Future<bool> translate({
    required int surveyId,
    required AnswerTranslationKey key,
    required String sourceText,
    String? sourceLocale,
  }) async {
    final state = getState(surveyId);
    if (state.loadingKeys.contains(key)) return false;
    if (state.translations.containsKey(key)) return true;

    final loading = {...state.loadingKeys, key};
    final errors = Map<AnswerTranslationKey, String>.from(state.errors)
      ..remove(key);
    setState(
      surveyId,
      state.copyWith(loadingKeys: loading, errors: errors),
    );

    try {
      final translations = await client.aiAdmin.translateLocalizedText(
        sourceLocale: sourceLocale ?? 'auto',
        sourceText: sourceText,
        targetLocales: [key.targetLocale],
        fieldKind: 'response',
      );
      final translated = translations[key.targetLocale]?.trim();
      if (translated == null || translated.isEmpty) {
        throw const FormatException('Translation was empty');
      }

      final current = getState(surveyId);
      final nextTranslations = Map<AnswerTranslationKey, String>.from(
        current.translations,
      )..[key] = translated;
      final nextLoading = {...current.loadingKeys}..remove(key);
      setState(
        surveyId,
        current.copyWith(
          translations: nextTranslations,
          loadingKeys: nextLoading,
        ),
      );
      return true;
    } on Exception catch (error) {
      final current = getState(surveyId);
      final nextLoading = {...current.loadingKeys}..remove(key);
      final nextErrors = Map<AnswerTranslationKey, String>.from(
        current.errors,
      )..[key] = 'Failed to translate: $error';
      setState(
        surveyId,
        current.copyWith(loadingKeys: nextLoading, errors: nextErrors),
      );
      return false;
    }
  }
}
