part of form_concierge_client;

/// Manages the respondent session and retrieves administrator replies.
class AnonymousEndpoint {
  final Client _client;

  /// The bearer token used to authenticate requests.
  String? token;

  /// The anonymous account associated with the current session, if known.
  AnonymousAccount? account;

  /// Creates AnonymousEndpoint using the supplied API client.
  AnonymousEndpoint(this._client);

  /// Whether a token is set locally, without checking its server validity.
  bool get isAuthenticated => token != null;

  /// Replaces the local anonymous token and optional account without validating them.
  void useToken(String token, {AnonymousAccount? account}) {
    this.token = token;
    this.account = account;
  }

  /// Clears the local anonymous session without revoking the token on the server.
  void clear() {
    token = null;
    account = null;
  }

  /// Creates an anonymous account and stores its session in this endpoint.
  Future<AnonymousSession> createAccount({String? displayName}) async {
    final json = await _client.request(
      'POST',
      '/api/anonymous/accounts',
      body: {'displayName': displayName},
    );
    final session = AnonymousSession.fromJson(json);
    token = session.token;
    account = session.account;
    return session;
  }

  /// Loads the current anonymous account and updates the locally stored account.
  Future<AnonymousAccount> me() async {
    final json = await _client.request(
      'GET',
      '/api/anonymous/me',
      bearerToken: token,
    );
    account = AnonymousAccount.fromJson(json);
    return account!;
  }

  /// Lists replies for the current respondent, optionally limited to one response.
  Future<List<AdminReply>> getReplies({int? responseId}) async {
    final query = responseId == null ? null : {'responseId': '$responseId'};
    final json = await _client.request(
      'GET',
      '/api/anonymous/replies',
      query: query,
      bearerToken: token,
    );
    return _objectList(json, AdminReply.fromJson);
  }

  /// Returns the latest reply time, or null when no matching reply exists.
  Future<DateTime?> getLatestReplyAt({int? responseId}) async {
    final query = responseId == null ? null : {'responseId': '$responseId'};
    final json = await _client.request(
      'GET',
      '/api/anonymous/replies/latest',
      query: query,
      bearerToken: token,
    );
    return _optionalDate(json['latestReplyAt']);
  }
}
