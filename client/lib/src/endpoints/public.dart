part of form_concierge_client;

class SurveyEndpoint {
  final Client _client;
  SurveyEndpoint(this._client);

  Future<PublicProject?> getProjectBySlug(String slug) async {
    try {
      final json = await _client.request('GET', '/api/projects/$slug');
      if (json == null) return null;
      return PublicProject.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<PublicProject?> getProjectByDomain(String domain) async {
    try {
      final json = await _client.request(
        'GET',
        '/api/projects/domain',
        query: {'host': domain},
      );
      if (json == null) return null;
      return PublicProject.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<Question>> getQuestionsForSurvey(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/surveys/id/$surveyId/questions',
    );
    return _objectList(json, Question.fromJson);
  }

  Future<List<QuestionVisibilityRule>> getVisibilityRulesForSurvey(
    int surveyId,
  ) async {
    final json = await _client.request(
      'GET',
      '/api/surveys/id/$surveyId/visibility-rules',
    );
    return _objectList(json, QuestionVisibilityRule.fromJson);
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

class ConfigEndpoint {
  final Client _client;
  ConfigEndpoint(this._client);

  Future<PublicConfig> getPublicConfig() async {
    final json = await _client.request('GET', '/api/config');
    return PublicConfig.fromJson(json);
  }
}
