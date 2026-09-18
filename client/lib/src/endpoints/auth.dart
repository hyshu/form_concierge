part of form_concierge_client;

/// Authenticates administrators using email and password.
class EmailIdpEndpoint {
  final Client _client;

  /// Creates EmailIdpEndpoint using the supplied API client.
  EmailIdpEndpoint(this._client);

  /// Authenticates an administrator and returns the session without persisting it.
  Future<AuthSuccess> login({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    final json = await _client.request(
      'POST',
      '/api/admin/auth/login',
      body: {
        'email': email,
        'password': password,
        if (captchaToken != null) 'captchaToken': captchaToken,
      },
    );
    return AuthSuccess.fromJson(json);
  }

  /// Invalidate the current admin session on the server (best-effort).
  Future<void> logout() async {
    try {
      await _client.request(
        'DELETE',
        '/api/admin/auth/session',
        authenticated: true,
      );
    } on ApiException catch (e) {
      // Already expired / missing session is fine for local sign-out.
      if (e.statusCode != 401) rethrow;
    }
  }

  /// Throws an ApiException with status 501 because password reset is not implemented.
  Future<UuidValue> startPasswordReset({required String email}) async =>
      throw const ApiException(501, 'Password reset is not configured');

  /// Throws an ApiException with status 501 because password reset is not implemented.
  Future<String> verifyPasswordResetCode({
    required UuidValue passwordResetRequestId,
    required String verificationCode,
  }) async => throw const ApiException(501, 'Password reset is not configured');

  /// Throws an ApiException with status 501 because password reset is not implemented.
  Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) async => throw const ApiException(501, 'Password reset is not configured');
}
