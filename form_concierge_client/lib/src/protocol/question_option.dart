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

/// An option for choice-type questions
abstract class QuestionOption implements _i1.SerializableModel {
  QuestionOption._({
    this.id,
    required this.questionId,
    required this.text,
    required this.orderIndex,
    this.value,
  });

  factory QuestionOption({
    int? id,
    required int questionId,
    required String text,
    required int orderIndex,
    String? value,
  }) = _QuestionOptionImpl;

  factory QuestionOption.fromJson(Map<String, dynamic> jsonSerialization) {
    return QuestionOption(
      id: jsonSerialization['id'] as int?,
      questionId: jsonSerialization['questionId'] as int,
      text: jsonSerialization['text'] as String,
      orderIndex: jsonSerialization['orderIndex'] as int,
      value: jsonSerialization['value'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Reference to the parent question
  int questionId;

  /// The option text
  String text;

  /// Display order within the question
  int orderIndex;

  /// Optional value (if different from text)
  String? value;

  /// Returns a shallow copy of this [QuestionOption]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  QuestionOption copyWith({
    int? id,
    int? questionId,
    String? text,
    int? orderIndex,
    String? value,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QuestionOption',
      if (id != null) 'id': id,
      'questionId': questionId,
      'text': text,
      'orderIndex': orderIndex,
      if (value != null) 'value': value,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _QuestionOptionImpl extends QuestionOption {
  _QuestionOptionImpl({
    int? id,
    required int questionId,
    required String text,
    required int orderIndex,
    String? value,
  }) : super._(
         id: id,
         questionId: questionId,
         text: text,
         orderIndex: orderIndex,
         value: value,
       );

  /// Returns a shallow copy of this [QuestionOption]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  QuestionOption copyWith({
    Object? id = _Undefined,
    int? questionId,
    String? text,
    int? orderIndex,
    Object? value = _Undefined,
  }) {
    return QuestionOption(
      id: id is int? ? id : this.id,
      questionId: questionId ?? this.questionId,
      text: text ?? this.text,
      orderIndex: orderIndex ?? this.orderIndex,
      value: value is String? ? value : this.value,
    );
  }
}
