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
import '../endpoints/auth_endpoints.dart' as _i2;
import '../endpoints/config_endpoint.dart' as _i3;
import '../endpoints/question_admin_endpoint.dart' as _i4;
import '../endpoints/question_option_admin_endpoint.dart' as _i5;
import '../endpoints/response_analytics_endpoint.dart' as _i6;
import '../endpoints/survey_admin_endpoint.dart' as _i7;
import '../endpoints/survey_endpoint.dart' as _i8;
import '../endpoints/user_admin_endpoint.dart' as _i9;
import 'package:form_concierge_server/src/generated/question.dart' as _i10;
import 'package:form_concierge_server/src/generated/question_option.dart'
    as _i11;
import 'package:form_concierge_server/src/generated/survey.dart' as _i12;
import 'package:form_concierge_server/src/generated/answer.dart' as _i13;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i14;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i15;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'refreshJwtTokens': _i2.RefreshJwtTokensEndpoint()
        ..initialize(
          server,
          'refreshJwtTokens',
          null,
        ),
      'emailIdp': _i2.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'config': _i3.ConfigEndpoint()
        ..initialize(
          server,
          'config',
          null,
        ),
      'questionAdmin': _i4.QuestionAdminEndpoint()
        ..initialize(
          server,
          'questionAdmin',
          null,
        ),
      'questionOptionAdmin': _i5.QuestionOptionAdminEndpoint()
        ..initialize(
          server,
          'questionOptionAdmin',
          null,
        ),
      'responseAnalytics': _i6.ResponseAnalyticsEndpoint()
        ..initialize(
          server,
          'responseAnalytics',
          null,
        ),
      'surveyAdmin': _i7.SurveyAdminEndpoint()
        ..initialize(
          server,
          'surveyAdmin',
          null,
        ),
      'survey': _i8.SurveyEndpoint()
        ..initialize(
          server,
          'survey',
          null,
        ),
      'userAdmin': _i9.UserAdminEndpoint()
        ..initialize(
          server,
          'userAdmin',
          null,
        ),
    };
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
                          as _i2.RefreshJwtTokensEndpoint)
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
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint).login(
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
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
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
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
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
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
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
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
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
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
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
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
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
              ) async => (endpoints['config'] as _i3.ConfigEndpoint)
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
              type: _i1.getType<_i10.Question>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionAdmin'] as _i4.QuestionAdminEndpoint)
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
              type: _i1.getType<_i10.Question>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionAdmin'] as _i4.QuestionAdminEndpoint)
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
                  (endpoints['questionAdmin'] as _i4.QuestionAdminEndpoint)
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
                  (endpoints['questionAdmin'] as _i4.QuestionAdminEndpoint)
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
                  (endpoints['questionAdmin'] as _i4.QuestionAdminEndpoint)
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
                  (endpoints['questionAdmin'] as _i4.QuestionAdminEndpoint)
                      .getById(
                        session,
                        params['questionId'],
                      ),
        ),
        'getOptionsForQuestion': _i1.MethodConnector(
          name: 'getOptionsForQuestion',
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
                  (endpoints['questionAdmin'] as _i4.QuestionAdminEndpoint)
                      .getOptionsForQuestion(
                        session,
                        params['questionId'],
                      ),
        ),
      },
    );
    connectors['questionOptionAdmin'] = _i1.EndpointConnector(
      name: 'questionOptionAdmin',
      endpoint: endpoints['questionOptionAdmin']!,
      methodConnectors: {
        'create': _i1.MethodConnector(
          name: 'create',
          params: {
            'option': _i1.ParameterDescription(
              name: 'option',
              type: _i1.getType<_i11.QuestionOption>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionOptionAdmin']
                          as _i5.QuestionOptionAdminEndpoint)
                      .create(
                        session,
                        params['option'],
                      ),
        ),
        'update': _i1.MethodConnector(
          name: 'update',
          params: {
            'option': _i1.ParameterDescription(
              name: 'option',
              type: _i1.getType<_i11.QuestionOption>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionOptionAdmin']
                          as _i5.QuestionOptionAdminEndpoint)
                      .update(
                        session,
                        params['option'],
                      ),
        ),
        'delete': _i1.MethodConnector(
          name: 'delete',
          params: {
            'optionId': _i1.ParameterDescription(
              name: 'optionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionOptionAdmin']
                          as _i5.QuestionOptionAdminEndpoint)
                      .delete(
                        session,
                        params['optionId'],
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
            'optionIds': _i1.ParameterDescription(
              name: 'optionIds',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionOptionAdmin']
                          as _i5.QuestionOptionAdminEndpoint)
                      .reorder(
                        session,
                        params['questionId'],
                        params['optionIds'],
                      ),
        ),
        'getById': _i1.MethodConnector(
          name: 'getById',
          params: {
            'optionId': _i1.ParameterDescription(
              name: 'optionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['questionOptionAdmin']
                          as _i5.QuestionOptionAdminEndpoint)
                      .getById(
                        session,
                        params['optionId'],
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
                          as _i6.ResponseAnalyticsEndpoint)
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
                          as _i6.ResponseAnalyticsEndpoint)
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
                          as _i6.ResponseAnalyticsEndpoint)
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
                          as _i6.ResponseAnalyticsEndpoint)
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
                          as _i6.ResponseAnalyticsEndpoint)
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
                          as _i6.ResponseAnalyticsEndpoint)
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
              type: _i1.getType<_i12.Survey>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['surveyAdmin'] as _i7.SurveyAdminEndpoint).create(
                    session,
                    params['survey'],
                  ),
        ),
        'update': _i1.MethodConnector(
          name: 'update',
          params: {
            'survey': _i1.ParameterDescription(
              name: 'survey',
              type: _i1.getType<_i12.Survey>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['surveyAdmin'] as _i7.SurveyAdminEndpoint).update(
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
                  (endpoints['surveyAdmin'] as _i7.SurveyAdminEndpoint).delete(
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
              ) async => (endpoints['surveyAdmin'] as _i7.SurveyAdminEndpoint)
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
                  (endpoints['surveyAdmin'] as _i7.SurveyAdminEndpoint).getById(
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
                  (endpoints['surveyAdmin'] as _i7.SurveyAdminEndpoint).publish(
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
                  (endpoints['surveyAdmin'] as _i7.SurveyAdminEndpoint).close(
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
                  (endpoints['surveyAdmin'] as _i7.SurveyAdminEndpoint).reopen(
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
              ) async => (endpoints['survey'] as _i8.SurveyEndpoint).getBySlug(
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
              type: _i1.getType<List<_i13.Answer>>(),
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
                  (endpoints['survey'] as _i8.SurveyEndpoint).submitResponse(
                    session,
                    surveyId: params['surveyId'],
                    answers: params['answers'],
                    anonymousId: params['anonymousId'],
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
              ) async => (endpoints['userAdmin'] as _i9.UserAdminEndpoint)
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
              ) async => (endpoints['userAdmin'] as _i9.UserAdminEndpoint)
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
              ) async => (endpoints['userAdmin'] as _i9.UserAdminEndpoint)
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
                  (endpoints['userAdmin'] as _i9.UserAdminEndpoint).createUser(
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
                  (endpoints['userAdmin'] as _i9.UserAdminEndpoint).deleteUser(
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
              ) async => (endpoints['userAdmin'] as _i9.UserAdminEndpoint)
                  .toggleUserBlocked(
                    session,
                    params['userId'],
                  ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i14.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i15.Endpoints()
      ..initializeEndpoints(server);
  }
}
