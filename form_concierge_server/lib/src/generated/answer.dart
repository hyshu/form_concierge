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

/// An individual answer to a question
abstract class Answer implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Answer._({
    this.id,
    required this.surveyResponseId,
    required this.questionId,
    this.textValue,
    this.selectedChoiceIds,
  });

  factory Answer({
    int? id,
    required int surveyResponseId,
    required int questionId,
    String? textValue,
    List<int>? selectedChoiceIds,
  }) = _AnswerImpl;

  factory Answer.fromJson(Map<String, dynamic> jsonSerialization) {
    return Answer(
      id: jsonSerialization['id'] as int?,
      surveyResponseId: jsonSerialization['surveyResponseId'] as int,
      questionId: jsonSerialization['questionId'] as int,
      textValue: jsonSerialization['textValue'] as String?,
      selectedChoiceIds: jsonSerialization['selectedChoiceIds'] == null
          ? null
          : _i2.Protocol().deserialize<List<int>>(
              jsonSerialization['selectedChoiceIds'],
            ),
    );
  }

  static final t = AnswerTable();

  static const db = AnswerRepository._();

  @override
  int? id;

  /// Reference to the survey response
  int surveyResponseId;

  /// Reference to the question being answered
  int questionId;

  /// Text answer (for text-type questions)
  String? textValue;

  /// Selected choice IDs (for choice questions)
  List<int>? selectedChoiceIds;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Answer]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Answer copyWith({
    int? id,
    int? surveyResponseId,
    int? questionId,
    String? textValue,
    List<int>? selectedChoiceIds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Answer',
      if (id != null) 'id': id,
      'surveyResponseId': surveyResponseId,
      'questionId': questionId,
      if (textValue != null) 'textValue': textValue,
      if (selectedChoiceIds != null)
        'selectedChoiceIds': selectedChoiceIds?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Answer',
      if (id != null) 'id': id,
      'surveyResponseId': surveyResponseId,
      'questionId': questionId,
      if (textValue != null) 'textValue': textValue,
      if (selectedChoiceIds != null)
        'selectedChoiceIds': selectedChoiceIds?.toJson(),
    };
  }

  static AnswerInclude include() {
    return AnswerInclude._();
  }

  static AnswerIncludeList includeList({
    _i1.WhereExpressionBuilder<AnswerTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AnswerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AnswerTable>? orderByList,
    AnswerInclude? include,
  }) {
    return AnswerIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Answer.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Answer.t),
      include: include,
    );
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
    List<int>? selectedChoiceIds,
  }) : super._(
         id: id,
         surveyResponseId: surveyResponseId,
         questionId: questionId,
         textValue: textValue,
         selectedChoiceIds: selectedChoiceIds,
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
    Object? selectedChoiceIds = _Undefined,
  }) {
    return Answer(
      id: id is int? ? id : this.id,
      surveyResponseId: surveyResponseId ?? this.surveyResponseId,
      questionId: questionId ?? this.questionId,
      textValue: textValue is String? ? textValue : this.textValue,
      selectedChoiceIds: selectedChoiceIds is List<int>?
          ? selectedChoiceIds
          : this.selectedChoiceIds?.map((e0) => e0).toList(),
    );
  }
}

class AnswerUpdateTable extends _i1.UpdateTable<AnswerTable> {
  AnswerUpdateTable(super.table);

  _i1.ColumnValue<int, int> surveyResponseId(int value) => _i1.ColumnValue(
    table.surveyResponseId,
    value,
  );

  _i1.ColumnValue<int, int> questionId(int value) => _i1.ColumnValue(
    table.questionId,
    value,
  );

  _i1.ColumnValue<String, String> textValue(String? value) => _i1.ColumnValue(
    table.textValue,
    value,
  );

  _i1.ColumnValue<List<int>, List<int>> selectedChoiceIds(List<int>? value) =>
      _i1.ColumnValue(
        table.selectedChoiceIds,
        value,
      );
}

class AnswerTable extends _i1.Table<int?> {
  AnswerTable({super.tableRelation}) : super(tableName: 'answer') {
    updateTable = AnswerUpdateTable(this);
    surveyResponseId = _i1.ColumnInt(
      'surveyResponseId',
      this,
    );
    questionId = _i1.ColumnInt(
      'questionId',
      this,
    );
    textValue = _i1.ColumnString(
      'textValue',
      this,
    );
    selectedChoiceIds = _i1.ColumnSerializable<List<int>>(
      'selectedChoiceIds',
      this,
    );
  }

  late final AnswerUpdateTable updateTable;

  /// Reference to the survey response
  late final _i1.ColumnInt surveyResponseId;

  /// Reference to the question being answered
  late final _i1.ColumnInt questionId;

  /// Text answer (for text-type questions)
  late final _i1.ColumnString textValue;

  /// Selected choice IDs (for choice questions)
  late final _i1.ColumnSerializable<List<int>> selectedChoiceIds;

  @override
  List<_i1.Column> get columns => [
    id,
    surveyResponseId,
    questionId,
    textValue,
    selectedChoiceIds,
  ];
}

class AnswerInclude extends _i1.IncludeObject {
  AnswerInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Answer.t;
}

class AnswerIncludeList extends _i1.IncludeList {
  AnswerIncludeList._({
    _i1.WhereExpressionBuilder<AnswerTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Answer.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Answer.t;
}

class AnswerRepository {
  const AnswerRepository._();

  /// Returns a list of [Answer]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Answer>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AnswerTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AnswerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AnswerTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Answer>(
      where: where?.call(Answer.t),
      orderBy: orderBy?.call(Answer.t),
      orderByList: orderByList?.call(Answer.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Answer] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Answer?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AnswerTable>? where,
    int? offset,
    _i1.OrderByBuilder<AnswerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AnswerTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Answer>(
      where: where?.call(Answer.t),
      orderBy: orderBy?.call(Answer.t),
      orderByList: orderByList?.call(Answer.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Answer] by its [id] or null if no such row exists.
  Future<Answer?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Answer>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Answer]s in the list and returns the inserted rows.
  ///
  /// The returned [Answer]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Answer>> insert(
    _i1.Session session,
    List<Answer> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Answer>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Answer] and returns the inserted row.
  ///
  /// The returned [Answer] will have its `id` field set.
  Future<Answer> insertRow(
    _i1.Session session,
    Answer row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Answer>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Answer]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Answer>> update(
    _i1.Session session,
    List<Answer> rows, {
    _i1.ColumnSelections<AnswerTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Answer>(
      rows,
      columns: columns?.call(Answer.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Answer]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Answer> updateRow(
    _i1.Session session,
    Answer row, {
    _i1.ColumnSelections<AnswerTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Answer>(
      row,
      columns: columns?.call(Answer.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Answer] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Answer?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<AnswerUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Answer>(
      id,
      columnValues: columnValues(Answer.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Answer]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Answer>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<AnswerUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<AnswerTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AnswerTable>? orderBy,
    _i1.OrderByListBuilder<AnswerTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Answer>(
      columnValues: columnValues(Answer.t.updateTable),
      where: where(Answer.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Answer.t),
      orderByList: orderByList?.call(Answer.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Answer]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Answer>> delete(
    _i1.Session session,
    List<Answer> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Answer>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Answer].
  Future<Answer> deleteRow(
    _i1.Session session,
    Answer row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Answer>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Answer>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<AnswerTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Answer>(
      where: where(Answer.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AnswerTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Answer>(
      where: where?.call(Answer.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
