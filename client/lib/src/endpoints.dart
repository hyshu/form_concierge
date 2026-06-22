part of form_concierge_client;

class SurveyEndpoint {
  final Client _client;
  SurveyEndpoint(this._client);

  Future<Survey?> getBySlug(String slug) async {
    final json = await _client.request('GET', '/api/surveys/$slug');
    return json == null ? null : Survey.fromJson(json);
  }

  Future<List<Question>> getQuestionsForSurvey(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/surveys/id/$surveyId/questions',
    );
    return _objectList(json, Question.fromJson);
  }

  Future<List<Choice>> getChoicesForQuestion(int questionId) async {
    final json = await _client.request(
      'GET',
      '/api/questions/$questionId/choices',
    );
    return _objectList(json, Choice.fromJson);
  }

  Future<Map<int, List<Choice>>> getChoicesByQuestion(
    Iterable<Question> questions,
  ) => _choicesByQuestion(questions, getChoicesForQuestion);

  Future<SurveyResponse> submitResponse({
    required int surveyId,
    required List<Answer> answers,
    String? anonymousId,
    DeviceInfo? deviceInfo,
    Map<String, dynamic>? metadata,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/surveys/id/$surveyId/responses',
      body: {
        'anonymousId': anonymousId,
        'answers': answers.map((answer) => answer.toJson()).toList(),
        'deviceInfo': deviceInfo?.toJson(),
        'metadata': metadata,
      },
      bearerToken: _client.anonymous.token,
    );
    return SurveyResponse.fromJson(json);
  }
}

class AnonymousEndpoint {
  final Client _client;
  String? token;
  AnonymousAccount? account;

  AnonymousEndpoint(this._client);

  bool get isAuthenticated => token != null;

  void useToken(String token, {AnonymousAccount? account}) {
    this.token = token;
    this.account = account;
  }

  void clear() {
    token = null;
    account = null;
  }

  Future<AnonymousSession> createAccount({String? displayName}) async {
    final json = await _client.request(
      'POST',
      '/api/anonymous/accounts',
      body: {'displayName': displayName},
    );
    final session = AnonymousSession.fromJson(json);
    token = session.token;
    account = session.account;
    return session;
  }

  Future<AnonymousAccount> me() async {
    final json = await _client.request(
      'GET',
      '/api/anonymous/me',
      bearerToken: token,
    );
    account = AnonymousAccount.fromJson(json);
    return account!;
  }

  Future<List<AdminReply>> getReplies({int? responseId}) async {
    final query = responseId == null ? null : {'responseId': '$responseId'};
    final json = await _client.request(
      'GET',
      '/api/anonymous/replies',
      query: query,
      bearerToken: token,
    );
    return _objectList(json, AdminReply.fromJson);
  }
}

class EmailIdpEndpoint {
  final Client _client;
  EmailIdpEndpoint(this._client);

  Future<AuthSuccess> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/auth/login',
      body: {'email': email, 'password': password},
    );
    return AuthSuccess.fromJson(json);
  }

  Future<UuidValue> startRegistration({required String email}) async {
    final json = await _client.request(
      'POST',
      '/api/admin/auth/start-registration',
      body: {'email': email},
      authenticated: true,
    );
    return json['requestId'].toString();
  }

  Future<String> verifyRegistrationCode({
    required UuidValue accountRequestId,
    required String verificationCode,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/auth/verify-registration',
      body: {
        'accountRequestId': accountRequestId,
        'verificationCode': verificationCode,
      },
      authenticated: true,
    );
    return json['registrationToken'] as String;
  }

  Future<AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/auth/finish-registration',
      body: {'registrationToken': registrationToken, 'password': password},
      authenticated: true,
    );
    return AuthSuccess.fromJson(json);
  }

  Future<UuidValue> startPasswordReset({required String email}) async {
    throw const ApiException(501, 'Password reset is not configured');
  }

  Future<String> verifyPasswordResetCode({
    required UuidValue passwordResetRequestId,
    required String verificationCode,
  }) async {
    throw const ApiException(501, 'Password reset is not configured');
  }

  Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) async {
    throw const ApiException(501, 'Password reset is not configured');
  }
}

class ConfigEndpoint {
  final Client _client;
  ConfigEndpoint(this._client);

  Future<PublicConfig> getPublicConfig() async {
    final json = await _client.request('GET', '/api/config');
    return PublicConfig.fromJson(json);
  }
}

class SurveyAdminEndpoint {
  final Client _client;
  SurveyAdminEndpoint(this._client);

  Future<Survey> create(Survey survey) async {
    final json = await _client.request(
      'POST',
      '/api/admin/surveys',
      body: survey.toJson(),
      authenticated: true,
    );
    return Survey.fromJson(json);
  }

