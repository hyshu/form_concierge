part of form_concierge_client;

/// An administrator's identity and granted permissions.
class AuthUserInfo {
  /// The identifier of this auth user info.
  final UuidValue id;

  /// The administrator's email address, when available.
  final String? email;

  /// Permission scopes granted to the administrator.
  final List<String> scopeNames;

  /// The administrator's permission level.
  final AdminRole role;

  /// When the administrator account was created.
  final DateTime created;

  /// Creates AuthUserInfo with the supplied values.
  const AuthUserInfo({
    required this.id,
    this.email,
    required this.scopeNames,
    required this.role,
    required this.created,
  });

  /// Decodes AuthUserInfo from its JSON representation.
  factory AuthUserInfo.fromJson(Map<String, dynamic> json) => AuthUserInfo(
    id: _string(json['id']),
    email: _optionalString(json['email']),
    scopeNames: _stringList(json['scopeNames']),
    role: _enum(AdminRole.values, json['role']),
    created: _date(json['created']),
  );

  /// Returns the JSON representation used by the API.
  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'email': email,
    'scopeNames': scopeNames,
    'role': _enumName(role),
    'created': created.toIso8601String(),
  });
}

/// The session token and administrator returned after authentication.
class AuthSuccess {
  /// The bearer token used to authenticate requests.
  final String token;

  /// The administrator authenticated by this session.
  final AuthUserInfo user;

  /// Creates AuthSuccess with the supplied values.
  const AuthSuccess({required this.token, required this.user});

  /// Decodes AuthSuccess from its JSON representation.
  factory AuthSuccess.fromJson(Map<String, dynamic> json) => AuthSuccess(
    token: _string(json['token']),
    user: _object(json['user'], AuthUserInfo.fromJson),
  );

  /// Returns the JSON representation used by the API.
  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user.toJson(),
  };
}
