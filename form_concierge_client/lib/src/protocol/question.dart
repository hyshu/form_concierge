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
import 'question_type.dart' as _i2;

/// A question within a survey
abstract class Question implements _i1.SerializableModel {
  Question._({
    this.id,
    required this.surveyId,
    required this.text,
    required this.type,
    required this.orderIndex,
    bool? isRequired,
    this.placeholder,
    this.minLength,
    this.maxLength,
  }) : isRequired = isRequired ?? true;

  factory Question({
    int? id,
    required int surveyId,
    required String text,
    required _i2.QuestionType type,
    required int orderIndex,
    bool? isRequired,
    String? placeholder,
    int? minLength,
    int? maxLength,
  }) = _QuestionImpl;

  factory Question.fromJson(Map<String, dynamic> jsonSerialization) {
    return Question(
      id: jsonSerialization['id'] as int?,
      surveyId: jsonSerialization['surveyId'] as int,
      text: jsonSerialization['text'] as String,
      type: _i2.QuestionType.fromJson((jsonSerialization['type'] as String)),
      orderIndex: jsonSerialization['orderIndex'] as int,
      isRequired: jsonSerialization['isRequired'] as bool?,
      placeholder: jsonSerialization['placeholder'] as String?,
      minLength: jsonSerialization['minLength'] as int?,
      maxLength: jsonSerialization['maxLength'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Reference to the parent survey
  int surveyId;

  /// The question text
  String text;

  /// Type of question (single choice, multiple choice, text, etc.)
  _i2.QuestionType type;

  /// Display order within the survey
  int orderIndex;

  /// Whether this question is required
  bool isRequired;

  /// Optional placeholder text for text inputs
  String? placeholder;

  /// For text inputs: minimum character count
  int? minLength;

  /// For text inputs: maximum character count
  int? maxLength;

  /// Returns a shallow copy of this [Question]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Question copyWith({
    int? id,
    int? surveyId,
    String? text,
    _i2.QuestionType? type,
    int? orderIndex,
    bool? isRequired,
    String? placeholder,
    int? minLength,
    int? maxLength,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Question',
      if (id != null) 'id': id,
      'surveyId': surveyId,
      'text': text,
      'type': type.toJson(),
      'orderIndex': orderIndex,
      'isRequired': isRequired,
      if (placeholder != null) 'placeholder': placeholder,
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _QuestionImpl extends Question {
  _QuestionImpl({
    int? id,
    required int surveyId,
    required String text,
    required _i2.QuestionType type,
    required int orderIndex,
    bool? isRequired,
    String? placeholder,
    int? minLength,
    int? maxLength,
  }) : super._(
         id: id,
         surveyId: surveyId,
         text: text,
         type: type,
         orderIndex: orderIndex,
         isRequired: isRequired,
         placeholder: placeholder,
         minLength: minLength,
         maxLength: maxLength,
       );

  /// Returns a shallow copy of this [Question]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Question copyWith({
    Object? id = _Undefined,
    int? surveyId,
    String? text,
    _i2.QuestionType? type,
    int? orderIndex,
    bool? isRequired,
    Object? placeholder = _Undefined,
    Object? minLength = _Undefined,
    Object? maxLength = _Undefined,
  }) {
    return Question(
      id: id is int? ? id : this.id,
      surveyId: surveyId ?? this.surveyId,
      text: text ?? this.text,
      type: type ?? this.type,
      orderIndex: orderIndex ?? this.orderIndex,
      isRequired: isRequired ?? this.isRequired,
      placeholder: placeholder is String? ? placeholder : this.placeholder,
      minLength: minLength is int? ? minLength : this.minLength,
      maxLength: maxLength is int? ? maxLength : this.maxLength,
    );
  }
}