  Future<Survey> createWithQuestions(
    Survey survey,
    List<QuestionWithChoices> questions,
  ) async {
    final json = await _client.request(
      'POST',
      '/api/admin/surveys/with-questions',
      body: {
        'survey': survey.toJson(),
        'questions': questions.map((question) => question.toJson()).toList(),
      },
      authenticated: true,
    );
    return Survey.fromJson(json);
  }

  Future<Survey> update(Survey survey) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/surveys/${survey.id}',
      body: survey.toJson(),
      authenticated: true,
    );
    return Survey.fromJson(json);
  }

  Future<bool> delete(int surveyId) async {
    await _client.request(
      'DELETE',
      '/api/admin/surveys/$surveyId',
      authenticated: true,
    );
    return true;
  }

  Future<List<Survey>> list() async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys',
      authenticated: true,
    );
    return _objectList(json, Survey.fromJson);
  }

  Future<Survey?> getById(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId',
      authenticated: true,
    );
    return json == null ? null : Survey.fromJson(json);
  }

  Future<Survey> publish(int surveyId) => _status(surveyId, 'publish');
  Future<Survey> close(int surveyId) => _status(surveyId, 'close');
  Future<Survey> reopen(int surveyId) => _status(surveyId, 'reopen');

  Future<Survey> _status(int surveyId, String action) async {
    final json = await _client.request(
      'POST',
      '/api/admin/surveys/$surveyId/$action',
      authenticated: true,
    );
    return Survey.fromJson(json);
  }
}

class QuestionAdminEndpoint {
  final Client _client;
  QuestionAdminEndpoint(this._client);

  Future<Question> create(Question question) async {
    final json = await _client.request(
      'POST',
      '/api/admin/questions',
      body: question.toJson(),
      authenticated: true,
    );
    return Question.fromJson(json);
  }

  Future<Question> update(Question question) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/questions/${question.id}',
      body: question.toJson(),
      authenticated: true,
    );
    return Question.fromJson(json);
  }

  Future<bool> delete(int questionId) async {
    final json = await _client.request(
      'DELETE',
      '/api/admin/questions/$questionId',
      authenticated: true,
    );
    return _bool(json['hardDeleted'], true);
  }

  Future<List<Question>> reorder(int surveyId, List<int> questionIds) async {
    final json = await _client.request(
      'POST',
      '/api/admin/surveys/$surveyId/questions/reorder',
      body: {'questionIds': questionIds},
      authenticated: true,
    );
    return _objectList(json, Question.fromJson);
  }

  Future<List<Question>> getForSurvey(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/questions',
      authenticated: true,
    );
    return _objectList(json, Question.fromJson);
  }

  Future<Question?> getById(int questionId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/questions/$questionId',
      authenticated: true,
    );
    return json == null ? null : Question.fromJson(json);
  }

  Future<List<Choice>> getChoicesForQuestion(int questionId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/questions/$questionId/choices',
      authenticated: true,
    );
    return _objectList(json, Choice.fromJson);
  }

  Future<Map<int, List<Choice>>> getChoicesByQuestion(
    Iterable<Question> questions,
  ) => _choicesByQuestion(questions, getChoicesForQuestion);
}

class ChoiceAdminEndpoint {
  final Client _client;
  ChoiceAdminEndpoint(this._client);

  Future<Choice> create(Choice choice) async {
    final json = await _client.request(
      'POST',
      '/api/admin/choices',
      body: choice.toJson(),
      authenticated: true,
    );
    return Choice.fromJson(json);
  }

  Future<Choice> update(Choice choice) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/choices/${choice.id}',
      body: choice.toJson(),
      authenticated: true,
    );
    return Choice.fromJson(json);
  }

  Future<bool> delete(int choiceId) async {
    await _client.request(
      'DELETE',
      '/api/admin/choices/$choiceId',
      authenticated: true,
    );
    return true;
  }

  Future<List<Choice>> reorder(int questionId, List<int> choiceIds) async {
    final json = await _client.request(
      'POST',
      '/api/admin/questions/$questionId/choices/reorder',
      body: {'choiceIds': choiceIds},
      authenticated: true,
    );
    return _objectList(json, Choice.fromJson);
  }

  Future<Choice?> getById(int choiceId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/choices/$choiceId',
      authenticated: true,
    );
    return json == null ? null : Choice.fromJson(json);
  }
}

class ResponseAnalyticsEndpoint {
  final Client _client;
  ResponseAnalyticsEndpoint(this._client);

