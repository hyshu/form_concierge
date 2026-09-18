part of form_concierge_client;

/// Creates and manages projects using administrator access.
class ProjectAdminEndpoint {
  final Client _client;

  /// Creates ProjectAdminEndpoint using the supplied API client.
  ProjectAdminEndpoint(this._client);

  /// Creates a project and returns the saved record.
  Future<Project> create(Project project) async {
    final json = await _client.request(
      'POST',
      '/api/admin/projects',
      body: project.toJson(),
      authenticated: true,
    );
    return Project.fromJson(json);
  }

  /// Updates the project and returns the saved record.
  Future<Project> update(Project project) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/projects/${project.id}',
      body: project.toJson(),
      authenticated: true,
    );
    return Project.fromJson(json);
  }

  /// Deletes the project and returns true after the request succeeds.
  Future<bool> delete(int projectId) async {
    await _client.request(
      'DELETE',
      '/api/admin/projects/$projectId',
      authenticated: true,
    );
    return true;
  }

  /// Lists available projects.
  Future<List<ProjectWithSurveys>> list() async {
    final json = await _client.request(
      'GET',
      '/api/admin/projects',
      authenticated: true,
    );
    return _objectList(json, ProjectWithSurveys.fromJson);
  }

  /// Returns the project with the given identifier, or null if it is not found.
  Future<ProjectWithSurveys?> getById(int projectId) async {
    try {
      final json = await _client.request(
        'GET',
        '/api/admin/projects/$projectId',
        authenticated: true,
      );
      return ProjectWithSurveys.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}

/// Creates and manages surveys using administrator access.
class SurveyAdminEndpoint {
  final Client _client;

  /// Creates SurveyAdminEndpoint using the supplied API client.
  SurveyAdminEndpoint(this._client);

  /// Creates a survey and returns the saved record.
  Future<Survey> create(Survey survey) async {
    final json = await _client.request(
      'POST',
      '/api/admin/surveys',
      body: survey.toJson(),
      authenticated: true,
    );
    return Survey.fromJson(json);
  }

  /// Creates a survey together with its initial questions and choices.
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

  /// Updates the survey and returns the saved record.
  Future<Survey> update(Survey survey) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/surveys/${survey.id}',
      body: survey.toJson(),
      authenticated: true,
    );
    return Survey.fromJson(json);
  }

  /// Deletes the survey and returns true after the request succeeds.
  Future<bool> delete(int surveyId) async {
    await _client.request(
      'DELETE',
      '/api/admin/surveys/$surveyId',
      authenticated: true,
    );
    return true;
  }

  /// Lists available surveys.
  Future<List<Survey>> list({int? projectId}) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys',
      query: {'projectId': projectId?.toString() ?? ''},
      authenticated: true,
    );
    return _objectList(json, Survey.fromJson);
  }

  /// Returns the survey with the given identifier, or null if it is not found.
  Future<Survey?> getById(int surveyId) async {
    try {
      final json = await _client.request(
        'GET',
        '/api/admin/surveys/$surveyId',
        authenticated: true,
      );
      return Survey.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Returns the visibility rules configured for a survey.
  Future<List<QuestionVisibilityRule>> getVisibilityRules(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/visibility-rules',
      authenticated: true,
    );
    return _objectList(json, QuestionVisibilityRule.fromJson);
  }

  /// Replaces all rules and optionally updates per-question
  /// visibility modes indexed by question identifier in the same transaction.
  Future<List<QuestionVisibilityRule>> replaceVisibilityRules(
    int surveyId,
    List<QuestionVisibilityRule> rules, {
    Map<int, VisibilityConditionMode>? conditionModes,
  }) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/surveys/$surveyId/visibility-rules',
      body: {
        'rules': rules.map((rule) => rule.toJson()).toList(),
        if (conditionModes != null)
          'conditionModes': conditionModes.map(
            (questionId, mode) => MapEntry('$questionId', _enumName(mode)),
          ),
      },
      authenticated: true,
    );
    return _objectList(json, QuestionVisibilityRule.fromJson);
  }

  /// Publishes the survey and returns its updated state.
  Future<Survey> publish(int surveyId) => _status(surveyId, 'publish');

  /// Closes the survey to new responses and returns its updated state.
  Future<Survey> close(int surveyId) => _status(surveyId, 'close');

  /// Reopens the survey and returns its updated state.
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

/// Creates and manages survey questions using administrator access.
class QuestionAdminEndpoint {
  final Client _client;

  /// Creates QuestionAdminEndpoint using the supplied API client.
  QuestionAdminEndpoint(this._client);

