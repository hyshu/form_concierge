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

/// An option for choice-type questions
abstract class QuestionOption
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = QuestionOptionTable();

  static const db = QuestionOptionRepository._();

  @override
  int? id;

  /// Reference to the parent question
  int questionId;

  /// The option text
  String text;

  /// Display order within the question
  int orderIndex;

  /// Optional value (if different from text)
  String? value;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'QuestionOption',
      if (id != null) 'id': id,
      'questionId': questionId,
      'text': text,
      'orderIndex': orderIndex,
      if (value != null) 'value': value,
    };
  }

  static QuestionOptionInclude include() {
    return QuestionOptionInclude._();
  }

  static QuestionOptionIncludeList includeList({
    _i1.WhereExpressionBuilder<QuestionOptionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<QuestionOptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<QuestionOptionTable>? orderByList,
    QuestionOptionInclude? include,
  }) {
    return QuestionOptionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(QuestionOption.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(QuestionOption.t),
      include: include,
    );
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

class QuestionOptionUpdateTable extends _i1.UpdateTable<QuestionOptionTable> {
  QuestionOptionUpdateTable(super.table);

  _i1.ColumnValue<int, int> questionId(int value) => _i1.ColumnValue(
    table.questionId,
    value,
  );

  _i1.ColumnValue<String, String> text(String value) => _i1.ColumnValue(
    table.text,
    value,
  );

  _i1.ColumnValue<int, int> orderIndex(int value) => _i1.ColumnValue(
    table.orderIndex,
    value,
  );

  _i1.ColumnValue<String, String> value(String? value) => _i1.ColumnValue(
    table.value,
    value,
  );
}

class QuestionOptionTable extends _i1.Table<int?> {
  QuestionOptionTable({super.tableRelation})
    : super(tableName: 'question_option') {
    updateTable = QuestionOptionUpdateTable(this);
    questionId = _i1.ColumnInt(
      'questionId',
      this,
    );
    text = _i1.ColumnString(
      'text',
      this,
    );
    orderIndex = _i1.ColumnInt(
      'orderIndex',
      this,
    );
    value = _i1.ColumnString(
      'value',
      this,
    );
  }

  late final QuestionOptionUpdateTable updateTable;

  /// Reference to the parent question
  late final _i1.ColumnInt questionId;

  /// The option text
  late final _i1.ColumnString text;

  /// Display order within the question
  late final _i1.ColumnInt orderIndex;

  /// Optional value (if different from text)
  late final _i1.ColumnString value;

  @override
  List<_i1.Column> get columns => [
    id,
    questionId,
    text,
    orderIndex,
    value,
  ];
}

class QuestionOptionInclude extends _i1.IncludeObject {
  QuestionOptionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => QuestionOption.t;
}

class QuestionOptionIncludeList extends _i1.IncludeList {
  QuestionOptionIncludeList._({
    _i1.WhereExpressionBuilder<QuestionOptionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(QuestionOption.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => QuestionOption.t;
}

class QuestionOptionRepository {
  const QuestionOptionRepository._();

  /// Returns a list of [QuestionOption]s matching the given query parameters.
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
  Future<List<QuestionOption>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<QuestionOptionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<QuestionOptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<QuestionOptionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<QuestionOption>(
      where: where?.call(QuestionOption.t),
      orderBy: orderBy?.call(QuestionOption.t),
      orderByList: orderByList?.call(QuestionOption.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [QuestionOption] matching the given query parameters.
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
  Future<QuestionOption?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<QuestionOptionTable>? where,
    int? offset,
    _i1.OrderByBuilder<QuestionOptionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<QuestionOptionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<QuestionOption>(
      where: where?.call(QuestionOption.t),
      orderBy: orderBy?.call(QuestionOption.t),
      orderByList: orderByList?.call(QuestionOption.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [QuestionOption] by its [id] or null if no such row exists.
  Future<QuestionOption?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<QuestionOption>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [QuestionOption]s in the list and returns the inserted rows.
  ///
  /// The returned [QuestionOption]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<QuestionOption>> insert(
    _i1.Session session,
    List<QuestionOption> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<QuestionOption>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [QuestionOption] and returns the inserted row.
  ///
  /// The returned [QuestionOption] will have its `id` field set.
  Future<QuestionOption> insertRow(
    _i1.Session session,
    QuestionOption row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<QuestionOption>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [QuestionOption]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<QuestionOption>> update(
    _i1.Session session,
    List<QuestionOption> rows, {
    _i1.ColumnSelections<QuestionOptionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<QuestionOption>(
      rows,
      columns: columns?.call(QuestionOption.t),
      transaction: transaction,
    );
  }

  /// Updates a single [QuestionOption]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<QuestionOption> updateRow(
    _i1.Session session,
    QuestionOption row, {
    _i1.ColumnSelections<QuestionOptionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<QuestionOption>(
      row,
      columns: columns?.call(QuestionOption.t),
      transaction: transaction,
    );
  }

  /// Updates a single [QuestionOption] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<QuestionOption?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<QuestionOptionUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<QuestionOption>(
      id,
      columnValues: columnValues(QuestionOption.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [QuestionOption]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<QuestionOption>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<QuestionOptionUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<QuestionOptionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<QuestionOptionTable>? orderBy,
    _i1.OrderByListBuilder<QuestionOptionTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<QuestionOption>(
      columnValues: columnValues(QuestionOption.t.updateTable),
      where: where(QuestionOption.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(QuestionOption.t),
      orderByList: orderByList?.call(QuestionOption.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [QuestionOption]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<QuestionOption>> delete(
    _i1.Session session,
    List<QuestionOption> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<QuestionOption>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [QuestionOption].
  Future<QuestionOption> deleteRow(
    _i1.Session session,
    QuestionOption row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<QuestionOption>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<QuestionOption>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<QuestionOptionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<QuestionOption>(
      where: where(QuestionOption.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<QuestionOptionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<QuestionOption>(
      where: where?.call(QuestionOption.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
