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
import 'question_type.dart' as _i2;
import 'package:form_concierge_server/src/generated/protocol.dart' as _i3;

/// Aggregated results for a single question (non-persisted model)
abstract class QuestionResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  QuestionResult._({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    this.optionCounts,
    this.textResponses,
  });

  factory QuestionResult({
    required int questionId,
    required String questionText,
    required _i2.QuestionType questionType,
    Map<int, int>? optionCounts,
    List<String>? textResponses,
  }) = _QuestionResultImpl;

  factory QuestionResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return QuestionResult(
      questionId: jsonSerialization['questionId'] as int,
      questionText: jsonSerialization['questionText'] as String,
      questionType: _i2.QuestionType.fromJson(
        (jsonSerialization['questionType'] as String),
      ),
      optionCounts: jsonSerialization['optionCounts'] == null
          ? null
          : _i3.Protocol().deserialize<Map<int, int>>(
              jsonSerialization['optionCounts'],
            ),
      textResponses: jsonSerialization['textResponses'] == null
          ? null
          : _i3.Protocol().deserialize<List<String>>(
              jsonSerialization['textResponses'],
            ),
    );
  }

  int questionId;

  String questionText;

  _i2.QuestionType questionType;

  /// Option ID to count mapping (for choice questions)
  Map<int, int>? optionCounts;

  /// Text responses (for text questions)
  List<String>? textResponses;

  /// Returns a shallow copy of this [QuestionResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  QuestionResult copyWith({
    int? questionId,
    String? questionText,
    _i2.QuestionType? questionType,
    Map<int, int>? optionCounts,
    List<String>? textResponses,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QuestionResult',
      'questionId': questionId,
      'questionText': questionText,
      'questionType': questionType.toJson(),
      if (optionCounts != null) 'optionCounts': optionCounts?.toJson(),
      if (textResponses != null) 'textResponses': textResponses?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'QuestionResult',
      'questionId': questionId,
      'questionText': questionText,
      'questionType': questionType.toJson(),
      if (optionCounts != null) 'optionCounts': optionCounts?.toJson(),
      if (textResponses != null) 'textResponses': textResponses?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _QuestionResultImpl extends QuestionResult {
  _QuestionResultImpl({
    required int questionId,
    required String questionText,
    required _i2.QuestionType questionType,
    Map<int, int>? optionCounts,
    List<String>? textResponses,
  }) : super._(
         questionId: questionId,
         questionText: questionText,
         questionType: questionType,
         optionCounts: optionCounts,
         textResponses: textResponses,
       );

  /// Returns a shallow copy of this [QuestionResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  QuestionResult copyWith({
    int? questionId,
    String? questionText,
    _i2.QuestionType? questionType,
    Object? optionCounts = _Undefined,
    Object? textResponses = _Undefined,
  }) {
    return QuestionResult(
      questionId: questionId ?? this.questionId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      optionCounts: optionCounts is Map<int, int>?
          ? optionCounts
          : this.optionCounts?.map(
              (
                key0,
                value0,
              ) => MapEntry(
                key0,
                value0,
              ),
            ),
      textResponses: textResponses is List<String>?
          ? textResponses
          : this.textResponses?.map((e0) => e0).toList(),
    );
  }
}
