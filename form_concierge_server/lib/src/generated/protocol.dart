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
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i4;
import 'admin_user.dart' as _i5;
import 'answer.dart' as _i6;
import 'auth_requirement.dart' as _i7;
import 'auth_user_info.dart' as _i8;
import 'choice.dart' as _i9;
import 'public_config.dart' as _i10;
import 'question.dart' as _i11;
import 'question_result.dart' as _i12;
import 'question_type.dart' as _i13;
import 'question_with_choices.dart' as _i14;
import 'survey.dart' as _i15;
import 'survey_response.dart' as _i16;
import 'survey_results.dart' as _i17;
import 'survey_status.dart' as _i18;
import 'package:form_concierge_server/src/generated/choice.dart' as _i19;
import 'package:form_concierge_server/src/generated/question.dart' as _i20;
import 'package:form_concierge_server/src/generated/survey_response.dart'
    as _i21;
import 'package:form_concierge_server/src/generated/answer.dart' as _i22;
import 'package:form_concierge_server/src/generated/question_with_choices.dart'
    as _i23;
import 'package:form_concierge_server/src/generated/survey.dart' as _i24;
import 'package:form_concierge_server/src/generated/auth_user_info.dart'
    as _i25;
export 'admin_user.dart';
export 'answer.dart';
export 'auth_requirement.dart';
export 'auth_user_info.dart';
export 'choice.dart';
export 'public_config.dart';
export 'question.dart';
export 'question_result.dart';
export 'question_type.dart';
export 'question_with_choices.dart';
export 'survey.dart';
export 'survey_response.dart';
export 'survey_results.dart';
export 'survey_status.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'admin_user',
      dartName: 'AdminUser',
      schema: 'public',
      module: 'form_concierge',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'admin_user_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'isAdmin',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'canCreateSurveys',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'admin_user_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'user_id_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'answer',
      dartName: 'Answer',
      schema: 'public',
      module: 'form_concierge',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'answer_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'surveyResponseId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'questionId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'textValue',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'selectedChoiceIds',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<int>?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'answer_fk_0',
          columns: ['surveyResponseId'],
          referenceTable: 'survey_response',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'answer_fk_1',
          columns: ['questionId'],
          referenceTable: 'question',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'answer_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'response_question_index',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'surveyResponseId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'questionId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'choice',
      dartName: 'Choice',
      schema: 'public',
      module: 'form_concierge',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'choice_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'questionId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'text',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'orderIndex',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'value',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'choice_fk_0',
          columns: ['questionId'],
          referenceTable: 'question',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'choice_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'question_order_index',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'questionId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'orderIndex',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'question',
      dartName: 'Question',
      schema: 'public',
      module: 'form_concierge',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'question_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'surveyId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'text',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'type',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:QuestionType',
        ),
        _i2.ColumnDefinition(
          name: 'orderIndex',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'isRequired',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'placeholder',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'minLength',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'maxLength',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'isDeleted',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'question_fk_0',
          columns: ['surveyId'],
          referenceTable: 'survey',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'question_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'survey_order_index',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'surveyId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'orderIndex',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'survey',
      dartName: 'Survey',
      schema: 'public',
      module: 'form_concierge',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'survey_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'slug',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'title',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SurveyStatus',
          columnDefault: '\'draft\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'authRequirement',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AuthRequirement',
          columnDefault: '\'anonymous\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'createdByUserId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'startsAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'endsAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'survey_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'slug_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'slug',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'status_index',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'survey_response',
      dartName: 'SurveyResponse',
      schema: 'public',
      module: 'form_concierge',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'survey_response_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'surveyId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'anonymousId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'submittedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'ipAddress',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'userAgent',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'survey_response_fk_0',
          columns: ['surveyId'],
          referenceTable: 'survey',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'survey_response_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'survey_submitted_index',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'surveyId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'submittedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'user_survey_index',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'surveyId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

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

    if (t == _i5.AdminUser) {
      return _i5.AdminUser.fromJson(data) as T;
    }
    if (t == _i6.Answer) {
      return _i6.Answer.fromJson(data) as T;
    }
    if (t == _i7.AuthRequirement) {
      return _i7.AuthRequirement.fromJson(data) as T;
    }
    if (t == _i8.AuthUserInfo) {
      return _i8.AuthUserInfo.fromJson(data) as T;
    }
    if (t == _i9.Choice) {
      return _i9.Choice.fromJson(data) as T;
    }
    if (t == _i10.PublicConfig) {
      return _i10.PublicConfig.fromJson(data) as T;
    }
    if (t == _i11.Question) {
      return _i11.Question.fromJson(data) as T;
    }
    if (t == _i12.QuestionResult) {
      return _i12.QuestionResult.fromJson(data) as T;
    }
    if (t == _i13.QuestionType) {
      return _i13.QuestionType.fromJson(data) as T;
    }
    if (t == _i14.QuestionWithChoices) {
      return _i14.QuestionWithChoices.fromJson(data) as T;
    }
    if (t == _i15.Survey) {
      return _i15.Survey.fromJson(data) as T;
    }
    if (t == _i16.SurveyResponse) {
      return _i16.SurveyResponse.fromJson(data) as T;
    }
    if (t == _i17.SurveyResults) {
      return _i17.SurveyResults.fromJson(data) as T;
    }
    if (t == _i18.SurveyStatus) {
      return _i18.SurveyStatus.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.AdminUser?>()) {
      return (data != null ? _i5.AdminUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Answer?>()) {
      return (data != null ? _i6.Answer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.AuthRequirement?>()) {
      return (data != null ? _i7.AuthRequirement.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.AuthUserInfo?>()) {
      return (data != null ? _i8.AuthUserInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.Choice?>()) {
      return (data != null ? _i9.Choice.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.PublicConfig?>()) {
      return (data != null ? _i10.PublicConfig.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.Question?>()) {
      return (data != null ? _i11.Question.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.QuestionResult?>()) {
      return (data != null ? _i12.QuestionResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.QuestionType?>()) {
      return (data != null ? _i13.QuestionType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.QuestionWithChoices?>()) {
      return (data != null ? _i14.QuestionWithChoices.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.Survey?>()) {
      return (data != null ? _i15.Survey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.SurveyResponse?>()) {
      return (data != null ? _i16.SurveyResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.SurveyResults?>()) {
      return (data != null ? _i17.SurveyResults.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.SurveyStatus?>()) {
      return (data != null ? _i18.SurveyStatus.fromJson(data) : null) as T;
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
    if (t == List<_i12.QuestionResult>) {
      return (data as List)
              .map((e) => deserialize<_i12.QuestionResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i19.Choice>) {
      return (data as List).map((e) => deserialize<_i19.Choice>(e)).toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i20.Question>) {
      return (data as List).map((e) => deserialize<_i20.Question>(e)).toList()
          as T;
    }
    if (t == List<_i21.SurveyResponse>) {
      return (data as List)
              .map((e) => deserialize<_i21.SurveyResponse>(e))
              .toList()
          as T;
    }
    if (t == List<_i22.Answer>) {
      return (data as List).map((e) => deserialize<_i22.Answer>(e)).toList()
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<_i23.QuestionWithChoices>) {
      return (data as List)
              .map((e) => deserialize<_i23.QuestionWithChoices>(e))
              .toList()
          as T;
    }
    if (t == List<_i24.Survey>) {
      return (data as List).map((e) => deserialize<_i24.Survey>(e)).toList()
          as T;
    }
    if (t == List<_i25.AuthUserInfo>) {
      return (data as List)
              .map((e) => deserialize<_i25.AuthUserInfo>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i5.AdminUser => 'AdminUser',
      _i6.Answer => 'Answer',
      _i7.AuthRequirement => 'AuthRequirement',
      _i8.AuthUserInfo => 'AuthUserInfo',
      _i9.Choice => 'Choice',
      _i10.PublicConfig => 'PublicConfig',
      _i11.Question => 'Question',
      _i12.QuestionResult => 'QuestionResult',
      _i13.QuestionType => 'QuestionType',
      _i14.QuestionWithChoices => 'QuestionWithChoices',
      _i15.Survey => 'Survey',
      _i16.SurveyResponse => 'SurveyResponse',
      _i17.SurveyResults => 'SurveyResults',
      _i18.SurveyStatus => 'SurveyStatus',
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
      case _i5.AdminUser():
        return 'AdminUser';
      case _i6.Answer():
        return 'Answer';
      case _i7.AuthRequirement():
        return 'AuthRequirement';
      case _i8.AuthUserInfo():
        return 'AuthUserInfo';
      case _i9.Choice():
        return 'Choice';
      case _i10.PublicConfig():
        return 'PublicConfig';
      case _i11.Question():
        return 'Question';
      case _i12.QuestionResult():
        return 'QuestionResult';
      case _i13.QuestionType():
        return 'QuestionType';
      case _i14.QuestionWithChoices():
        return 'QuestionWithChoices';
      case _i15.Survey():
        return 'Survey';
      case _i16.SurveyResponse():
        return 'SurveyResponse';
      case _i17.SurveyResults():
        return 'SurveyResults';
      case _i18.SurveyStatus():
        return 'SurveyStatus';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
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
      return deserialize<_i5.AdminUser>(data['data']);
    }
    if (dataClassName == 'Answer') {
      return deserialize<_i6.Answer>(data['data']);
    }
    if (dataClassName == 'AuthRequirement') {
      return deserialize<_i7.AuthRequirement>(data['data']);
    }
    if (dataClassName == 'AuthUserInfo') {
      return deserialize<_i8.AuthUserInfo>(data['data']);
    }
    if (dataClassName == 'Choice') {
      return deserialize<_i9.Choice>(data['data']);
    }
    if (dataClassName == 'PublicConfig') {
      return deserialize<_i10.PublicConfig>(data['data']);
    }
    if (dataClassName == 'Question') {
      return deserialize<_i11.Question>(data['data']);
    }
    if (dataClassName == 'QuestionResult') {
      return deserialize<_i12.QuestionResult>(data['data']);
    }
    if (dataClassName == 'QuestionType') {
      return deserialize<_i13.QuestionType>(data['data']);
    }
    if (dataClassName == 'QuestionWithChoices') {
      return deserialize<_i14.QuestionWithChoices>(data['data']);
    }
    if (dataClassName == 'Survey') {
      return deserialize<_i15.Survey>(data['data']);
    }
    if (dataClassName == 'SurveyResponse') {
      return deserialize<_i16.SurveyResponse>(data['data']);
    }
    if (dataClassName == 'SurveyResults') {
      return deserialize<_i17.SurveyResults>(data['data']);
    }
    if (dataClassName == 'SurveyStatus') {
      return deserialize<_i18.SurveyStatus>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i4.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i5.AdminUser:
        return _i5.AdminUser.t;
      case _i6.Answer:
        return _i6.Answer.t;
      case _i9.Choice:
        return _i9.Choice.t;
      case _i11.Question:
        return _i11.Question.t;
      case _i15.Survey:
        return _i15.Survey.t;
      case _i16.SurveyResponse:
        return _i16.SurveyResponse.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'form_concierge';

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
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
