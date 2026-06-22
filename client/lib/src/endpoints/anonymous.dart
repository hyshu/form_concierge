part of form_concierge_client;

class AnonymousEndpoint {
  final Client _client;
  String? token;
  AnonymousAccount? account;

  AnonymousEndpoint(this._client);

  bool get isAuthenticated => token != null;

  void useToken(String token, {AnonymousAccount? account}) {
    this.token = token;
    this.account = account;
  }

  void clear() {
    token = null;
    account = null;
  }

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

  Future<AnonymousAccount> me() async {
    final json = await _client.request(
      'GET',
      '/api/anonymous/me',
      bearerToken: token,
    );
    account = AnonymousAccount.fromJson(json);
    return account!;
  }

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
}
