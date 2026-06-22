part of form_concierge_client;

class AnonymousAccount {
  final String id;
  final String? displayName;
  final DateTime createdAt;
  final DateTime lastSeenAt;

  const AnonymousAccount({
    required this.id,
    this.displayName,
    required this.createdAt,
    required this.lastSeenAt,
  });

  factory AnonymousAccount.fromJson(Map<String, dynamic> json) =>
      AnonymousAccount(
        id: _string(json['id']),
        displayName: _optionalString(json['displayName']),
        createdAt: _date(json['createdAt']),
        lastSeenAt: _date(json['lastSeenAt']),
      );
}

class AnonymousSession {
  final AnonymousAccount account;
  final String token;

  const AnonymousSession({required this.account, required this.token});

  factory AnonymousSession.fromJson(Map<String, dynamic> json) =>
      AnonymousSession(
        account: _object(json['account'], AnonymousAccount.fromJson),
        token: _string(json['token']),
      );
}

class AdminReply {
  final int id;
  final int surveyResponseId;
  final String anonymousAccountId;
  final String body;
  final String? adminId;
  final DateTime createdAt;
  final DateTime? readAt;

  const AdminReply({
    required this.id,
    required this.surveyResponseId,
    required this.anonymousAccountId,
    required this.body,
    this.adminId,
    required this.createdAt,
    this.readAt,
  });

  factory AdminReply.fromJson(Map<String, dynamic> json) => AdminReply(
    id: _int(json['id']),
    surveyResponseId: _int(json['surveyResponseId']),
    anonymousAccountId: _string(json['anonymousAccountId']),
    body: _string(json['body']),
    adminId: _optionalString(json['adminId']),
    createdAt: _date(json['createdAt']),
    readAt: _optionalDate(json['readAt']),
  );
}