  /// Creates a question and returns the saved record.
  Future<Question> create(Question question) async {
    final json = await _client.request(
      'POST',
      '/api/admin/questions',
      body: question.toJson(),
      authenticated: true,
    );
    return Question.fromJson(json);
  }

  /// Updates the question and returns the saved record.
  Future<Question> update(Question question) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/questions/${question.id}',
      body: question.toJson(),
      authenticated: true,
    );
    return Question.fromJson(json);
  }

  /// Deletes the question and returns true after the request succeeds.
  Future<bool> delete(int questionId) async {
    final json = await _client.request(
      'DELETE',
      '/api/admin/questions/$questionId',
      authenticated: true,
    );
    return _bool(json['hardDeleted']);
  }

  /// Reorders survey questions using the supplied sequence of identifiers.
  Future<List<Question>> reorder(int surveyId, List<int> questionIds) async {
    final json = await _client.request(
      'POST',
      '/api/admin/surveys/$surveyId/questions/reorder',
      body: {'questionIds': questionIds},
      authenticated: true,
    );
    return _objectList(json, Question.fromJson);
  }

  /// Returns the questions belonging to a survey.
  Future<List<Question>> getForSurvey(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/questions',
      authenticated: true,
    );
    return _objectList(json, Question.fromJson);
  }

  /// Returns the question with the given identifier, or null if it is not found.
  Future<Question?> getById(int questionId) async {
    try {
      final json = await _client.request(
        'GET',
        '/api/admin/questions/$questionId',
        authenticated: true,
      );
      return Question.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Returns the available choices for a question.
  Future<List<Choice>> getChoicesForQuestion(int questionId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/questions/$questionId/choices',
      authenticated: true,
    );
    return _objectList(json, Choice.fromJson);
  }

  /// Loads choices for choice-based questions and indexes them by question identifier.
  Future<Map<int, List<Choice>>> getChoicesByQuestion(
    Iterable<Question> questions,
  ) => _choicesByQuestion(questions, getChoicesForQuestion);
}

/// Creates and manages question choices using administrator access.
class ChoiceAdminEndpoint {
  final Client _client;

  /// Creates ChoiceAdminEndpoint using the supplied API client.
  ChoiceAdminEndpoint(this._client);

  /// Creates a choice and returns the saved record.
  Future<Choice> create(Choice choice) async {
    final json = await _client.request(
      'POST',
      '/api/admin/choices',
      body: choice.toJson(),
      authenticated: true,
    );
    return Choice.fromJson(json);
  }

  /// Updates the choice and returns the saved record.
  Future<Choice> update(Choice choice) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/choices/${choice.id}',
      body: choice.toJson(),
      authenticated: true,
    );
    return Choice.fromJson(json);
  }

  /// Deletes the choice and returns true after the request succeeds.
  Future<bool> delete(int choiceId) async {
    await _client.request(
      'DELETE',
      '/api/admin/choices/$choiceId',
      authenticated: true,
    );
    return true;
  }

  /// Reorders a question's choices using the supplied sequence of identifiers.
  Future<List<Choice>> reorder(int questionId, List<int> choiceIds) async {
    final json = await _client.request(
      'POST',
      '/api/admin/questions/$questionId/choices/reorder',
      body: {'choiceIds': choiceIds},
      authenticated: true,
    );
    return _objectList(json, Choice.fromJson);
  }

  /// Returns the choice with the given identifier, or null if it is not found.
  Future<Choice?> getById(int choiceId) async {
    try {
      final json = await _client.request(
        'GET',
        '/api/admin/choices/$choiceId',
        authenticated: true,
      );
      return Choice.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}

/// Generates survey questions using the configured AI provider.
class AiAdminEndpoint {
  final Client _client;

  /// Creates AiAdminEndpoint using the supplied API client.
  AiAdminEndpoint(this._client);

  /// Generates localized questions and choices from the supplied prompt.
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

  /// Translate [sourceText] from [sourceLocale] into each of [targetLocales].
  Future<Map<String, String>> translateLocalizedText({
    required String sourceLocale,
    required String sourceText,
    required List<String> targetLocales,
    String? fieldKind,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/ai/translate-localized-text',
      body: {
        'sourceLocale': sourceLocale,
        'sourceText': sourceText,
        'targetLocales': targetLocales,
        if (fieldKind != null) 'fieldKind': fieldKind,
      },
      authenticated: true,
    );
    final map = _requiredMap(json);
    final translations = map['translations'];
    if (translations is! Map) {
      throw const ApiException(502, 'Invalid translations response');
    }
    return translations.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }
}
