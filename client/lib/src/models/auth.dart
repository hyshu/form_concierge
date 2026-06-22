part of form_concierge_client;

class AuthUserInfo {
  final UuidValue id;
  final String? email;
  final List<String> scopeNames;
  final AdminRole role;
  final bool blocked;
  final DateTime created;

  const AuthUserInfo({
    required this.id,
    this.email,
    required this.scopeNames,
    required this.role,
    required this.blocked,
    required this.created,
  });

  factory AuthUserInfo.fromJson(Map<String, dynamic> json) => AuthUserInfo(
    id: json['id'].toString(),
    email: json['email'] as String?,
    scopeNames: (json['scopeNames'] as List? ?? const [])
        .map((e) => '$e')
        .toList(),
    role: _enum(AdminRole.values, json['role'], AdminRole.viewer),
    blocked: _bool(json['blocked']),
    created: _date(json['created']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'email': email,
    'scopeNames': scopeNames,
    'role': _enumName(role),
    'blocked': blocked,
    'created': created.toIso8601String(),
  });
}

class AuthSuccess {
  final String token;
  final AuthUserInfo user;

  const AuthSuccess({required this.token, required this.user});

  factory AuthSuccess.fromJson(Map<String, dynamic> json) => AuthSuccess(
    token: json['token'] as String,
    user: _object(json['user'], AuthUserInfo.fromJson),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user.toJson(),
  };
}
