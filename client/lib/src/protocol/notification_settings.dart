/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// Configuration for daily email notifications per survey
abstract class NotificationSettings implements _i1.SerializableModel {
  NotificationSettings._({
    this.id,
    required this.surveyId,
    bool? enabled,
    required this.recipientEmail,
    int? sendHour,
    DateTime? updatedAt,
    this.lastSentAt,
  }) : enabled = enabled ?? false,
       sendHour = sendHour ?? 9,
       updatedAt = updatedAt ?? DateTime.now();

  factory NotificationSettings({
    int? id,
    required int surveyId,
    bool? enabled,
    required String recipientEmail,
    int? sendHour,
    DateTime? updatedAt,
    DateTime? lastSentAt,
  }) = _NotificationSettingsImpl;

  factory NotificationSettings.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotificationSettings(
      id: jsonSerialization['id'] as int?,
      surveyId: jsonSerialization['surveyId'] as int,
      enabled: jsonSerialization['enabled'] as bool?,
      recipientEmail: jsonSerialization['recipientEmail'] as String,
      sendHour: jsonSerialization['sendHour'] as int?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      lastSentAt: jsonSerialization['lastSentAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastSentAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Reference to the survey (one settings record per survey)
  int surveyId;

  /// Whether daily notifications are enabled
  bool enabled;

  /// Email address to receive notifications
  String recipientEmail;

  /// Hour of day to send notification (0-23, UTC)
  int sendHour;

  /// When settings were last updated
  DateTime updatedAt;

  /// Last time notification was sent (null if never)
  DateTime? lastSentAt;

  /// Returns a shallow copy of this [NotificationSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationSettings copyWith({
    int? id,
    int? surveyId,
    bool? enabled,
    String? recipientEmail,
    int? sendHour,
    DateTime? updatedAt,
    DateTime? lastSentAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationSettings',
      if (id != null) 'id': id,
      'surveyId': surveyId,
      'enabled': enabled,
      'recipientEmail': recipientEmail,
      'sendHour': sendHour,
      'updatedAt': updatedAt.toJson(),
      if (lastSentAt != null) 'lastSentAt': lastSentAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationSettingsImpl extends NotificationSettings {
  _NotificationSettingsImpl({
    int? id,
    required int surveyId,
    bool? enabled,
    required String recipientEmail,
    int? sendHour,
    DateTime? updatedAt,
    DateTime? lastSentAt,
  }) : super._(
         id: id,
         surveyId: surveyId,
         enabled: enabled,
         recipientEmail: recipientEmail,
         sendHour: sendHour,
         updatedAt: updatedAt,
         lastSentAt: lastSentAt,
       );

  /// Returns a shallow copy of this [NotificationSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationSettings copyWith({
    Object? id = _Undefined,
    int? surveyId,
    bool? enabled,
    String? recipientEmail,
    int? sendHour,
    DateTime? updatedAt,
    Object? lastSentAt = _Undefined,
  }) {
    return NotificationSettings(
      id: id is int? ? id : this.id,
      surveyId: surveyId ?? this.surveyId,
      enabled: enabled ?? this.enabled,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      sendHour: sendHour ?? this.sendHour,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSentAt: lastSentAt is DateTime? ? lastSentAt : this.lastSentAt,
    );
  }
}
