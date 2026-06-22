part of form_concierge_client;

class AuthUserInfo {
  final UuidValue id;
  final String? email;
  final List<String> scopeNames;
  final AdminRole role;
  final DateTime created;

  const AuthUserInfo({
    required this.id,
    this.email,
    required this.scopeNames,
    required this.role,
    required this.created,
  });

  factory AuthUserInfo.fromJson(Map<String, dynamic> json) => AuthUserInfo(
    id: _string(json['id']),
    email: _optionalString(json['email']),
    scopeNames: _stringList(json['scopeNames']),
    role: _enum(AdminRole.values, json['role']),
    created: _date(json['created']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'email': email,
    'scopeNames': scopeNames,
    'role': _enumName(role),
    'created': created.toIso8601String(),
  });
}

class AuthSuccess {
  final String token;
  final AuthUserInfo user;

  const AuthSuccess({required this.token, required this.user});

  factory AuthSuccess.fromJson(Map<String, dynamic> json) => AuthSuccess(
    token: _string(json['token']),
    user: _object(json['user'], AuthUserInfo.fromJson),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user.toJson(),
  };
}
