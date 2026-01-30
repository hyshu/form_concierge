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
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:form_concierge_server/src/generated/protocol.dart' as _i2;

abstract class AuthUserInfo
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AuthUserInfo._({
    required this.id,
    this.email,
    required this.scopeNames,
    required this.blocked,
    required this.created,
  });

  factory AuthUserInfo({
    required _i1.UuidValue id,
    String? email,
    required List<String> scopeNames,
    required bool blocked,
    required DateTime created,
  }) = _AuthUserInfoImpl;

  factory AuthUserInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthUserInfo(
      id: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      email: jsonSerialization['email'] as String?,
      scopeNames: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['scopeNames'],
      ),
      blocked: jsonSerialization['blocked'] as bool,
      created: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
    );
  }

  _i1.UuidValue id;

  String? email;

  List<String> scopeNames;

  bool blocked;

  DateTime created;

  /// Returns a shallow copy of this [AuthUserInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuthUserInfo copyWith({
    _i1.UuidValue? id,
    String? email,
    List<String>? scopeNames,
    bool? blocked,
    DateTime? created,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthUserInfo',
      'id': id.toJson(),
      if (email != null) 'email': email,
      'scopeNames': scopeNames.toJson(),
      'blocked': blocked,
      'created': created.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuthUserInfo',
      'id': id.toJson(),
      if (email != null) 'email': email,
      'scopeNames': scopeNames.toJson(),
      'blocked': blocked,
      'created': created.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuthUserInfoImpl extends AuthUserInfo {
  _AuthUserInfoImpl({
    required _i1.UuidValue id,
    String? email,
    required List<String> scopeNames,
    required bool blocked,
    required DateTime created,
  }) : super._(
         id: id,
         email: email,
         scopeNames: scopeNames,
         blocked: blocked,
         created: created,
       );

  /// Returns a shallow copy of this [AuthUserInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuthUserInfo copyWith({
    _i1.UuidValue? id,
    Object? email = _Undefined,
    List<String>? scopeNames,
    bool? blocked,
    DateTime? created,
  }) {
    return AuthUserInfo(
      id: id ?? this.id,
      email: email is String? ? email : this.email,
      scopeNames: scopeNames ?? this.scopeNames.map((e0) => e0).toList(),
      blocked: blocked ?? this.blocked,
      created: created ?? this.created,
    );
  }
}
