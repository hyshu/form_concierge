part of form_concierge_client;

/// Connects to a Form Concierge server and exposes its API endpoints.
class Client {
  /// The server's base URI with any trailing slash removed.
  final Uri baseUri;
  final http.Client _httpClient;

  /// Public survey, response submission, and media operations.
  late final SurveyEndpoint survey;

  /// Administrator operations for projects.
  late final ProjectAdminEndpoint projectAdmin;

  /// Administrator operations for surveys.
  late final SurveyAdminEndpoint surveyAdmin;

  /// Administrator operations for questions.
  late final QuestionAdminEndpoint questionAdmin;

  /// Administrator operations for question choices.
  late final ChoiceAdminEndpoint choiceAdmin;

  /// Administrator operations for responses and aggregated results.
  late final ResponseAnalyticsEndpoint responseAnalytics;

  /// Administrator operations for survey email notifications.
  late final NotificationSettingsEndpoint notificationSettings;

  /// Administrator operations for server integrations.
  late final AdminSettingsEndpoint adminSettings;

  /// Access to public server configuration.
  late final ConfigEndpoint config;

  /// Administrator account and role operations.
  late final UserAdminEndpoint userAdmin;

  /// AI-assisted survey question generation.
  late final AiAdminEndpoint aiAdmin;

  /// Email and password authentication operations.
  late final EmailIdpEndpoint emailIdp;

  /// The respondent session and reply operations.
  late final AnonymousEndpoint anonymous;

  /// The current administrator session and its local persistence.
  late final ClientAuth auth;

  /// An optional application-owned authentication integration.
  Object? authSessionManager;

  /// An optional application-owned connectivity integration.
  Object? connectivityMonitor;

  /// Creates a client for the server URL with an optional HTTP transport. Closing this
  /// client also closes the supplied transport.
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

  /// The maximum time allowed for sending an HTTP request.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Sends a request and decodes its JSON response. Throws an ApiException for an
  /// unsuccessful HTTP status.
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

  /// Downloads a response without JSON decoding. Throws an ApiException for an
  /// unsuccessful HTTP status.
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

  /// Upload raw bytes (e.g. image/jpeg) without JSON encoding the body.
  Future<dynamic> uploadBytes(
    String method,
    String path, {
    required List<int> bytes,
    required String contentType,
    Map<String, String>? query,
    bool authenticated = false,
    String? bearerToken,
  }) async {
    final response = await _sendRequest(
      method,
      path,
      query: query,
      bodyBytes: bytes,
      bodyContentType: contentType,
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

  /// Closes the HTTP transport and releases its connections.
  void close() => _httpClient.close();

  Future<http.Response> _sendRequest(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    List<int>? bodyBytes,
    String? bodyContentType,
    bool authenticated = false,
    String? bearerToken,
    required String accept,
  }) {
    final hasBody = body != null || bodyBytes != null;
    final request = http.Request(method, _uriFor(path, query))
      ..headers.addAll(
        _headers(
          accept: accept,
          hasBody: hasBody,
          bodyContentType: bodyContentType,
          authenticated: authenticated,
          bearerToken: bearerToken,
        ),
      );
    if (bodyBytes != null) {
      request.bodyBytes = bodyBytes;
    } else if (body != null) {
      request.body = jsonEncode(body);
    }

    return _httpClient
        .send(request)
        .timeout(requestTimeout)
        .then(http.Response.fromStream);
  }

  /// Builds a server URI with encoded path segments and nonempty query values.
  Uri uriFor(String path, [Map<String, String>? query]) => _uriFor(path, query);

  Uri _uriFor(String path, Map<String, String>? query) {
    final encodedPath = _encodePath(path);
    return baseUri.replace(
      path:
          '${baseUri.path}${encodedPath.startsWith('/') ? encodedPath : '/$encodedPath'}',
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
        .map(
          (segment) => segment.isEmpty ? segment : Uri.encodeComponent(segment),
        )
        .join('/');
  }

  Map<String, String> _headers({
    required String accept,
    required bool hasBody,
    String? bodyContentType,
    required bool authenticated,
    required String? bearerToken,
  }) {
    return {
      'accept': accept,
      if (hasBody) 'content-type': bodyContentType ?? 'application/json',
      if (bearerToken != null) 'authorization': 'Bearer $bearerToken',
      if (bearerToken == null && authenticated && auth.token != null)
        'authorization': 'Bearer ${auth.token}',
    };
  }
}

/// Downloaded bytes and optional file metadata from an API response.
class RawResponse {
  /// The response body as raw bytes.
  final List<int> bodyBytes;

  /// The MIME type of the content.
  final String? contentType;

  /// The suggested name for the downloaded file.
  final String? filename;

  /// Creates RawResponse with the supplied values.
  const RawResponse({
    required this.bodyBytes,
    this.contentType,
    this.filename,
  });

  /// Decodes the downloaded bytes as UTF-8 text.
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

/// Stores the current administrator session and persists it locally.
class ClientAuth {
  final String _storageKey;
  final Future<void> Function()? _revokeSession;

  /// The bearer token used to authenticate requests.
  String? token;

  /// The administrator associated with the current session, if any.
  AuthUserInfo? signedInUser;

  /// Creates ClientAuth with the supplied values.
  ClientAuth({
    required String storageKey,
    Future<void> Function()? revokeSession,
  }) : _storageKey = storageKey,
       _revokeSession = revokeSession;

  /// Whether a token is set locally, without checking its server validity.
  bool get isAuthenticated => token != null;

  /// Updates the current administrator session and persists it locally.
  Future<void> updateSignedInUser(AuthSuccess authSuccess) async {
    token = authSuccess.token;
    signedInUser = authSuccess.user;
    await auth_storage.writeAuthSession(
      _storageKey,
      jsonEncode(authSuccess.toJson()),
    );
  }

  /// Restores a locally stored administrator session when its data can be decoded.
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

  /// Attempts to revoke the server session, then clears local session data even if
  /// revocation fails.
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
