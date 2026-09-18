part of form_concierge_client;

/// Public survey lookup, submission, follow-up, and media operations.
class SurveyEndpoint {
  final Client _client;

  /// Creates SurveyEndpoint using the supplied API client.
  SurveyEndpoint(this._client);

  /// Returns the public project with this slug, or null if it is not found.
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

  /// Returns the public project assigned to a host name, or null if it is not found.
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

  /// Returns the publicly available questions for a survey.
  Future<List<Question>> getQuestionsForSurvey(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/surveys/id/$surveyId/questions',
    );
    return _objectList(json, Question.fromJson);
  }

  /// Returns the public visibility rules for a survey's questions.
  Future<List<QuestionVisibilityRule>> getVisibilityRulesForSurvey(
    int surveyId,
  ) async {
    final json = await _client.request(
      'GET',
      '/api/surveys/id/$surveyId/visibility-rules',
    );
    return _objectList(json, QuestionVisibilityRule.fromJson);
  }

  /// Returns the available choices for a question.
  Future<List<Choice>> getChoicesForQuestion(int questionId) async {
    final json = await _client.request(
      'GET',
      '/api/questions/$questionId/choices',
    );
    return _objectList(json, Choice.fromJson);
  }

  /// Loads choices for choice-based questions and indexes them by question identifier.
  Future<Map<int, List<Choice>>> getChoicesByQuestion(
    Iterable<Question> questions,
  ) => _choicesByQuestion(questions, getChoicesForQuestion);

  /// Submits answers using the current anonymous session and returns the saved response.
  /// Reuse the same idempotency key when retrying a submission.
  Future<SurveyResponse> submitResponse({
    required int surveyId,
    required List<Answer> answers,
    String? anonymousId,
    DeviceInfo? deviceInfo,
    Map<String, dynamic>? metadata,
    String? captchaToken,
    String? idempotencyKey,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/surveys/id/$surveyId/responses',
      body: {
        'anonymousId': anonymousId,
        'answers': answers.map((answer) => answer.toJson()).toList(),
        'deviceInfo': deviceInfo?.toJson(),
        'metadata': metadata,
        if (captchaToken != null) 'captchaToken': captchaToken,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      },
      bearerToken: _client.anonymous.token,
    );
    return SurveyResponse.fromJson(json);
  }

  /// Generate adaptive follow-up questions after the main form was submitted.
  Future<FollowUpGenerateResult> generateFollowUp({
    required int responseId,
    String? locale,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/responses/$responseId/follow-up/generate',
      body: {'locale': locale},
      bearerToken: _client.anonymous.token,
    );
    return FollowUpGenerateResult.fromJson(json);
  }

  /// Save answers for a pending follow-up interview.
  Future<SurveyResponse> saveFollowUp({
    required int responseId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final json = await _client.request(
      'PUT',
      '/api/responses/$responseId/follow-up',
      body: {'answers': answers},
      bearerToken: _client.anonymous.token,
    );
    return SurveyResponse.fromJson(json);
  }

  /// Upload an image for the current anonymous account.
  Future<MediaUpload> uploadMedia({
    required List<int> bytes,
    required String contentType,
  }) async {
    final json = await _client.uploadBytes(
      'POST',
      '/api/media',
      bytes: bytes,
      contentType: contentType,
      bearerToken: _client.anonymous.token,
    );
    return MediaUpload.fromJson(json as Map<String, dynamic>);
  }

  /// Absolute URL to fetch media (requires admin or owner bearer token).
  Uri mediaUrl(String key) => _client.uriFor('/api/media', {'key': key});

  /// Download media bytes. Use [authenticated] for admin sessions.
  Future<List<int>> getMediaBytes(
    String key, {
    bool authenticated = false,
    String? bearerToken,
  }) async {
    final response = await _client.rawRequest(
      'GET',
      '/api/media',
      query: {'key': key},
      authenticated: authenticated,
      bearerToken: bearerToken,
    );
    return response.bodyBytes;
  }
}

/// Retrieves server features available to unauthenticated clients.
class ConfigEndpoint {
  final Client _client;

  /// Creates ConfigEndpoint using the supplied API client.
  ConfigEndpoint(this._client);

  /// Returns public feature flags and the Turnstile site key, if configured.
  Future<PublicConfig> getPublicConfig() async {
    final json = await _client.request('GET', '/api/config');
    return PublicConfig.fromJson(json);
  }
}
