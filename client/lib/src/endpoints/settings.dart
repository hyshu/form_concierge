part of form_concierge_client;

/// Reads and updates server integration settings with administrator access.
class AdminSettingsEndpoint {
  final Client _client;

  /// Creates AdminSettingsEndpoint using the supplied API client.
  AdminSettingsEndpoint(this._client);

  /// Returns integration settings without exposing saved secret values.
  Future<AdminIntegrationSettings> get() async {
    final json = await _client.request(
      'GET',
      '/api/admin/settings',
      authenticated: true,
    );
    return AdminIntegrationSettings.fromJson(json);
  }

  /// Saves integration settings and returns the resulting secret availability flags.
  Future<AdminIntegrationSettings> update(
    AdminIntegrationSettingsInput input,
  ) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/settings',
      body: input.toJson(),
      authenticated: true,
    );
    return AdminIntegrationSettings.fromJson(json);
  }

  /// Returns whether the server has the email settings required to send messages.
  Future<bool> isEmailConfigured() async {
    final json = await _client.request(
      'GET',
      '/api/admin/settings/email-configured',
      authenticated: true,
    );
    return _bool(json['configured']);
  }
}
