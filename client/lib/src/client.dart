part of form_concierge_client;

class Client {
  final Uri baseUri;
  final http.Client _httpClient;

  late final SurveyEndpoint survey;
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
    auth = ClientAuth(
      storageKey: 'form_concierge.admin_auth.${baseUri.toString()}',
    );
    survey = SurveyEndpoint(this);
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
  }

  Future<dynamic> request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool authenticated = false,
    String? bearerToken,
  }) async {
    final uri = baseUri.replace(
      path: '${baseUri.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: query == null
          ? null
          : Map.fromEntries(
              query.entries.where((entry) => entry.value.isNotEmpty),
            ),
    );

    final headers = <String, String>{
      'accept': 'application/json',
      if (body != null) 'content-type': 'application/json',
      if (bearerToken != null) 'authorization': 'Bearer $bearerToken',
      if (bearerToken == null && authenticated && auth.token != null)
        'authorization': 'Bearer ${auth.token}',
    };

    final response = await _httpClient
        .send(
          http.Request(method, uri)
            ..headers.addAll(headers)
            ..body = body == null ? '' : jsonEncode(body),
        )
        .then(http.Response.fromStream);

    final text = response.body;
    final decoded = text.isEmpty ? null : jsonDecode(text);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed';
      Object? details = decoded;
      if (decoded is Map<String, dynamic>) {
        message =
            decoded['error']?.toString() ??
            decoded['message']?.toString() ??
            message;
        details = decoded['details'];
      }
      throw ApiException(response.statusCode, message, details);
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
    final uri = baseUri.replace(
      path: '${baseUri.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: query == null
          ? null
          : Map.fromEntries(
              query.entries.where((entry) => entry.value.isNotEmpty),
            ),
    );

    final headers = <String, String>{
      'accept': '*/*',
      if (bearerToken != null) 'authorization': 'Bearer $bearerToken',
      if (bearerToken == null && authenticated && auth.token != null)
        'authorization': 'Bearer ${auth.token}',
    };

    final response = await _httpClient
        .send(http.Request(method, uri)..headers.addAll(headers))
        .then(http.Response.fromStream);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      Object? details;
      var message = 'Request failed';
      try {
        final decoded = response.body.isEmpty
            ? null
            : jsonDecode(response.body);
        details = decoded;
        if (decoded is Map<String, dynamic>) {
          message =
              decoded['error']?.toString() ??
              decoded['message']?.toString() ??
              message;
          details = decoded['details'];
        }
      } on Object {
        message = response.body.isEmpty ? message : response.body;
      }
      throw ApiException(response.statusCode, message, details);
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

class ClientAuth {
  final String _storageKey;
  String? token;
  AuthUserInfo? signedInUser;

  ClientAuth({required String storageKey}) : _storageKey = storageKey;

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
    token = null;
    signedInUser = null;
    await auth_storage.clearAuthSession(_storageKey);
  }
}
