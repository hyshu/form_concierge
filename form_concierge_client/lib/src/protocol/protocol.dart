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
import 'admin_user.dart' as _i2;
import 'answer.dart' as _i3;
import 'auth_requirement.dart' as _i4;
import 'auth_user_info.dart' as _i5;
import 'public_config.dart' as _i6;
import 'question.dart' as _i7;
import 'question_option.dart' as _i8;
import 'question_result.dart' as _i9;
import 'question_type.dart' as _i10;
import 'survey.dart' as _i11;
import 'survey_response.dart' as _i12;
import 'survey_results.dart' as _i13;
import 'survey_status.dart' as _i14;
import 'package:form_concierge_client/src/protocol/question.dart' as _i15;
import 'package:form_concierge_client/src/protocol/question_option.dart'
    as _i16;
import 'package:form_concierge_client/src/protocol/survey_response.dart'
    as _i17;
import 'package:form_concierge_client/src/protocol/answer.dart' as _i18;
import 'package:form_concierge_client/src/protocol/survey.dart' as _i19;
import 'package:form_concierge_client/src/protocol/auth_user_info.dart' as _i20;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i21;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i22;
export 'admin_user.dart';
export 'answer.dart';
export 'auth_requirement.dart';
export 'auth_user_info.dart';
export 'public_config.dart';
export 'question.dart';
export 'question_option.dart';
export 'question_result.dart';
export 'question_type.dart';
export 'survey.dart';
export 'survey_response.dart';
export 'survey_results.dart';
export 'survey_status.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.AdminUser) {
      return _i2.AdminUser.fromJson(data) as T;
    }
    if (t == _i3.Answer) {
      return _i3.Answer.fromJson(data) as T;
    }
    if (t == _i4.AuthRequirement) {
      return _i4.AuthRequirement.fromJson(data) as T;
    }
    if (t == _i5.AuthUserInfo) {
      return _i5.AuthUserInfo.fromJson(data) as T;
    }
    if (t == _i6.PublicConfig) {
      return _i6.PublicConfig.fromJson(data) as T;
    }
    if (t == _i7.Question) {
      return _i7.Question.fromJson(data) as T;
    }
    if (t == _i8.QuestionOption) {
      return _i8.QuestionOption.fromJson(data) as T;
    }
    if (t == _i9.QuestionResult) {
      return _i9.QuestionResult.fromJson(data) as T;
    }
    if (t == _i10.QuestionType) {
      return _i10.QuestionType.fromJson(data) as T;
    }
    if (t == _i11.Survey) {
      return _i11.Survey.fromJson(data) as T;
    }
    if (t == _i12.SurveyResponse) {
      return _i12.SurveyResponse.fromJson(data) as T;
    }
    if (t == _i13.SurveyResults) {
      return _i13.SurveyResults.fromJson(data) as T;
    }
    if (t == _i14.SurveyStatus) {
      return _i14.SurveyStatus.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AdminUser?>()) {
      return (data != null ? _i2.AdminUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Answer?>()) {
      return (data != null ? _i3.Answer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AuthRequirement?>()) {
      return (data != null ? _i4.AuthRequirement.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AuthUserInfo?>()) {
      return (data != null ? _i5.AuthUserInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.PublicConfig?>()) {
      return (data != null ? _i6.PublicConfig.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Question?>()) {
      return (data != null ? _i7.Question.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.QuestionOption?>()) {
      return (data != null ? _i8.QuestionOption.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.QuestionResult?>()) {
      return (data != null ? _i9.QuestionResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.QuestionType?>()) {
      return (data != null ? _i10.QuestionType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.Survey?>()) {
      return (data != null ? _i11.Survey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.SurveyResponse?>()) {
      return (data != null ? _i12.SurveyResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.SurveyResults?>()) {
      return (data != null ? _i13.SurveyResults.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.SurveyStatus?>()) {
      return (data != null ? _i14.SurveyStatus.fromJson(data) : null) as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == Map<int, int>) {
      return Map.fromEntries(
            (data as List).map(
              (e) =>
                  MapEntry(deserialize<int>(e['k']), deserialize<int>(e['v'])),
            ),
          )
          as T;
    }
    if (t == _i1.getType<Map<int, int>?>()) {
      return (data != null
              ? Map.fromEntries(
                  (data as List).map(
                    (e) => MapEntry(
                      deserialize<int>(e['k']),
                      deserialize<int>(e['v']),
                    ),
                  ),
                )
              : null)
          as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i9.QuestionResult>) {
      return (data as List)
              .map((e) => deserialize<_i9.QuestionResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i15.Question>) {
      return (data as List).map((e) => deserialize<_i15.Question>(e)).toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i16.QuestionOption>) {
      return (data as List)
              .map((e) => deserialize<_i16.QuestionOption>(e))
              .toList()
          as T;
    }
    if (t == List<_i17.SurveyResponse>) {
      return (data as List)
              .map((e) => deserialize<_i17.SurveyResponse>(e))
              .toList()
          as T;
    }
    if (t == List<_i18.Answer>) {
      return (data as List).map((e) => deserialize<_i18.Answer>(e)).toList()
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<_i19.Survey>) {
      return (data as List).map((e) => deserialize<_i19.Survey>(e)).toList()
          as T;
    }
    if (t == List<_i20.AuthUserInfo>) {
      return (data as List)
              .map((e) => deserialize<_i20.AuthUserInfo>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    try {
      return _i21.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i22.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AdminUser => 'AdminUser',
      _i3.Answer => 'Answer',
      _i4.AuthRequirement => 'AuthRequirement',
      _i5.AuthUserInfo => 'AuthUserInfo',
      _i6.PublicConfig => 'PublicConfig',
      _i7.Question => 'Question',
      _i8.QuestionOption => 'QuestionOption',
      _i9.QuestionResult => 'QuestionResult',
      _i10.QuestionType => 'QuestionType',
      _i11.Survey => 'Survey',
      _i12.SurveyResponse => 'SurveyResponse',
      _i13.SurveyResults => 'SurveyResults',
      _i14.SurveyStatus => 'SurveyStatus',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'form_concierge.',
        '',
      );
    }

    switch (data) {
      case _i2.AdminUser():
        return 'AdminUser';
      case _i3.Answer():
        return 'Answer';
      case _i4.AuthRequirement():
        return 'AuthRequirement';
      case _i5.AuthUserInfo():
        return 'AuthUserInfo';
      case _i6.PublicConfig():
        return 'PublicConfig';
      case _i7.Question():
        return 'Question';
      case _i8.QuestionOption():
        return 'QuestionOption';
      case _i9.QuestionResult():
        return 'QuestionResult';
      case _i10.QuestionType():
        return 'QuestionType';
      case _i11.Survey():
        return 'Survey';
      case _i12.SurveyResponse():
        return 'SurveyResponse';
      case _i13.SurveyResults():
        return 'SurveyResults';
      case _i14.SurveyStatus():
        return 'SurveyStatus';
    }
    className = _i21.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i22.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AdminUser') {
      return deserialize<_i2.AdminUser>(data['data']);
    }
    if (dataClassName == 'Answer') {
      return deserialize<_i3.Answer>(data['data']);
    }
    if (dataClassName == 'AuthRequirement') {
      return deserialize<_i4.AuthRequirement>(data['data']);
    }
    if (dataClassName == 'AuthUserInfo') {
      return deserialize<_i5.AuthUserInfo>(data['data']);
    }
    if (dataClassName == 'PublicConfig') {
      return deserialize<_i6.PublicConfig>(data['data']);
    }
    if (dataClassName == 'Question') {
      return deserialize<_i7.Question>(data['data']);
    }
    if (dataClassName == 'QuestionOption') {
      return deserialize<_i8.QuestionOption>(data['data']);
    }
    if (dataClassName == 'QuestionResult') {
      return deserialize<_i9.QuestionResult>(data['data']);
    }
    if (dataClassName == 'QuestionType') {
      return deserialize<_i10.QuestionType>(data['data']);
    }
    if (dataClassName == 'Survey') {
      return deserialize<_i11.Survey>(data['data']);
    }
    if (dataClassName == 'SurveyResponse') {
      return deserialize<_i12.SurveyResponse>(data['data']);
    }
    if (dataClassName == 'SurveyResults') {
      return deserialize<_i13.SurveyResults>(data['data']);
    }
    if (dataClassName == 'SurveyStatus') {
      return deserialize<_i14.SurveyStatus>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i21.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i22.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i21.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i22.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
