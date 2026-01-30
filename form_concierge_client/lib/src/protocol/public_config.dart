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

abstract class PublicConfig implements _i1.SerializableModel {
  PublicConfig._({
    required this.passwordResetEnabled,
    required this.requireEmailVerification,
    required this.geminiEnabled,
  });

  factory PublicConfig({
    required bool passwordResetEnabled,
    required bool requireEmailVerification,
    required bool geminiEnabled,
  }) = _PublicConfigImpl;

  factory PublicConfig.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicConfig(
      passwordResetEnabled: jsonSerialization['passwordResetEnabled'] as bool,
      requireEmailVerification:
          jsonSerialization['requireEmailVerification'] as bool,
      geminiEnabled: jsonSerialization['geminiEnabled'] as bool,
    );
  }

  bool passwordResetEnabled;

  bool requireEmailVerification;

  bool geminiEnabled;

  /// Returns a shallow copy of this [PublicConfig]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PublicConfig copyWith({
    bool? passwordResetEnabled,
    bool? requireEmailVerification,
    bool? geminiEnabled,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicConfig',
      'passwordResetEnabled': passwordResetEnabled,
      'requireEmailVerification': requireEmailVerification,
      'geminiEnabled': geminiEnabled,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PublicConfigImpl extends PublicConfig {
  _PublicConfigImpl({
    required bool passwordResetEnabled,
    required bool requireEmailVerification,
    required bool geminiEnabled,
  }) : super._(
         passwordResetEnabled: passwordResetEnabled,
         requireEmailVerification: requireEmailVerification,
         geminiEnabled: geminiEnabled,
       );

  /// Returns a shallow copy of this [PublicConfig]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PublicConfig copyWith({
    bool? passwordResetEnabled,
    bool? requireEmailVerification,
    bool? geminiEnabled,
  }) {
    return PublicConfig(
      passwordResetEnabled: passwordResetEnabled ?? this.passwordResetEnabled,
      requireEmailVerification:
          requireEmailVerification ?? this.requireEmailVerification,
      geminiEnabled: geminiEnabled ?? this.geminiEnabled,
    );
  }
}
