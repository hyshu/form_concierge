part of form_concierge_client;

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
