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
import 'question_result.dart' as _i2;
import 'package:form_concierge_client/src/protocol/protocol.dart' as _i3;

/// Aggregated survey results (non-persisted model)
abstract class SurveyResults implements _i1.SerializableModel {
  SurveyResults._({
    required this.surveyId,
    required this.totalResponses,
    required this.questionResults,
  });

  factory SurveyResults({
    required int surveyId,
    required int totalResponses,
    required List<_i2.QuestionResult> questionResults,
  }) = _SurveyResultsImpl;

  factory SurveyResults.fromJson(Map<String, dynamic> jsonSerialization) {
    return SurveyResults(
      surveyId: jsonSerialization['surveyId'] as int,
      totalResponses: jsonSerialization['totalResponses'] as int,
      questionResults: _i3.Protocol().deserialize<List<_i2.QuestionResult>>(
        jsonSerialization['questionResults'],
      ),
    );
  }

  int surveyId;

  int totalResponses;

  List<_i2.QuestionResult> questionResults;

  /// Returns a shallow copy of this [SurveyResults]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SurveyResults copyWith({
    int? surveyId,
    int? totalResponses,
    List<_i2.QuestionResult>? questionResults,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SurveyResults',
      'surveyId': surveyId,
      'totalResponses': totalResponses,
      'questionResults': questionResults.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SurveyResultsImpl extends SurveyResults {
  _SurveyResultsImpl({
    required int surveyId,
    required int totalResponses,
    required List<_i2.QuestionResult> questionResults,
  }) : super._(
         surveyId: surveyId,
         totalResponses: totalResponses,
         questionResults: questionResults,
       );

  /// Returns a shallow copy of this [SurveyResults]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SurveyResults copyWith({
    int? surveyId,
    int? totalResponses,
    List<_i2.QuestionResult>? questionResults,
  }) {
    return SurveyResults(
      surveyId: surveyId ?? this.surveyId,
      totalResponses: totalResponses ?? this.totalResponses,
      questionResults:
          questionResults ??
          this.questionResults.map((e0) => e0.copyWith()).toList(),
    );
  }
}
