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
import 'survey_status.dart' as _i2;
import 'auth_requirement.dart' as _i3;

/// A survey/questionnaire form definition
abstract class Survey implements _i1.SerializableModel {
  Survey._({
    this.id,
    required this.slug,
    required this.title,
    this.description,
    _i2.SurveyStatus? status,
    _i3.AuthRequirement? authRequirement,
    this.createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.startsAt,
    this.endsAt,
  }) : status = status ?? _i2.SurveyStatus.draft,
       authRequirement = authRequirement ?? _i3.AuthRequirement.anonymous,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Survey({
    int? id,
    required String slug,
    required String title,
    String? description,
    _i2.SurveyStatus? status,
    _i3.AuthRequirement? authRequirement,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startsAt,
    DateTime? endsAt,
  }) = _SurveyImpl;

  factory Survey.fromJson(Map<String, dynamic> jsonSerialization) {
    return Survey(
      id: jsonSerialization['id'] as int?,
      slug: jsonSerialization['slug'] as String,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String?,
      status: jsonSerialization['status'] == null
          ? null
          : _i2.SurveyStatus.fromJson((jsonSerialization['status'] as String)),
      authRequirement: jsonSerialization['authRequirement'] == null
          ? null
          : _i3.AuthRequirement.fromJson(
              (jsonSerialization['authRequirement'] as String),
            ),
      createdByUserId: jsonSerialization['createdByUserId'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      startsAt: jsonSerialization['startsAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startsAt']),
      endsAt: jsonSerialization['endsAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['endsAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Unique identifier for the survey (used in URLs)
  String slug;

  /// Title of the survey
  String title;

  /// Optional description of the survey
  String? description;

  /// Current status of the survey
  _i2.SurveyStatus status;

  /// Whether responses require authentication
  _i3.AuthRequirement authRequirement;

  /// Identifier of the admin user who created this survey (from auth system)
  String? createdByUserId;

  /// When the survey was created
  DateTime createdAt;

  /// When the survey was last updated
  DateTime updatedAt;

  /// Optional start date for accepting responses
  DateTime? startsAt;

  /// Optional end date for accepting responses
  DateTime? endsAt;

  /// Returns a shallow copy of this [Survey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Survey copyWith({
    int? id,
    String? slug,
    String? title,
    String? description,
    _i2.SurveyStatus? status,
    _i3.AuthRequirement? authRequirement,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startsAt,
    DateTime? endsAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Survey',
      if (id != null) 'id': id,
      'slug': slug,
      'title': title,
      if (description != null) 'description': description,
      'status': status.toJson(),
      'authRequirement': authRequirement.toJson(),
      if (createdByUserId != null) 'createdByUserId': createdByUserId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (startsAt != null) 'startsAt': startsAt?.toJson(),
      if (endsAt != null) 'endsAt': endsAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SurveyImpl extends Survey {
  _SurveyImpl({
    int? id,
    required String slug,
    required String title,
    String? description,
    _i2.SurveyStatus? status,
    _i3.AuthRequirement? authRequirement,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startsAt,
    DateTime? endsAt,
  }) : super._(
         id: id,
         slug: slug,
         title: title,
         description: description,
         status: status,
         authRequirement: authRequirement,
         createdByUserId: createdByUserId,
         createdAt: createdAt,
         updatedAt: updatedAt,
         startsAt: startsAt,
         endsAt: endsAt,
       );

  /// Returns a shallow copy of this [Survey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Survey copyWith({
    Object? id = _Undefined,
    String? slug,
    String? title,
    Object? description = _Undefined,
    _i2.SurveyStatus? status,
    _i3.AuthRequirement? authRequirement,
    Object? createdByUserId = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? startsAt = _Undefined,
    Object? endsAt = _Undefined,
  }) {
    return Survey(
      id: id is int? ? id : this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description is String? ? description : this.description,
      status: status ?? this.status,
      authRequirement: authRequirement ?? this.authRequirement,
      createdByUserId: createdByUserId is String?
          ? createdByUserId
          : this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startsAt: startsAt is DateTime? ? startsAt : this.startsAt,
      endsAt: endsAt is DateTime? ? endsAt : this.endsAt,
    );
  }
}
