// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';

import 'package:form_concierge_web/components/survey_client.dart'
    deferred as _survey_client;

/// Default [ClientOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.client.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultClientOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ClientOptions get defaultClientOptions => ClientOptions(
  clients: {
    'survey_client': ClientLoader(
      (p) => _survey_client.SurveyClient(
        surveyJson: (p['surveyJson'] as Map<String, Object?>),
        questionsJson: (p['questionsJson'] as List<Object?>)
            .map((i) => (i as Map<String, Object?>))
            .toList(),
        choicesByQuestionJson:
            (p['choicesByQuestionJson'] as Map<String, Object?>).map(
              (k, v) => MapEntry(
                k,
                (v as List<Object?>)
                    .map((i) => (i as Map<String, Object?>))
                    .toList(),
              ),
            ),
        serverUrl: p['serverUrl'] as String,
      ),
      loader: _survey_client.loadLibrary,
    ),
  },
);