  Future<List<SurveyResponse>> getResponses(
    int surveyId, {
    int? limit,
    int? offset,
  }) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/responses',
      query: {
        if (limit != null) 'limit': '$limit',
        if (offset != null) 'offset': '$offset',
      },
      authenticated: true,
    );
    return _objectList(json, SurveyResponse.fromJson);
  }

  Future<int> getResponseCount(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/responses/count',
      authenticated: true,
    );
    return _int(json['count']);
  }

  Future<List<Answer>> getAnswersForResponse(int responseId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/responses/$responseId/answers',
      authenticated: true,
    );
    return _objectList(json, Answer.fromJson);
  }

  Future<SurveyResults> getAggregatedResults(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/results',
      authenticated: true,
    );
    return SurveyResults.fromJson(json);
  }

  Future<Map<String, int>> getResponseTrends(
    int surveyId, {
    int days = 30,
  }) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/trends',
      query: {'days': '$days'},
      authenticated: true,
    );
    return _requiredMap(
      json,
    ).map((key, value) => MapEntry(key.toString(), _int(value)));
  }

  Future<bool> deleteResponse(int responseId) async {
    await _client.request(
      'DELETE',
      '/api/admin/responses/$responseId',
      authenticated: true,
    );
    return true;
  }

  Future<AdminReply> createReply(int responseId, String body) async {
    final json = await _client.request(
      'POST',
      '/api/admin/responses/$responseId/replies',
      body: {'body': body},
      authenticated: true,
    );
    return AdminReply.fromJson(json);
  }

  Future<List<AdminReply>> getReplies(int responseId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/responses/$responseId/replies',
      authenticated: true,
    );
    return _objectList(json, AdminReply.fromJson);
  }
}

class NotificationSettingsEndpoint {
  final Client _client;
  NotificationSettingsEndpoint(this._client);

  Future<NotificationSettings?> getForSurvey(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/notification-settings',
      authenticated: true,
    );
    return json == null ? null : NotificationSettings.fromJson(json);
  }

  Future<NotificationSettings> upsert(NotificationSettings settings) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/surveys/${settings.surveyId}/notification-settings',
      body: settings.toJson(),
      authenticated: true,
    );
    return NotificationSettings.fromJson(json);
  }

  Future<NotificationSettings> enable(int surveyId) => _toggle(surveyId, true);
  Future<NotificationSettings> disable(int surveyId) =>
      _toggle(surveyId, false);

  Future<NotificationSettings> _toggle(int surveyId, bool enabled) async {
    final json = await _client.request(
      'POST',
      '/api/admin/surveys/$surveyId/notification-settings/toggle',
      body: {'enabled': enabled},
      authenticated: true,
    );
    return NotificationSettings.fromJson(json);
  }

  Future<bool> delete(int surveyId) async {
    await _client.request(
      'DELETE',
      '/api/admin/surveys/$surveyId/notification-settings',
      authenticated: true,
    );
    return true;
  }

  Future<bool> isEmailConfigured() async => false;

  Future<bool> sendTestNotification(int surveyId) async {
    throw const ApiException(501, 'Email notifications are not configured');
  }
}

class UserAdminEndpoint {
  final Client _client;
  UserAdminEndpoint(this._client);

  Future<bool> isFirstUser() async {
    final json = await _client.request('GET', '/api/admin/bootstrap/status');
    return _bool(json['isFirstUser']);
  }

  Future<AuthSuccess> registerFirstUser({
    required String email,
    required String password,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/bootstrap',
      body: {'email': email, 'password': password},
    );
    return AuthSuccess.fromJson(json);
  }

  Future<List<AuthUserInfo>> listUsers() async {
    final json = await _client.request(
      'GET',
      '/api/admin/users',
      authenticated: true,
    );
    return _objectList(json, AuthUserInfo.fromJson);
  }

  Future<AuthUserInfo> createUser({
    required String email,
    required String password,
    required List<String> scopes,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/users',
      body: {'email': email, 'password': password, 'scopes': scopes},
      authenticated: true,
    );
    return AuthUserInfo.fromJson(json);
  }

  Future<bool> deleteUser(UuidValue userId) async {
    final json = await _client.request(
      'DELETE',
      '/api/admin/users/$userId',
      authenticated: true,
    );
    return _bool(json['selfDeleted']);
  }

  Future<bool> toggleUserBlocked(UuidValue userId) async {
    final json = await _client.request(
      'POST',
      '/api/admin/users/$userId/toggle-blocked',
      authenticated: true,
    );
    return _bool(json['blocked']);
  }
}

class AiAdminEndpoint {
  final Client _client;
  AiAdminEndpoint(this._client);

  Future<List<QuestionWithChoices>> generateSurveyQuestions(
    String prompt,
  ) async {
    final json = await _client.request(
      'POST',
      '/api/admin/ai/survey-questions',
      body: {'prompt': prompt},
      authenticated: true,
    );
    return _objectList(json, QuestionWithChoices.fromJson);
  }
}
