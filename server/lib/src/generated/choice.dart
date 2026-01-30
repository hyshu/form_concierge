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

/// A choice option for choice-type questions
abstract class Choice implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Choice._({
    this.id,
    required this.questionId,
    required this.text,
    required this.orderIndex,
    this.value,
  });

  factory Choice({
    int? id,
    required int questionId,
    required String text,
    required int orderIndex,
    String? value,
  }) = _ChoiceImpl;

  factory Choice.fromJson(Map<String, dynamic> jsonSerialization) {
    return Choice(
      id: jsonSerialization['id'] as int?,
      questionId: jsonSerialization['questionId'] as int,
      text: jsonSerialization['text'] as String,
      orderIndex: jsonSerialization['orderIndex'] as int,
      value: jsonSerialization['value'] as String?,
    );
  }

  static final t = ChoiceTable();

  static const db = ChoiceRepository._();

  @override
  int? id;

  /// Reference to the parent question
  int questionId;

  /// The choice text displayed to respondents
  String text;

  /// Display order within the question
  int orderIndex;

  /// Optional value (if different from text)
  String? value;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Choice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Choice copyWith({
    int? id,
    int? questionId,
    String? text,
    int? orderIndex,
    String? value,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Choice',
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
      '__className__': 'Choice',
      if (id != null) 'id': id,
      'questionId': questionId,
      'text': text,
      'orderIndex': orderIndex,
      if (value != null) 'value': value,
    };
  }

  static ChoiceInclude include() {
    return ChoiceInclude._();
  }

  static ChoiceIncludeList includeList({
    _i1.WhereExpressionBuilder<ChoiceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChoiceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChoiceTable>? orderByList,
    ChoiceInclude? include,
  }) {
    return ChoiceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Choice.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Choice.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChoiceImpl extends Choice {
  _ChoiceImpl({
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

  /// Returns a shallow copy of this [Choice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Choice copyWith({
    Object? id = _Undefined,
    int? questionId,
    String? text,
    int? orderIndex,
    Object? value = _Undefined,
  }) {
    return Choice(
      id: id is int? ? id : this.id,
      questionId: questionId ?? this.questionId,
      text: text ?? this.text,
      orderIndex: orderIndex ?? this.orderIndex,
      value: value is String? ? value : this.value,
    );
  }
}

class ChoiceUpdateTable extends _i1.UpdateTable<ChoiceTable> {
  ChoiceUpdateTable(super.table);

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

class ChoiceTable extends _i1.Table<int?> {
  ChoiceTable({super.tableRelation}) : super(tableName: 'choice') {
    updateTable = ChoiceUpdateTable(this);
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

  late final ChoiceUpdateTable updateTable;

  /// Reference to the parent question
  late final _i1.ColumnInt questionId;

  /// The choice text displayed to respondents
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

class ChoiceInclude extends _i1.IncludeObject {
  ChoiceInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Choice.t;
}

class ChoiceIncludeList extends _i1.IncludeList {
  ChoiceIncludeList._({
    _i1.WhereExpressionBuilder<ChoiceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Choice.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Choice.t;
}

class ChoiceRepository {
  const ChoiceRepository._();

  /// Returns a list of [Choice]s matching the given query parameters.
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
  Future<List<Choice>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChoiceTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChoiceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChoiceTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Choice>(
      where: where?.call(Choice.t),
      orderBy: orderBy?.call(Choice.t),
      orderByList: orderByList?.call(Choice.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Choice] matching the given query parameters.
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
  Future<Choice?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChoiceTable>? where,
    int? offset,
    _i1.OrderByBuilder<ChoiceTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChoiceTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Choice>(
      where: where?.call(Choice.t),
      orderBy: orderBy?.call(Choice.t),
      orderByList: orderByList?.call(Choice.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Choice] by its [id] or null if no such row exists.
  Future<Choice?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Choice>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Choice]s in the list and returns the inserted rows.
  ///
  /// The returned [Choice]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Choice>> insert(
    _i1.Session session,
    List<Choice> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Choice>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Choice] and returns the inserted row.
  ///
  /// The returned [Choice] will have its `id` field set.
  Future<Choice> insertRow(
    _i1.Session session,
    Choice row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Choice>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Choice]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Choice>> update(
    _i1.Session session,
    List<Choice> rows, {
    _i1.ColumnSelections<ChoiceTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Choice>(
      rows,
      columns: columns?.call(Choice.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Choice]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Choice> updateRow(
    _i1.Session session,
    Choice row, {
    _i1.ColumnSelections<ChoiceTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Choice>(
      row,
      columns: columns?.call(Choice.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Choice] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Choice?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ChoiceUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Choice>(
      id,
      columnValues: columnValues(Choice.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Choice]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Choice>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ChoiceUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ChoiceTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChoiceTable>? orderBy,
    _i1.OrderByListBuilder<ChoiceTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Choice>(
      columnValues: columnValues(Choice.t.updateTable),
      where: where(Choice.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Choice.t),
      orderByList: orderByList?.call(Choice.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Choice]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Choice>> delete(
    _i1.Session session,
    List<Choice> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Choice>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Choice].
  Future<Choice> deleteRow(
    _i1.Session session,
    Choice row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Choice>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Choice>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ChoiceTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Choice>(
      where: where(Choice.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChoiceTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Choice>(
      where: where?.call(Choice.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
