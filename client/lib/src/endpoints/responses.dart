part of form_concierge_client;

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
    ).map((key, value) => MapEntry(key, _int(value)));
  }

  Future<ResponseExportFile> exportResponses(
    int surveyId, {
    ResponseExportFormat format = ResponseExportFormat.csv,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _client.rawRequest(
      'GET',
      '/api/admin/surveys/$surveyId/responses/export',
      query: {
        'format': _enumName(format),
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
      authenticated: true,
    );
    final extension = format == ResponseExportFormat.csv ? 'csv' : 'json';
    return ResponseExportFile(
      bytes: response.bodyBytes,
      filename: response.filename ?? 'responses.$extension',
      contentType:
          response.contentType ??
          (format == ResponseExportFormat.csv
              ? 'text/csv; charset=utf-8'
              : 'application/json; charset=utf-8'),
      format: format,
    );
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

  Future<bool> isEmailConfigured() => _client.adminSettings.isEmailConfigured();

  Future<bool> sendTestNotification(int surveyId) async {
    await _client.request(
      'POST',
      '/api/admin/surveys/$surveyId/notification-settings/test',
      authenticated: true,
    );
    return true;
  }
}
