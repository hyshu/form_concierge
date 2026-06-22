part of form_concierge_client;

class AdminSettingsEndpoint {
  final Client _client;
  AdminSettingsEndpoint(this._client);

  Future<AdminIntegrationSettings> get() async {
    final json = await _client.request(
      'GET',
      '/api/admin/settings',
      authenticated: true,
    );
    return AdminIntegrationSettings.fromJson(json);
  }

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

  Future<bool> isEmailConfigured() async {
    final json = await _client.request(
      'GET',
      '/api/admin/settings/email-configured',
      authenticated: true,
    );
    return _bool(json['configured']);
  }
}
