part of form_concierge_client;

class Client {
  final Uri baseUri;
  final http.Client _httpClient;

  late final SurveyEndpoint survey;
  late final ProjectAdminEndpoint projectAdmin;
  late final SurveyAdminEndpoint surveyAdmin;
  late final QuestionAdminEndpoint questionAdmin;
  late final ChoiceAdminEndpoint choiceAdmin;
  late final ResponseAnalyticsEndpoint responseAnalytics;
  late final NotificationSettingsEndpoint notificationSettings;
  late final AdminSettingsEndpoint adminSettings;
  late final ConfigEndpoint config;
  late final UserAdminEndpoint userAdmin;
  late final AiAdminEndpoint aiAdmin;
  late final EmailIdpEndpoint emailIdp;
  late final AnonymousEndpoint anonymous;
  late final ClientAuth auth;

  Object? authSessionManager;
  Object? connectivityMonitor;

  Client(String serverUrl, {http.Client? httpClient})
    : baseUri = Uri.parse(
        serverUrl.endsWith('/')
            ? serverUrl.substring(0, serverUrl.length - 1)
            : serverUrl,
      ),
      _httpClient = httpClient ?? http.Client() {
    survey = SurveyEndpoint(this);
    projectAdmin = ProjectAdminEndpoint(this);
    surveyAdmin = SurveyAdminEndpoint(this);
    questionAdmin = QuestionAdminEndpoint(this);
    choiceAdmin = ChoiceAdminEndpoint(this);
    responseAnalytics = ResponseAnalyticsEndpoint(this);
    notificationSettings = NotificationSettingsEndpoint(this);
    adminSettings = AdminSettingsEndpoint(this);
    config = ConfigEndpoint(this);
    userAdmin = UserAdminEndpoint(this);
    aiAdmin = AiAdminEndpoint(this);
    emailIdp = EmailIdpEndpoint(this);
    anonymous = AnonymousEndpoint(this);
    auth = ClientAuth(
      storageKey: 'form_concierge.admin_auth.${baseUri.toString()}',
      revokeSession: () => emailIdp.logout(),
    );
  }

  static const Duration requestTimeout = Duration(seconds: 30);

  Future<dynamic> request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool authenticated = false,
    String? bearerToken,
  }) async {
    final response = await _sendRequest(
      method,
      path,
      query: query,
      body: body,
      authenticated: authenticated,
      bearerToken: bearerToken,
      accept: 'application/json',
    );

    final text = response.body;
    Object? decoded;
    if (text.isNotEmpty) {
      try {
        decoded = jsonDecode(text);
      } on Object {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiException(
            response.statusCode,
            'Request failed with status ${response.statusCode}',
          );
        }
        rethrow;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiException(response.statusCode, decoded);
    }

    return decoded;
  }

  Future<RawResponse> rawRequest(
    String method,
    String path, {
    Map<String, String>? query,
    bool authenticated = false,
    String? bearerToken,
  }) async {
    final response = await _sendRequest(
      method,
      path,
      query: query,
      authenticated: authenticated,
      bearerToken: bearerToken,
      accept: '*/*',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _rawApiException(response);
    }

    return RawResponse(
      bodyBytes: response.bodyBytes,
      contentType: response.headers['content-type'],
      filename: _filenameFromContentDisposition(
        response.headers['content-disposition'],
      ),
    );
  }

  void close() => _httpClient.close();

  Future<http.Response> _sendRequest(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = false,
    String? bearerToken,
    required String accept,
  }) {
    final request = http.Request(method, _uriFor(path, query))
      ..headers.addAll(
        _headers(
          accept: accept,
          hasBody: body != null,
          authenticated: authenticated,
          bearerToken: bearerToken,
        ),
      );
    if (body != null) {
      request.body = jsonEncode(body);
    }

    return _httpClient
        .send(request)
        .timeout(requestTimeout)
        .then(http.Response.fromStream);
  }

  Uri _uriFor(String path, Map<String, String>? query) {
    final encodedPath = _encodePath(path);
    return baseUri.replace(
      path: '${baseUri.path}${encodedPath.startsWith('/') ? encodedPath : '/$encodedPath'}',
      queryParameters: query == null
          ? null
          : Map.fromEntries(
              query.entries.where((entry) => entry.value.isNotEmpty),
            ),
    );
  }

  /// Encode each path segment so slugs with spaces/unicode stay valid.
  static String _encodePath(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return normalized
        .split('/')
        .map((segment) => segment.isEmpty ? segment : Uri.encodeComponent(segment))
        .join('/');
  }

  Map<String, String> _headers({
    required String accept,
    required bool hasBody,
    required bool authenticated,
    required String? bearerToken,
  }) {
    return {
      'accept': accept,
      if (hasBody) 'content-type': 'application/json',
      if (bearerToken != null) 'authorization': 'Bearer $bearerToken',
      if (bearerToken == null && authenticated && auth.token != null)
        'authorization': 'Bearer ${auth.token}',
    };
  }
}

class RawResponse {
  final List<int> bodyBytes;
  final String? contentType;
  final String? filename;

  const RawResponse({
    required this.bodyBytes,
    this.contentType,
    this.filename,
  });

  String get bodyText => utf8.decode(bodyBytes);
}

String? _filenameFromContentDisposition(String? header) {
  if (header == null) return null;
  final match = RegExp(r'filename="?([^";]+)"?').firstMatch(header);
  return match?.group(1);
}

ApiException _apiException(int statusCode, Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return ApiException(statusCode, 'Request failed with status $statusCode');
  }
  final error = decoded['error'];
  if (error is! String || error.trim().isEmpty) {
    return ApiException(statusCode, 'Request failed with status $statusCode');
  }
  final details = decoded['details'];
  final message = error.trim();
  return ApiException(statusCode, message, details);
}

ApiException _rawApiException(http.Response response) {
  try {
    final decoded = jsonDecode(response.body);
    return _apiException(response.statusCode, decoded);
  } on Object {
    return ApiException(
      response.statusCode,
      'Request failed with status ${response.statusCode}',
    );
  }
}

class ClientAuth {
  final String _storageKey;
  final Future<void> Function()? _revokeSession;
  String? token;
  AuthUserInfo? signedInUser;

  ClientAuth({
    required String storageKey,
    Future<void> Function()? revokeSession,
  }) : _storageKey = storageKey,
       _revokeSession = revokeSession;

  bool get isAuthenticated => token != null;

  Future<void> updateSignedInUser(AuthSuccess authSuccess) async {
    token = authSuccess.token;
    signedInUser = authSuccess.user;
    await auth_storage.writeAuthSession(
      _storageKey,
      jsonEncode(authSuccess.toJson()),
    );
  }

  Future<void> restore() async {
    final raw = await auth_storage.readAuthSession(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      final authSuccess = AuthSuccess.fromJson(_requiredMap(decoded));
      token = authSuccess.token;
      signedInUser = authSuccess.user;
    } on Object {
      token = null;
      signedInUser = null;
      await auth_storage.clearAuthSession(_storageKey);
    }
  }

  Future<void> signOutDevice() async {
    // Best-effort server-side session revoke before clearing local state.
    if (token != null && _revokeSession != null) {
      try {
        await _revokeSession();
      } on Object {
        // Local logout must succeed even if the network call fails.
      }
    }
    token = null;
    signedInUser = null;
    await auth_storage.clearAuthSession(_storageKey);
  }
}
