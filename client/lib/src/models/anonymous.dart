part of form_concierge_client;

/// An anonymous respondent identity used to own submissions and receive replies.
class AnonymousAccount {
  /// The identifier of this anonymous account.
  final String id;

  /// The optional display name attached to the anonymous account.
  final String? displayName;

  /// When this record was created.
  final DateTime createdAt;

  /// When the anonymous account was last active.
  final DateTime lastSeenAt;

  /// Creates AnonymousAccount with the supplied values.
  const AnonymousAccount({
    required this.id,
    this.displayName,
    required this.createdAt,
    required this.lastSeenAt,
  });

  /// Decodes AnonymousAccount from its JSON representation.
  factory AnonymousAccount.fromJson(Map<String, dynamic> json) =>
      AnonymousAccount(
        id: _string(json['id']),
        displayName: _optionalString(json['displayName']),
        createdAt: _date(json['createdAt']),
        lastSeenAt: _date(json['lastSeenAt']),
      );
}

/// An anonymous account and the bearer token used to access it.
class AnonymousSession {
  /// The anonymous account associated with the current session, if known.
  final AnonymousAccount account;

  /// The bearer token used to authenticate requests.
  final String token;

  /// Creates AnonymousSession with the supplied values.
  const AnonymousSession({required this.account, required this.token});

  /// Decodes AnonymousSession from its JSON representation.
  factory AnonymousSession.fromJson(Map<String, dynamic> json) =>
      AnonymousSession(
        account: _object(json['account'], AnonymousAccount.fromJson),
        token: _string(json['token']),
      );
}

/// An administrator's message to the owner of a survey response.
class AdminReply {
  /// The identifier of this admin reply.
  final int id;

  /// The identifier of the associated survey response.
  final int surveyResponseId;

  /// The anonymous account that owns the response or reply.
  final String anonymousAccountId;

  /// The reply text sent to the respondent.
  final String body;

  /// The identifier of the administrator who wrote the reply, if available.
  final String? adminId;

  /// When this record was created.
  final DateTime createdAt;

  /// When the reply was marked as read, if available.
  final DateTime? readAt;

  /// Creates AdminReply with the supplied values.
  const AdminReply({
    required this.id,
    required this.surveyResponseId,
    required this.anonymousAccountId,
    required this.body,
    this.adminId,
    required this.createdAt,
    this.readAt,
  });

  /// Decodes AdminReply from its JSON representation.
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
