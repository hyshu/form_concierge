import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

/// Result of comparing the latest server reply with the host's last-seen value.
class FormConciergeReplyCheckResult {
  /// The time of the latest administrator reply, if one exists.
  final DateTime? latestReplyAt;

  /// The latest reply time previously marked as seen, if available.
  final DateTime? lastSeenReplyAt;

  /// Creates FormConciergeReplyCheckResult with the supplied values.
  const FormConciergeReplyCheckResult({
    required this.latestReplyAt,
    required this.lastSeenReplyAt,
  });

  /// Whether the latest reply is newer than the stored seen time, or no seen time exists
  /// yet.
  bool get hasNewReplies {
    final latest = latestReplyAt;
    if (latest == null) return false;
    final seen = lastSeenReplyAt;
    if (seen == null) return true;
    return latest.toUtc().isAfter(seen.toUtc());
  }
}

/// Host-provided persistence for last-seen reply timestamps.
///
/// The host app owns persistence through
/// SharedPreferences, secure storage, or any other backend.
class FormConciergeReplySeenStore {
  /// Reads a stored value for the supplied persistence key.
  final Future<String?> Function(String key) read;

  /// Stores a value under the supplied persistence key.
  final Future<void> Function(String key, String value) write;

  /// Removes the value associated with the supplied persistence key.
  final Future<void> Function(String key) remove;

  /// Creates FormConciergeReplySeenStore with the supplied values.
  const FormConciergeReplySeenStore({
    required this.read,
    required this.write,
    required this.remove,
  });
}

/// Checks for unseen admin replies without downloading the full reply list.
///
/// Last-seen timestamps live in the host-provided [store]. Call
/// [markLatestSeen] after the host has shown the latest reply to the user.
class FormConciergeReplyChecker {
  /// The API client used to load data and submit changes.
  final Client client;

  /// The bearer token for the anonymous respondent account.
  final String anonymousToken;

  /// The identifier of the associated survey response.
  final int? responseId;

  /// The key used to persist state for this server and respondent.
  final String storageKey;

  /// The persistence callbacks used to track the latest seen reply.
  final FormConciergeReplySeenStore store;

  /// Creates FormConciergeReplyChecker with the supplied values.
  FormConciergeReplyChecker({
    required this.client,
    required this.anonymousToken,
    required this.store,
    this.responseId,
    String? storageKey,
  }) : storageKey =
           storageKey ??
           defaultStorageKey(
             baseUri: client.baseUri,
             anonymousToken: anonymousToken,
             responseId: responseId,
           );

  /// Suggested key for the host store. The host may use any key scheme.
  static String defaultStorageKey({
    required Uri baseUri,
    required String anonymousToken,
    int? responseId,
  }) {
    final tokenHash = sha256.convert(utf8.encode(anonymousToken)).toString();
    final scope = responseId == null ? 'all' : 'response_$responseId';
    return 'form_concierge.reply_seen.${baseUri.toString()}.$scope.$tokenHash';
  }

  /// Compares the latest reply time with local seen state and optionally marks it seen.
  /// Sets the client's anonymous token before requesting replies.
  Future<FormConciergeReplyCheckResult> check({bool markSeen = false}) async {
    client.anonymous.useToken(anonymousToken);
    final latestReplyAt = await client.anonymous.getLatestReplyAt(
      responseId: responseId,
    );
    final lastSeenReplyAt = await readLastSeenReplyAt();
    final result = FormConciergeReplyCheckResult(
      latestReplyAt: latestReplyAt,
      lastSeenReplyAt: lastSeenReplyAt,
    );
    if (markSeen && latestReplyAt != null) {
      await markSeenAt(latestReplyAt);
    }
    return result;
  }

  /// Returns the stored seen time, or null when the value is absent or invalid.
  Future<DateTime?> readLastSeenReplyAt() async {
    final value = await store.read(storageKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  /// Stores the supplied reply time in UTC as the latest seen value.
  Future<void> markSeenAt(DateTime date) =>
      store.write(storageKey, date.toUtc().toIso8601String());

  /// Fetches the latest reply time and marks it seen if a reply exists.
  Future<void> markLatestSeen() async {
    client.anonymous.useToken(anonymousToken);
    final latestReplyAt = await client.anonymous.getLatestReplyAt(
      responseId: responseId,
    );
    if (latestReplyAt != null) {
      await markSeenAt(latestReplyAt);
    }
  }

  /// Removes the stored seen time for this reply scope.
  Future<void> clearSeen() => store.remove(storageKey);
}
