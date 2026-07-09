import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

class FormConciergeReplyCheckResult {
  final DateTime? latestReplyAt;
  final DateTime? lastSeenReplyAt;

  const FormConciergeReplyCheckResult({
    required this.latestReplyAt,
    required this.lastSeenReplyAt,
  });

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
/// The widget package never writes to disk itself — the host app owns
/// SharedPreferences, secure storage, or any other backend.
class FormConciergeReplySeenStore {
  final Future<String?> Function(String key) read;
  final Future<void> Function(String key, String value) write;
  final Future<void> Function(String key) remove;

  const FormConciergeReplySeenStore({
    required this.read,
    required this.write,
    required this.remove,
  });
}

class FormConciergeReplyChecker {
  final Client client;
  final String anonymousToken;
  final int? responseId;
  final String storageKey;
  final FormConciergeReplySeenStore store;

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

  Future<DateTime?> readLastSeenReplyAt() async {
    final value = await store.read(storageKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> markSeenAt(DateTime date) async {
    await store.write(storageKey, date.toUtc().toIso8601String());
  }

  Future<void> markLatestSeen() async {
    client.anonymous.useToken(anonymousToken);
    final latestReplyAt = await client.anonymous.getLatestReplyAt(
      responseId: responseId,
    );
    if (latestReplyAt != null) {
      await markSeenAt(latestReplyAt);
    }
  }

  Future<void> clearSeen() async {
    await store.remove(storageKey);
  }
}
