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

/// A question within a survey
abstract class Question
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = QuestionTable();

  static const db = QuestionRepository._();

  @override
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

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static QuestionInclude include() {
    return QuestionInclude._();
  }

  static QuestionIncludeList includeList({
    _i1.WhereExpressionBuilder<QuestionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<QuestionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<QuestionTable>? orderByList,
    QuestionInclude? include,
  }) {
    return QuestionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Question.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Question.t),
      include: include,
    );
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

class QuestionUpdateTable extends _i1.UpdateTable<QuestionTable> {
  QuestionUpdateTable(super.table);

  _i1.ColumnValue<int, int> surveyId(int value) => _i1.ColumnValue(
    table.surveyId,
    value,
  );

  _i1.ColumnValue<String, String> text(String value) => _i1.ColumnValue(
    table.text,
    value,
  );

  _i1.ColumnValue<_i2.QuestionType, _i2.QuestionType> type(
    _i2.QuestionType value,
  ) => _i1.ColumnValue(
    table.type,
    value,
  );

  _i1.ColumnValue<int, int> orderIndex(int value) => _i1.ColumnValue(
    table.orderIndex,
    value,
  );

  _i1.ColumnValue<bool, bool> isRequired(bool value) => _i1.ColumnValue(
    table.isRequired,
    value,
  );

  _i1.ColumnValue<String, String> placeholder(String? value) => _i1.ColumnValue(
    table.placeholder,
    value,
  );

  _i1.ColumnValue<int, int> minLength(int? value) => _i1.ColumnValue(
    table.minLength,
    value,
  );

  _i1.ColumnValue<int, int> maxLength(int? value) => _i1.ColumnValue(
    table.maxLength,
    value,
  );
}

class QuestionTable extends _i1.Table<int?> {
  QuestionTable({super.tableRelation}) : super(tableName: 'question') {
    updateTable = QuestionUpdateTable(this);
    surveyId = _i1.ColumnInt(
      'surveyId',
      this,
    );
    text = _i1.ColumnString(
      'text',
      this,
    );
    type = _i1.ColumnEnum(
      'type',
      this,
      _i1.EnumSerialization.byName,
    );
    orderIndex = _i1.ColumnInt(
      'orderIndex',
      this,
    );
    isRequired = _i1.ColumnBool(
      'isRequired',
      this,
      hasDefault: true,
    );
    placeholder = _i1.ColumnString(
      'placeholder',
      this,
    );
    minLength = _i1.ColumnInt(
      'minLength',
      this,
    );
    maxLength = _i1.ColumnInt(
      'maxLength',
      this,
    );
  }

  late final QuestionUpdateTable updateTable;

  /// Reference to the parent survey
  late final _i1.ColumnInt surveyId;

  /// The question text
  late final _i1.ColumnString text;

  /// Type of question (single choice, multiple choice, text, etc.)
  late final _i1.ColumnEnum<_i2.QuestionType> type;

  /// Display order within the survey
  late final _i1.ColumnInt orderIndex;

  /// Whether this question is required
  late final _i1.ColumnBool isRequired;

  /// Optional placeholder text for text inputs
  late final _i1.ColumnString placeholder;

  /// For text inputs: minimum character count
  late final _i1.ColumnInt minLength;

  /// For text inputs: maximum character count
  late final _i1.ColumnInt maxLength;

  @override
  List<_i1.Column> get columns => [
    id,
    surveyId,
    text,
    type,
    orderIndex,
    isRequired,
    placeholder,
    minLength,
    maxLength,
  ];
}

class QuestionInclude extends _i1.IncludeObject {
  QuestionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Question.t;
}

class QuestionIncludeList extends _i1.IncludeList {
  QuestionIncludeList._({
    _i1.WhereExpressionBuilder<QuestionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Question.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Question.t;
}

class QuestionRepository {
  const QuestionRepository._();

  /// Returns a list of [Question]s matching the given query parameters.
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
  Future<List<Question>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<QuestionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<QuestionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<QuestionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Question>(
      where: where?.call(Question.t),
      orderBy: orderBy?.call(Question.t),
      orderByList: orderByList?.call(Question.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Question] matching the given query parameters.
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
  Future<Question?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<QuestionTable>? where,
    int? offset,
    _i1.OrderByBuilder<QuestionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<QuestionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Question>(
      where: where?.call(Question.t),
      orderBy: orderBy?.call(Question.t),
      orderByList: orderByList?.call(Question.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Question] by its [id] or null if no such row exists.
  Future<Question?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Question>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Question]s in the list and returns the inserted rows.
  ///
  /// The returned [Question]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Question>> insert(
    _i1.Session session,
    List<Question> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Question>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Question] and returns the inserted row.
  ///
  /// The returned [Question] will have its `id` field set.
  Future<Question> insertRow(
    _i1.Session session,
    Question row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Question>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Question]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Question>> update(
    _i1.Session session,
    List<Question> rows, {
    _i1.ColumnSelections<QuestionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Question>(
      rows,
      columns: columns?.call(Question.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Question]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Question> updateRow(
    _i1.Session session,
    Question row, {
    _i1.ColumnSelections<QuestionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Question>(
      row,
      columns: columns?.call(Question.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Question] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Question?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<QuestionUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Question>(
      id,
      columnValues: columnValues(Question.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Question]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Question>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<QuestionUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<QuestionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<QuestionTable>? orderBy,
    _i1.OrderByListBuilder<QuestionTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Question>(
      columnValues: columnValues(Question.t.updateTable),
      where: where(Question.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Question.t),
      orderByList: orderByList?.call(Question.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Question]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Question>> delete(
    _i1.Session session,
    List<Question> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Question>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Question].
  Future<Question> deleteRow(
    _i1.Session session,
    Question row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Question>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Question>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<QuestionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Question>(
      where: where(Question.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<QuestionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Question>(
      where: where?.call(Question.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
