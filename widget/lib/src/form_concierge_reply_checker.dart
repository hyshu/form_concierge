import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class FormConciergeReplyChecker {
  final Client client;
  final String anonymousToken;
  final int? responseId;
  final String storageKey;

  FormConciergeReplyChecker({
    required this.client,
    required this.anonymousToken,
    this.responseId,
    String? storageKey,
  }) : storageKey =
           storageKey ??
           defaultStorageKey(
             baseUri: client.baseUri,
             anonymousToken: anonymousToken,
             responseId: responseId,
           );

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
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(storageKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> markSeenAt(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, date.toUtc().toIso8601String());
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
