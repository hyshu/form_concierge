part of form_concierge_client;

class EmailIdpEndpoint {
  final Client _client;
  EmailIdpEndpoint(this._client);

  Future<AuthSuccess> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/auth/login',
      body: {'email': email, 'password': password},
    );
    return AuthSuccess.fromJson(json);
  }

  Future<UuidValue> startPasswordReset({required String email}) async {
    throw const ApiException(501, 'Password reset is not configured');
  }

  Future<String> verifyPasswordResetCode({
    required UuidValue passwordResetRequestId,
    required String verificationCode,
  }) async {
    throw const ApiException(501, 'Password reset is not configured');
  }

  Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) async {
    throw const ApiException(501, 'Password reset is not configured');
  }
}
