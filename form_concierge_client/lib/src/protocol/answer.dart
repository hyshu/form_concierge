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
import 'package:form_concierge_client/src/protocol/protocol.dart' as _i2;

/// An individual answer to a question
abstract class Answer implements _i1.SerializableModel {
  Answer._({
    this.id,
    required this.surveyResponseId,
    required this.questionId,
    this.textValue,
    this.selectedOptionIds,
  });

  factory Answer({
    int? id,
    required int surveyResponseId,
    required int questionId,
    String? textValue,
    List<int>? selectedOptionIds,
  }) = _AnswerImpl;

  factory Answer.fromJson(Map<String, dynamic> jsonSerialization) {
    return Answer(
      id: jsonSerialization['id'] as int?,
      surveyResponseId: jsonSerialization['surveyResponseId'] as int,
      questionId: jsonSerialization['questionId'] as int,
      textValue: jsonSerialization['textValue'] as String?,
      selectedOptionIds: jsonSerialization['selectedOptionIds'] == null
          ? null
          : _i2.Protocol().deserialize<List<int>>(
              jsonSerialization['selectedOptionIds'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Reference to the survey response
  int surveyResponseId;

  /// Reference to the question being answered
  int questionId;

  /// Text answer (for text-type questions)
  String? textValue;

  /// Selected option IDs (for choice questions)
  List<int>? selectedOptionIds;

  /// Returns a shallow copy of this [Answer]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Answer copyWith({
    int? id,
    int? surveyResponseId,
    int? questionId,
    String? textValue,
    List<int>? selectedOptionIds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Answer',
      if (id != null) 'id': id,
      'surveyResponseId': surveyResponseId,
      'questionId': questionId,
      if (textValue != null) 'textValue': textValue,
      if (selectedOptionIds != null)
        'selectedOptionIds': selectedOptionIds?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AnswerImpl extends Answer {
  _AnswerImpl({
    int? id,
    required int surveyResponseId,
    required int questionId,
    String? textValue,
    List<int>? selectedOptionIds,
  }) : super._(
         id: id,
         surveyResponseId: surveyResponseId,
         questionId: questionId,
         textValue: textValue,
         selectedOptionIds: selectedOptionIds,
       );

  /// Returns a shallow copy of this [Answer]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Answer copyWith({
    Object? id = _Undefined,
    int? surveyResponseId,
    int? questionId,
    Object? textValue = _Undefined,
    Object? selectedOptionIds = _Undefined,
  }) {
    return Answer(
      id: id is int? ? id : this.id,
      surveyResponseId: surveyResponseId ?? this.surveyResponseId,
      questionId: questionId ?? this.questionId,
      textValue: textValue is String? ? textValue : this.textValue,
      selectedOptionIds: selectedOptionIds is List<int>?
          ? selectedOptionIds
          : this.selectedOptionIds?.map((e0) => e0).toList(),
    );
  }
}
