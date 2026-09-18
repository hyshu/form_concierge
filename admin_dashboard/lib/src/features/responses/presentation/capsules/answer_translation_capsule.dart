import 'package:flutter/widgets.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';

/// Identifies an answer translation by response, item, and target locale.
typedef AnswerTranslationKey = ({
  int responseId,
  String itemId,
  String targetLocale,
});

/// Builds a translation key for an answer to a main survey question.
AnswerTranslationKey mainAnswerTranslationKey({
  required int responseId,
  required int questionId,
  required String targetLocale,
}) => (
  responseId: responseId,
  itemId: 'question:$questionId',
  targetLocale: targetLocale,
);

/// Builds a translation key for an adaptive follow-up answer.
AnswerTranslationKey followUpAnswerTranslationKey({
  required int responseId,
  required String itemId,
  required String targetLocale,
}) => (
  responseId: responseId,
  itemId: 'follow-up:$itemId',
  targetLocale: targetLocale,
);

/// Converts a Flutter locale to the language tag used for answer translation.
String answerTargetLocale(Locale locale) => locale.toLanguageTag();

/// Resolves the language associated with an answer from response metadata or follow-up
/// data.
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

/// Cached translations, active requests, and errors indexed by translation key.
class AnswerTranslationState {
  /// Translated answer text indexed by its translation key.
  final Map<AnswerTranslationKey, String> translations;

  /// Translation keys whose requests are currently in progress.
  final Set<AnswerTranslationKey> loadingKeys;

  /// Translation failure messages indexed by translation key.
  final Map<AnswerTranslationKey, String> errors;

  /// Creates AnswerTranslationState with the supplied values.
  const AnswerTranslationState({
    this.translations = const {},
    this.loadingKeys = const {},
    this.errors = const {},
  });

  /// Returns a copy with the supplied state changes.
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

/// Requests a translation for a main or follow-up answer.
typedef TranslateAnswerCallback =
    Future<bool> Function({
      required AnswerTranslationKey key,
      required String sourceText,
      String? sourceLocale,
    });

/// Translation availability, current state, and the request callback for a survey.
class AnswerTranslationBindings {
  /// Whether answer translation is available for this survey.
  final bool enabled;

  /// The locale into which answer text should be translated.
  final String targetLocale;

  /// The current state snapshot exposed by this manager.
  final AnswerTranslationState state;

  /// Requests a translation using the current survey and target locale.
  final TranslateAnswerCallback translate;

  /// Creates AnswerTranslationBindings with the supplied values.
  const AnswerTranslationBindings({
    required this.enabled,
    required this.targetLocale,
    required this.state,
    required this.translate,
  });

  /// Returns whether translation is enabled and the source language differs from the
  /// target.
  bool canTranslate(String? sourceLocale) =>
      enabled && sourceLocale != targetLocale;
}

/// Provides reactive answer translation state state and dependencies.
KeyedStateAccessors<int, AnswerTranslationState> answerTranslationStateCapsule(
  CapsuleHandle use,
) => createKeyedState(use, () => const AnswerTranslationState());

/// Provides reactive answer translation manager state and dependencies.
AnswerTranslationManager answerTranslationManagerCapsule(CapsuleHandle use) {
  final (getState, setState) = use(answerTranslationStateCapsule);
  final client = use(clientCapsule);
  return AnswerTranslationManager(
    getState: getState,
    setState: setState,
    client: client,
  );
}

/// Requests answer translations and caches results separately for each survey.
class AnswerTranslationManager {
  /// Reads the current state for the supplied record identifier.
  final AnswerTranslationState Function(int surveyId) getState;

  /// Replaces the state associated with the supplied record identifier.
  final void Function(int surveyId, AnswerTranslationState state) setState;

  /// The API client used to load data and submit changes.
  final Client client;

  /// Creates AnswerTranslationManager with the supplied values.
  AnswerTranslationManager({
    required this.getState,
    required this.setState,
    required this.client,
  });

  /// Requests an answer translation, updates cached state, and returns whether it
  /// succeeded.
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
