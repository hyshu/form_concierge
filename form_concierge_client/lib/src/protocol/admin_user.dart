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

/// Extended admin user with roles
abstract class AdminUser implements _i1.SerializableModel {
  AdminUser._({
    this.id,
    required this.userId,
    required this.displayName,
    bool? isAdmin,
    bool? canCreateSurveys,
    DateTime? createdAt,
  }) : isAdmin = isAdmin ?? false,
       canCreateSurveys = canCreateSurveys ?? true,
       createdAt = createdAt ?? DateTime.now();

  factory AdminUser({
    int? id,
    required int userId,
    required String displayName,
    bool? isAdmin,
    bool? canCreateSurveys,
    DateTime? createdAt,
  }) = _AdminUserImpl;

  factory AdminUser.fromJson(Map<String, dynamic> jsonSerialization) {
    return AdminUser(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      displayName: jsonSerialization['displayName'] as String,
      isAdmin: jsonSerialization['isAdmin'] as bool?,
      canCreateSurveys: jsonSerialization['canCreateSurveys'] as bool?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Reference to the auth user
  int userId;

  /// Admin display name
  String displayName;

  /// Whether user has admin access
  bool isAdmin;

  /// Whether user can create surveys
  bool canCreateSurveys;

  /// When the admin user was created
  DateTime createdAt;

  /// Returns a shallow copy of this [AdminUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdminUser copyWith({
    int? id,
    int? userId,
    String? displayName,
    bool? isAdmin,
    bool? canCreateSurveys,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminUser',
      if (id != null) 'id': id,
      'userId': userId,
      'displayName': displayName,
      'isAdmin': isAdmin,
      'canCreateSurveys': canCreateSurveys,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AdminUserImpl extends AdminUser {
  _AdminUserImpl({
    int? id,
    required int userId,
    required String displayName,
    bool? isAdmin,
    bool? canCreateSurveys,
    DateTime? createdAt,
  }) : super._(
         id: id,
         userId: userId,
         displayName: displayName,
         isAdmin: isAdmin,
         canCreateSurveys: canCreateSurveys,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AdminUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdminUser copyWith({
    Object? id = _Undefined,
    int? userId,
    String? displayName,
    bool? isAdmin,
    bool? canCreateSurveys,
    DateTime? createdAt,
  }) {
    return AdminUser(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
      canCreateSurveys: canCreateSurveys ?? this.canCreateSurveys,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
