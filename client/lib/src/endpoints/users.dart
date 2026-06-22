part of form_concierge_client;

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
    required AdminRole role,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/users',
      body: {
        'email': email,
        'password': password,
        'role': _enumName(role),
      },
      authenticated: true,
    );
    return AuthUserInfo.fromJson(json);
  }

  Future<AuthUserInfo> updateRole(UuidValue userId, AdminRole role) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/users/$userId/role',
      body: {'role': _enumName(role)},
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
}
