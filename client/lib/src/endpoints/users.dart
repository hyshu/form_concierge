part of form_concierge_client;

/// Manages administrator accounts, roles, and passwords.
class UserAdminEndpoint {
  final Client _client;

  /// Creates UserAdminEndpoint using the supplied API client.
  UserAdminEndpoint(this._client);

  /// Returns whether the server is waiting for its first administrator account.
  Future<bool> isFirstUser() async {
    final json = await _client.request('GET', '/api/admin/bootstrap/status');
    return _bool(json['isFirstUser']);
  }

  /// Creates the first administrator and returns the new session.
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

  /// Lists administrator accounts visible to the current administrator.
  Future<List<AuthUserInfo>> listUsers() async {
    final json = await _client.request(
      'GET',
      '/api/admin/users',
      authenticated: true,
    );
    return _objectList(json, AuthUserInfo.fromJson);
  }

  /// Creates an administrator account with the supplied credentials and role.
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

  /// Changes an administrator's role and returns the updated account.
  Future<AuthUserInfo> updateRole(UuidValue userId, AdminRole role) async {
    final json = await _client.request(
      'PUT',
      '/api/admin/users/$userId/role',
      body: {'role': _enumName(role)},
      authenticated: true,
    );
    return AuthUserInfo.fromJson(json);
  }

  /// Deletes an administrator and returns whether it was the current account.
  Future<bool> deleteUser(UuidValue userId) async {
    final json = await _client.request(
      'DELETE',
      '/api/admin/users/$userId',
      authenticated: true,
    );
    return _bool(json['selfDeleted']);
  }

  /// Changes the current administrator's password after checking the existing one.
  Future<void> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.request(
      'PUT',
      '/api/admin/account/password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      authenticated: true,
    );
  }
}
