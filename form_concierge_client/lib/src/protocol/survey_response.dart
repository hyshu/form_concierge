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

/// A complete survey response submission
abstract class SurveyResponse implements _i1.SerializableModel {
  SurveyResponse._({
    this.id,
    required this.surveyId,
    this.userId,
    this.anonymousId,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  factory SurveyResponse({
    int? id,
    required int surveyId,
    String? userId,
    String? anonymousId,
    DateTime? submittedAt,
  }) = _SurveyResponseImpl;

  factory SurveyResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return SurveyResponse(
      id: jsonSerialization['id'] as int?,
      surveyId: jsonSerialization['surveyId'] as int,
      userId: jsonSerialization['userId'] as String?,
      anonymousId: jsonSerialization['anonymousId'] as String?,
      submittedAt: jsonSerialization['submittedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['submittedAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Reference to the survey being responded to
  int surveyId;

  /// User identifier if authenticated response (from auth system)
  String? userId;

  /// Anonymous session identifier
  String? anonymousId;

  /// When the response was submitted
  DateTime submittedAt;

  /// Returns a shallow copy of this [SurveyResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SurveyResponse copyWith({
    int? id,
    int? surveyId,
    String? userId,
    String? anonymousId,
    DateTime? submittedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SurveyResponse',
      if (id != null) 'id': id,
      'surveyId': surveyId,
      if (userId != null) 'userId': userId,
      if (anonymousId != null) 'anonymousId': anonymousId,
      'submittedAt': submittedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SurveyResponseImpl extends SurveyResponse {
  _SurveyResponseImpl({
    int? id,
    required int surveyId,
    String? userId,
    String? anonymousId,
    DateTime? submittedAt,
  }) : super._(
         id: id,
         surveyId: surveyId,
         userId: userId,
         anonymousId: anonymousId,
         submittedAt: submittedAt,
       );

  /// Returns a shallow copy of this [SurveyResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SurveyResponse copyWith({
    Object? id = _Undefined,
    int? surveyId,
    Object? userId = _Undefined,
    Object? anonymousId = _Undefined,
    DateTime? submittedAt,
  }) {
    return SurveyResponse(
      id: id is int? ? id : this.id,
      surveyId: surveyId ?? this.surveyId,
      userId: userId is String? ? userId : this.userId,
      anonymousId: anonymousId is String? ? anonymousId : this.anonymousId,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}
