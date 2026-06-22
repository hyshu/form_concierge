// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:form_concierge_web/components/domain_redirect_client.dart'
    as _domain_redirect_client;
import 'package:form_concierge_web/components/survey_client.dart'
    as _survey_client;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _domain_redirect_client.DomainRedirectClient:
        ClientTarget<_domain_redirect_client.DomainRedirectClient>(
          'domain_redirect_client',
          params: __domain_redirect_clientDomainRedirectClient,
        ),
    _survey_client.SurveyClient: ClientTarget<_survey_client.SurveyClient>(
      'survey_client',
      params: __survey_clientSurveyClient,
    ),
  },
);

Map<String, Object?> __domain_redirect_clientDomainRedirectClient(
  _domain_redirect_client.DomainRedirectClient c,
) => {'serverUrl': c.serverUrl};
Map<String, Object?> __survey_clientSurveyClient(
  _survey_client.SurveyClient c,
) => {
  'surveyJson': c.surveyJson,
  'questionsJson': c.questionsJson,
  'visibilityRulesJson': c.visibilityRulesJson,
  'choicesByQuestionJson': c.choicesByQuestionJson,
  'serverUrl': c.serverUrl,
};
