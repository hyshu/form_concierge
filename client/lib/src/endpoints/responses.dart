part of form_concierge_client;

/// Retrieves, exports, and manages responses using administrator access.
class ResponseAnalyticsEndpoint {
  final Client _client;

  /// Creates ResponseAnalyticsEndpoint using the supplied API client.
  ResponseAnalyticsEndpoint(this._client);

  /// Lists survey responses with optional pagination.
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

  /// Returns the total number of responses for a survey.
  Future<int> getResponseCount(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/responses/count',
      authenticated: true,
    );
    return _int(json['count']);
  }

  /// Returns the answers recorded for a response.
  Future<List<Answer>> getAnswersForResponse(int responseId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/responses/$responseId/answers',
      authenticated: true,
    );
    return _objectList(json, Answer.fromJson);
  }

  /// Returns per-question statistics and individual answers for a survey.
  Future<SurveyResults> getAggregatedResults(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/results',
      authenticated: true,
    );
    return SurveyResults.fromJson(json);
  }

  /// Returns response counts grouped by date over the requested number of days.
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

  /// Downloads responses in the selected format with optional date filters.
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

  /// Deletes a response and returns true after the request succeeds.
  Future<bool> deleteResponse(int responseId) async {
    await _client.request(
      'DELETE',
      '/api/admin/responses/$responseId',
      authenticated: true,
    );
    return true;
  }

  /// Sends an administrator reply to the owner of a survey response.
  Future<AdminReply> createReply(int responseId, String body) async {
    final json = await _client.request(
      'POST',
      '/api/admin/responses/$responseId/replies',
      body: {'body': body},
      authenticated: true,
    );
    return AdminReply.fromJson(json);
  }

  /// Lists administrator replies attached to a response.
  Future<List<AdminReply>> getReplies(int responseId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/responses/$responseId/replies',
      authenticated: true,
    );
    return _objectList(json, AdminReply.fromJson);
  }
}

/// Manages survey email notifications using administrator access.
class NotificationSettingsEndpoint {
  final Client _client;

  /// Creates NotificationSettingsEndpoint using the supplied API client.
  NotificationSettingsEndpoint(this._client);

  /// Returns notification settings for a survey, or null when none exist.
  Future<NotificationSettings?> getForSurvey(int surveyId) async {
    final json = await _client.request(
      'GET',
      '/api/admin/surveys/$surveyId/notification-settings',
      authenticated: true,
    );
    return json == null ? null : NotificationSettings.fromJson(json);
  }

  /// Creates or replaces a survey's notification settings.
  Future<NotificationSettings> upsert(NotificationSettings settings) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/surveys/${settings.surveyId}/notification-settings',
      body: settings.toJson(),
      authenticated: true,
    );
    return NotificationSettings.fromJson(json);
  }

  /// Enables email notifications for a survey and returns the saved settings.
  Future<NotificationSettings> enable(int surveyId) => _toggle(surveyId, true);

  /// Disables email notifications for a survey and returns the saved settings.
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

  /// Deletes a survey's notification settings and returns true on success.
  Future<bool> delete(int surveyId) async {
    await _client.request(
      'DELETE',
      '/api/admin/surveys/$surveyId/notification-settings',
      authenticated: true,
    );
    return true;
  }

  /// Returns whether the server has the email settings required to send messages.
  Future<bool> isEmailConfigured() => _client.adminSettings.isEmailConfigured();

  /// Requests a test notification and returns true after the request succeeds.
  Future<bool> sendTestNotification(int surveyId) async {
    await _client.request(
      'POST',
      '/api/admin/surveys/$surveyId/notification-settings/test',
      authenticated: true,
    );
    return true;
  }
}
