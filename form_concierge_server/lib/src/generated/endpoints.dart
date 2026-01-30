/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/ai_admin_endpoint.dart' as _i2;
import '../endpoints/auth_endpoints.dart' as _i3;
import '../endpoints/choice_admin_endpoint.dart' as _i4;
import '../endpoints/config_endpoint.dart' as _i5;
import '../endpoints/question_admin_endpoint.dart' as _i6;
import '../endpoints/response_analytics_endpoint.dart' as _i7;
import '../endpoints/survey_admin_endpoint.dart' as _i8;
import '../endpoints/survey_endpoint.dart' as _i9;
import '../endpoints/user_admin_endpoint.dart' as _i10;
import 'package:form_concierge_server/src/generated/choice.dart' as _i11;
import 'package:form_concierge_server/src/generated/question.dart' as _i12;
import 'package:form_concierge_server/src/generated/survey.dart' as _i13;
import 'package:form_concierge_server/src/generated/question_with_choices.dart'
    as _i14;
import 'package:form_concierge_server/src/generated/answer.dart' as _i15;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i16;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i17;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'aiAdmin': _i2.AiAdminEndpoint()
        ..initialize(
          server,
          'aiAdmin',
          null,
        ),
      'refreshJwtTokens': _i3.RefreshJwtTokensEndpoint()
        ..initialize(
          server,
          'refreshJwtTokens',
          null,
        ),
      'emailIdp': _i3.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'choiceAdmin': _i4.ChoiceAdminEndpoint()
        ..initialize(
          server,
          'choiceAdmin',
          null,
        ),
      'config': _i5.ConfigEndpoint()
        ..initialize(
          server,
          'config',
          null,
        ),
      'questionAdmin': _i6.QuestionAdminEndpoint()
        ..initialize(
          server,
          'questionAdmin',
          null,
        ),
      'responseAnalytics': _i7.ResponseAnalyticsEndpoint()
        ..initialize(
          server,
          'responseAnalytics',
          null,
        ),
      'surveyAdmin': _i8.SurveyAdminEndpoint()
        ..initialize(
          server,
          'surveyAdmin',
          null,
        ),
      'survey': _i9.SurveyEndpoint()
        ..initialize(
          server,
          'survey',
          null,
        ),
      'userAdmin': _i10.UserAdminEndpoint()
        ..initialize(
          server,
          'userAdmin',
          null,
        ),
    };
    connectors['aiAdmin'] = _i1.EndpointConnector(
      name: 'aiAdmin',
      endpoint: endpoints['aiAdmin']!,
      methodConnectors: {
        'generateSurveyQuestions': _i1.MethodConnector(
          name: 'generateSurveyQuestions',
          params: {
            'prompt': _i1.ParameterDescription(
              name: 'prompt',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['aiAdmin'] as _i2.AiAdminEndpoint)
                  .generateSurveyQuestions(
                    session,
                    params['prompt'],
                  ),
        ),
      },
    );
    connectors['refreshJwtTokens'] = _i1.EndpointConnector(
      name: 'refreshJwtTokens',
      endpoint: endpoints['refreshJwtTokens']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['refreshJwtTokens']
                          as _i3.RefreshJwtTokensEndpoint)
                      .refreshAccessToken(
                        session,
                        refreshToken: params['refreshToken'],
                      ),
        ),
      },
    );
    connectors['emailIdp'] = _i1.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
              ),
        ),
        'startRegistration': _i1.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _i1.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _i1.ParameterDescription(
              name: 'accountRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _i1.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _i1.ParameterDescription(
              name: 'registrationToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _i1.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _i1.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _i1.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _i1.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _i1.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i3.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
      },
    );
    connectors['choiceAdmin'] = _i1.EndpointConnector(
      name: 'choiceAdmin',
      endpoint: endpoints['choiceAdmin']!,
      methodConnectors: {
        'create': _i1.MethodConnector(
          name: 'create',
          params: {
            'choice': _i1.ParameterDescription(
              name: 'choice',
              type: _i1.getType<_i11.Choice>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['choiceAdmin'] as _i4.ChoiceAdminEndpoint).create(
                    session,
                    params['choice'],
                  ),
        ),
        'update': _i1.MethodConnector(
          name: 'update',
          params: {
            'choice': _i1.ParameterDescription(
              name: 'choice',
              type: _i1.getType<_i11.Choice>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['choiceAdmin'] as _i4.ChoiceAdminEndpoint).update(
                    session,
                    params['choice'],
                  ),
        ),
        'delete': _i1.MethodConnector(
          name: 'delete',
          params: {
            'choiceId': _i1.ParameterDescription(
              name: 'choiceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['choiceAdmin'] as _i4.ChoiceAdminEndpoint).delete(
                    session,
                    params['choiceId'],
                  ),
        ),
        'reorder': _i1.MethodConnector(
          name: 'reorder',
          params: {
            'questionId': _i1.ParameterDescription(
              name: 'questionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'choiceIds': _i1.ParameterDescription(
              name: 'choiceIds',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['choiceAdmin'] as _i4.ChoiceAdminEndpoint).reorder(
                    session,
                    params['questionId'],
                    params['choiceIds'],
                  ),
        ),
        'getById': _i1.MethodConnector(
          name: 'getById',
          params: {
            'choiceId': _i1.ParameterDescription(
              name: 'choiceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['choiceAdmin'] as _i4.ChoiceAdminEndpoint).getById(
                    session,
                    params['choiceId'],
                  ),
        ),
      },
    );
    connectors['config'] = _i1.EndpointConnector(
      name: 'config',
      endpoint: endpoints['config']!,
      methodConnectors: {
        'getPublicConfig': _i1.MethodConnector(
          name: 'getPublicConfig',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['config'] as _i5.ConfigEndpoint)
                  .getPublicConfig(session),
        ),
      },
    );
    connectors['questionAdmin'] = _i1.EndpointConnector(
      name: 'questionAdmin',
      endpoint: endpoints['questionAdmin']!,
      methodConnectors: {
        'create': _i1.MethodConnector(
          name: 'create',
          params: {
            'question': _i1.ParameterDescription(
              name: 'question',
              type: _i1.getType<_i12.Question>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionAdmin'] as _i6.QuestionAdminEndpoint)
                      .create(
                        session,
                        params['question'],
                      ),
        ),
        'update': _i1.MethodConnector(
          name: 'update',
          params: {
            'question': _i1.ParameterDescription(
              name: 'question',
              type: _i1.getType<_i12.Question>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionAdmin'] as _i6.QuestionAdminEndpoint)
                      .update(
                        session,
                        params['question'],
                      ),
        ),
        'delete': _i1.MethodConnector(
          name: 'delete',
          params: {
            'questionId': _i1.ParameterDescription(
              name: 'questionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionAdmin'] as _i6.QuestionAdminEndpoint)
                      .delete(
                        session,
                        params['questionId'],
                      ),
        ),
        'reorder': _i1.MethodConnector(
          name: 'reorder',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'questionIds': _i1.ParameterDescription(
              name: 'questionIds',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionAdmin'] as _i6.QuestionAdminEndpoint)
                      .reorder(
                        session,
                        params['surveyId'],
                        params['questionIds'],
                      ),
        ),
        'getForSurvey': _i1.MethodConnector(
          name: 'getForSurvey',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionAdmin'] as _i6.QuestionAdminEndpoint)
                      .getForSurvey(
                        session,
                        params['surveyId'],
                      ),
        ),
        'getById': _i1.MethodConnector(
          name: 'getById',
          params: {
            'questionId': _i1.ParameterDescription(
              name: 'questionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionAdmin'] as _i6.QuestionAdminEndpoint)
                      .getById(
                        session,
                        params['questionId'],
                      ),
        ),
        'getChoicesForQuestion': _i1.MethodConnector(
          name: 'getChoicesForQuestion',
          params: {
            'questionId': _i1.ParameterDescription(
              name: 'questionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionAdmin'] as _i6.QuestionAdminEndpoint)
                      .getChoicesForQuestion(
                        session,
                        params['questionId'],
                      ),
        ),
      },
    );
    connectors['responseAnalytics'] = _i1.EndpointConnector(
      name: 'responseAnalytics',
      endpoint: endpoints['responseAnalytics']!,
      methodConnectors: {
        'getResponses': _i1.MethodConnector(
          name: 'getResponses',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'offset': _i1.ParameterDescription(
              name: 'offset',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['responseAnalytics']
                          as _i7.ResponseAnalyticsEndpoint)
                      .getResponses(
                        session,
                        params['surveyId'],
                        limit: params['limit'],
                        offset: params['offset'],
                      ),
        ),
        'getResponseCount': _i1.MethodConnector(
          name: 'getResponseCount',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['responseAnalytics']
                          as _i7.ResponseAnalyticsEndpoint)
                      .getResponseCount(
                        session,
                        params['surveyId'],
                      ),
        ),
        'getAnswersForResponse': _i1.MethodConnector(
          name: 'getAnswersForResponse',
          params: {
            'responseId': _i1.ParameterDescription(
              name: 'responseId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['responseAnalytics']
                          as _i7.ResponseAnalyticsEndpoint)
                      .getAnswersForResponse(
                        session,
                        params['responseId'],
                      ),
        ),
        'getAggregatedResults': _i1.MethodConnector(
          name: 'getAggregatedResults',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['responseAnalytics']
                          as _i7.ResponseAnalyticsEndpoint)
                      .getAggregatedResults(
                        session,
                        params['surveyId'],
                      ),
        ),
        'getResponseTrends': _i1.MethodConnector(
          name: 'getResponseTrends',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'days': _i1.ParameterDescription(
              name: 'days',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['responseAnalytics']
                          as _i7.ResponseAnalyticsEndpoint)
                      .getResponseTrends(
                        session,
                        params['surveyId'],
                        days: params['days'],
                      ),
        ),
        'deleteResponse': _i1.MethodConnector(
          name: 'deleteResponse',
          params: {
            'responseId': _i1.ParameterDescription(
              name: 'responseId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['responseAnalytics']
                          as _i7.ResponseAnalyticsEndpoint)
                      .deleteResponse(
                        session,
                        params['responseId'],
                      ),
        ),
      },
    );
    connectors['surveyAdmin'] = _i1.EndpointConnector(
      name: 'surveyAdmin',
      endpoint: endpoints['surveyAdmin']!,
      methodConnectors: {
        'create': _i1.MethodConnector(
          name: 'create',
          params: {
            'survey': _i1.ParameterDescription(
              name: 'survey',
              type: _i1.getType<_i13.Survey>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['surveyAdmin'] as _i8.SurveyAdminEndpoint).create(
                    session,
                    params['survey'],
                  ),
        ),
        'createWithQuestions': _i1.MethodConnector(
          name: 'createWithQuestions',
          params: {
            'survey': _i1.ParameterDescription(
              name: 'survey',
              type: _i1.getType<_i13.Survey>(),
              nullable: false,
            ),
            'questions': _i1.ParameterDescription(
              name: 'questions',
              type: _i1.getType<List<_i14.QuestionWithChoices>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['surveyAdmin'] as _i8.SurveyAdminEndpoint)
                  .createWithQuestions(
                    session,
                    params['survey'],
                    params['questions'],
                  ),
        ),
        'update': _i1.MethodConnector(
          name: 'update',
          params: {
            'survey': _i1.ParameterDescription(
              name: 'survey',
              type: _i1.getType<_i13.Survey>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['surveyAdmin'] as _i8.SurveyAdminEndpoint).update(
                    session,
                    params['survey'],
                  ),
        ),
        'delete': _i1.MethodConnector(
          name: 'delete',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['surveyAdmin'] as _i8.SurveyAdminEndpoint).delete(
                    session,
                    params['surveyId'],
                  ),
        ),
        'list': _i1.MethodConnector(
          name: 'list',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['surveyAdmin'] as _i8.SurveyAdminEndpoint)
                  .list(session),
        ),
        'getById': _i1.MethodConnector(
          name: 'getById',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['surveyAdmin'] as _i8.SurveyAdminEndpoint).getById(
                    session,
                    params['surveyId'],
                  ),
        ),
        'publish': _i1.MethodConnector(
          name: 'publish',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['surveyAdmin'] as _i8.SurveyAdminEndpoint).publish(
                    session,
                    params['surveyId'],
                  ),
        ),
        'close': _i1.MethodConnector(
          name: 'close',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['surveyAdmin'] as _i8.SurveyAdminEndpoint).close(
                    session,
                    params['surveyId'],
                  ),
        ),
        'reopen': _i1.MethodConnector(
          name: 'reopen',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['surveyAdmin'] as _i8.SurveyAdminEndpoint).reopen(
                    session,
                    params['surveyId'],
                  ),
        ),
      },
    );
    connectors['survey'] = _i1.EndpointConnector(
      name: 'survey',
      endpoint: endpoints['survey']!,
      methodConnectors: {
        'getBySlug': _i1.MethodConnector(
          name: 'getBySlug',
          params: {
            'slug': _i1.ParameterDescription(
              name: 'slug',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['survey'] as _i9.SurveyEndpoint).getBySlug(
                session,
                params['slug'],
              ),
        ),
        'submitResponse': _i1.MethodConnector(
          name: 'submitResponse',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'answers': _i1.ParameterDescription(
              name: 'answers',
              type: _i1.getType<List<_i15.Answer>>(),
              nullable: false,
            ),
            'anonymousId': _i1.ParameterDescription(
              name: 'anonymousId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['survey'] as _i9.SurveyEndpoint).submitResponse(
                    session,
                    surveyId: params['surveyId'],
                    answers: params['answers'],
                    anonymousId: params['anonymousId'],
                  ),
        ),
        'getQuestionsForSurvey': _i1.MethodConnector(
          name: 'getQuestionsForSurvey',
          params: {
            'surveyId': _i1.ParameterDescription(
              name: 'surveyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['survey'] as _i9.SurveyEndpoint)
                  .getQuestionsForSurvey(
                    session,
                    params['surveyId'],
                  ),
        ),
        'getChoicesForQuestion': _i1.MethodConnector(
          name: 'getChoicesForQuestion',
          params: {
            'questionId': _i1.ParameterDescription(
              name: 'questionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['survey'] as _i9.SurveyEndpoint)
                  .getChoicesForQuestion(
                    session,
                    params['questionId'],
                  ),
        ),
      },
    );
    connectors['userAdmin'] = _i1.EndpointConnector(
      name: 'userAdmin',
      endpoint: endpoints['userAdmin']!,
      methodConnectors: {
        'isFirstUser': _i1.MethodConnector(
          name: 'isFirstUser',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['userAdmin'] as _i10.UserAdminEndpoint)
                  .isFirstUser(session),
        ),
        'registerFirstUser': _i1.MethodConnector(
          name: 'registerFirstUser',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['userAdmin'] as _i10.UserAdminEndpoint)
                  .registerFirstUser(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
        'listUsers': _i1.MethodConnector(
          name: 'listUsers',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['userAdmin'] as _i10.UserAdminEndpoint)
                  .listUsers(session),
        ),
        'createUser': _i1.MethodConnector(
          name: 'createUser',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'scopes': _i1.ParameterDescription(
              name: 'scopes',
              type: _i1.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['userAdmin'] as _i10.UserAdminEndpoint).createUser(
                    session,
                    email: params['email'],
                    password: params['password'],
                    scopes: params['scopes'],
                  ),
        ),
        'deleteUser': _i1.MethodConnector(
          name: 'deleteUser',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['userAdmin'] as _i10.UserAdminEndpoint).deleteUser(
                    session,
                    params['userId'],
                  ),
        ),
        'toggleUserBlocked': _i1.MethodConnector(
          name: 'toggleUserBlocked',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['userAdmin'] as _i10.UserAdminEndpoint)
                  .toggleUserBlocked(
                    session,
                    params['userId'],
                  ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i16.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i17.Endpoints()
      ..initializeEndpoints(server);
  }
}
